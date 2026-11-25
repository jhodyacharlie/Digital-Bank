import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationController>();
    final list = c.items;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1456A5),
        foregroundColor: Colors.white,
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: c.markAllAsRead,
            child: const Text(
              'Tandai semua dibaca',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (c.error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.red.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      c.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('Belum ada notifikasi'))
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final n = list[i];
                            return Dismissible(
                              key: ValueKey(n.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) {
                                c.delete(n.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notifikasi dihapus'),
                                  ),
                                );
                              },
                              child: ListTile(
                                tileColor: n.isRead
                                    ? null
                                    : Colors.blue.withValues(alpha: 0.07),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _warna(n.type).withValues(alpha: 0.15),
                                  child: Icon(
                                    _ikon(n.type),
                                    color: _warna(n.type),
                                  ),
                                ),
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.message),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm')
                                          .format(n.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: n.isRead
                                    ? null
                                    : const CircleAvatar(
                                        radius: 5,
                                        backgroundColor: Colors.blue,
                                      ),
                                onTap: () => c.markAsRead(n.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  IconData _ikon(NotificationType t) {
    switch (t) {
      case NotificationType.transaksi:
        return Icons.swap_horiz;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  Color _warna(NotificationType t) {
    switch (t) {
      case NotificationType.transaksi:
        return Colors.green;
      case NotificationType.promo:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
    }
  }
}
