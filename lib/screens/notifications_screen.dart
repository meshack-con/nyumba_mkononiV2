import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiClient.instance.getNotifications();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Imeshindikana kupakia arifa. Angalia mtandao wako.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inMinutes < 60) return 'Dakika ${diff.inMinutes} zilizopita';
    if (diff.inHours < 24 && local.day == now.day) return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (diff.inDays < 7) return 'Siku ${diff.inDays} zilizopita';
    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _openItem(NotificationItem item) async {
    if (item.isOwnerMessage && item.propertyId != null && item.otherUserId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            propertyId: item.propertyId!,
            otherUserId: item.otherUserId!,
            otherUserName: item.title.replaceFirst('Ujumbe kutoka kwa ', ''),
          ),
        ),
      );
      _load();
      return;
    }
    if (item.isPlatform) {
      if (!item.read) {
        try {
          await ApiClient.instance.markNotificationRead(item.id);
        } catch (_) {
          // Haihitaji kumsumbua mtumiaji ikiwa kusoma kumeshindikana.
        }
      }
      // Arifa za platform PEKEE (sio ujumbe wa mtu binafsi) zinafunguka
      // kwa upana kamili wa skrini kuonyesha ujumbe kamili.
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotificationDetailScreen(item: item)),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arifa')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
                        child: Column(children: [
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Jaribu tena')),
                        ]),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 100),
                            child: Column(children: [
                              Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.muted),
                              SizedBox(height: 12),
                              Text('Bado huna arifa.', style: TextStyle(color: AppTheme.muted)),
                            ]),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final unread = !item.read;
                          return ListTile(
                            onTap: () => _openItem(item),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: unread ? AppTheme.primary : AppTheme.surfaceLow,
                              foregroundColor: unread ? Colors.white : AppTheme.navy,
                              child: Icon(item.isPlatform ? Icons.home_work_outlined : Icons.chat_bubble_outline_rounded),
                            ),
                            title: Text(item.title, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w700)),
                            subtitle: Text(
                              item.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: unread ? AppTheme.navy : AppTheme.muted),
                            ),
                            isThreeLine: true,
                            trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_formatWhen(item.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                              const SizedBox(height: 6),
                              if (unread) Container(width: 9, height: 9, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}
