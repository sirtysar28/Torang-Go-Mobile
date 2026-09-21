import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import '../models/models.dart';

/// Sesi login (token + user). Pakai ListenableBuilder untuk listen.
class Session extends ChangeNotifier {
  String? _token;
  User? user;
  bool restored = false;

  bool get isAuthed => _token != null && user != null;
  User? get currentUser => user;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('tg_token');
    if (t == null) {
      restored = true;
      notifyListeners();
      return;
    }
    ApiClient.I.token = t;
    try {
      final res = await ApiClient.I.get('/auth/me');
      user = User.fromJson(res['user']);
      _token = t;
    } catch (_) {
      await prefs.remove('tg_token');
      ApiClient.I.token = null;
      _token = null;
      user = null;
    }
    restored = true;
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    final res = await ApiClient.I.post(
      '/auth/login',
      body: {'phone': phone, 'password': password},
    );
    await _persist(res);
  }

  Future<void> registerCustomer({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    final res = await ApiClient.I.post(
      '/auth/register',
      body: {
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'role': 'customer',
      },
    );
    await _persist(res);
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
  }) async {
    final res = await ApiClient.I.put(
      '/auth/me',
      body: {
        'name': ?name,
        'phone': ?phone,
        'email': ?email,
        'address': ?address,
      },
    );
    user = User.fromJson(res['user']);
    notifyListeners();
  }

  Future<void> _persist(dynamic res) async {
    final map = res as Map<String, dynamic>;
    _token = map['token'] as String?;
    user = User.fromJson(map['user']);
    ApiClient.I.token = _token;
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('tg_token', _token!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await ApiClient.I.post('/auth/logout');
    } catch (_) {}
    _token = null;
    user = null;
    ApiClient.I.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tg_token');
    notifyListeners();
  }
}
