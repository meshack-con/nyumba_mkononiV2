import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});
  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  List<ConversationThread> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final threads = await ApiClient.instance.getConversations();
      if (mounted) setState(() => _threads = threads);
    } catch (_) {
      // Endapo imeshindwa, orodha inabaki kama ilivyokuwa - hakuna cha kuvunjika.
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 4),
            sliver: SliverToBoxAdapter(
              child: Text('Ujumbe', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_threads.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Column(children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.muted),
                  SizedBox(height: 12),
                  Text('Bado hujapata ujumbe wowote.', style: TextStyle(color: AppTheme.muted)),
                ]),
              ),
            )
          else
            SliverList.separated(
              itemCount: _threads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final thread = _threads[index];
                final unread = thread.unreadCount > 0;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: unread ? AppTheme.coral : AppTheme.sand,
                    child: Text(
                      thread.otherUserName.isNotEmpty ? thread.otherUserName[0].toUpperCase() : '?',
                      style: TextStyle(color: unread ? Colors.white : AppTheme.navy, fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(thread.otherUserName, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w700)),
                  subtitle: Text(
                    '${thread.propertyName}\n${thread.lastMessage}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: unread ? AppTheme.navy : AppTheme.muted, fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
                  ),
                  isThreeLine: true,
                  trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_formatWhen(thread.lastMessageAt), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    if (unread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.coral, borderRadius: BorderRadius.circular(20)),
                        child: Text('${thread.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                  ]),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          propertyId: thread.propertyId,
                          otherUserId: thread.otherUserId,
                          otherUserName: thread.otherUserName,
                        ),
                      ),
                    );
                    _load();
                  },
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
