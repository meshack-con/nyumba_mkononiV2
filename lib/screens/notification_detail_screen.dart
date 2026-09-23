import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../theme/app_theme.dart';

/// Inaonyesha ujumbe KAMILI wa arifa ya platform (Nyumba Mkononi yenyewe),
/// ukiwa umekunjuliwa kwa upana wa skrini nzima.
///
/// Hii ni kwa ajili ya arifa za type == 'platform' TU - ujumbe wa mtu
/// binafsi (owner/mnunuzi) unaendelea kufungua ChatScreen kama kawaida,
/// hauji hapa kabisa.
class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.item});

  final NotificationItem item;

  String _formatFull(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
    ];
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${local.day} ${months[local.month - 1]} ${local.year}, saa $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ujumbe kutoka Nyumba Mkononi')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.home_work_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(_formatFull(item.createdAt), style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.surfaceLow, borderRadius: BorderRadius.circular(18)),
              child: Text(
                item.body,
                style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
