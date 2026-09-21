import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HandshakeException;

import 'package:http/http.dart' as http;

import 'app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  String? token;

  Uri _uri(String path, Map<String, String>? query) {
    final uri = Uri.parse(path);
    if (uri.isAbsolute) return uri.replace(queryParameters: query);
    return Uri.parse(
      '$apiBase$path',
    ).replace(queryParameters: (query == null || query.isEmpty) ? null : query);
  }

  /// Base URL API (sudah termasuk /api/v1).
  String get apiBase => _baseOverride ?? AppConfig.apiBase;

  /// Host dari base URL — untuk pesan error yang jelas.
  String get _host {
    try {
      return Uri.parse(apiBase).host;
    } catch (_) {
      return apiBase;
    }
  }

  static String? _baseOverride;

  /// Override base URL (dipakai unit-test).
  static set baseOverride(String? v) => _baseOverride = v;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response res;
    try {
      final req = http.Request(method, _uri(path, query))
        ..headers.addAll(headers);
      if (body != null) req.body = jsonEncode(body);
      final client = http.Client();
      try {
        final streamed = await client
            .send(req)
            .timeout(const Duration(seconds: 25));
        res = await http.Response.fromStream(
          streamed,
        ).timeout(const Duration(seconds: 30));
      } finally {
        client.close();
      }
    } on TimeoutException {
      throw ApiException(
        'Server $_host tidak merespons (timeout). Cek sinyal internet kamu, '
        'lalu coba lagi. Jika terus terjadi, server sedang down.',
      );
    } on HandshakeException catch (e) {
      throw ApiException(
        'Koneksi aman (SSL) ke $_host gagal (${e.type}). '
        'Cek tanggal & jam di HP kamu sudah benar — lalu coba lagi. '
        'Detail: ${e.message}',
      );
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak bisa menghubungi $_host — cek koneksi internet kamu '
        '((${e.osError?.errorCode ?? ''}) ${e.message}).',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tidak bisa terhubung ke server ($_host): $e');
    }

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    var msg = 'Terjadi kesalahan (${res.statusCode})';
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        msg = data['message'] as String;
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) msg = first.first.toString();
      }
    }
    if (res.statusCode == 401) {
      msg = 'Sesi berakhir. Silakan login ulang.';
    }
    throw ApiException(msg, res.statusCode);
  }
}
