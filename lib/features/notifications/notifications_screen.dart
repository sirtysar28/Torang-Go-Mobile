import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with AutomaticKeepAliveClientMixin {
  List<TgNotification> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.I.get('/notifications');
      setState(() {
        _items = ((res['notifications'] as List?) ?? [])
            .map(
              (e) => TgNotification(
                e['id'] as int,
                (e['title'] ?? 'Notifikasi').toString(),
                (e['body'] ?? '').toString(),
                e['read_at']?.toString(),
                (e['created_at'] ?? '').toString(),
              ),
            )
            .toList();
        _loading = false;
      });
      if (_items.any((n) => n.unread)) {
        ApiClient.I.post('/notifications/read');
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
              child: Text('Notifikasi', style: TG.title(context)),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: TG.leaf),
                    )
                  : _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.notifications_off_rounded,
                          title: 'Belum ada notifikasi',
                          subtitle: 'Update pesanan bakal muncul di sini.',
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: TG.ocean,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: TG.card(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: n.unread
                                        ? TG.oceanSoft
                                        : TG.sandDark,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.campaign_rounded,
                                    size: 19,
                                    color: n.unread ? TG.ocean : TG.inkSoft,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title, style: TG.titleSm(context)),
                                      if (n.body.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          n.body,
                                          style: TG.bodySm(
                                            context,
                                            color: TG.inkSoft,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 5),
                                      Text(
                                        timeAgoIso(n.createdAt),
                                        style: TG.bodySm(
                                          context,
                                          color: TG.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (n.unread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: const BoxDecoration(
                                      color: TG.coral,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
