import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  final List<NotificationModel> _items = [
    NotificationModel(
      id: 1,
      title: 'Transfer Berhasil',
      message: 'Transfer Rp500.000 ke Budi Santoso berhasil.',
      date: DateTime.now().subtract(const Duration(minutes: 10)),
      type: NotificationType.transaksi,
    ),
    NotificationModel(
      id: 2,
      title: 'Promo Cashback 20%',
      message: 'Dapatkan cashback 20% untuk pembayaran QRIS minggu ini.',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.promo,
    ),
    NotificationModel(
      id: 3,
      title: 'Pembaruan Aplikasi',
      message: 'Versi terbaru tersedia dengan peningkatan keamanan.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.info,
      isRead: true,
    ),
    NotificationModel(
      id: 4,
      title: 'Pembayaran Listrik',
      message: 'Pembayaran tagihan PLN Rp350.000 berhasil.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.transaksi,
      isRead: true,
    ),
  ];

  bool notifTransaksi = true;
  bool notifPromo = true;
  bool notifInfo = true;

  List<NotificationModel> get items {
    return _items.where((n) {
      switch (n.type) {
        case NotificationType.transaksi:
          return notifTransaksi;
        case NotificationType.promo:
          return notifPromo;
        case NotificationType.info:
          return notifInfo;
      }
    }).toList();
  }

  int get unreadCount => items.where((n) => !n.isRead).length;

  void markAsRead(int id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1) {
      _items[i] = _items[i].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void delete(int id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void setTransaksi(bool v) {
    notifTransaksi = v;
    notifyListeners();
  }

  void setPromo(bool v) {
    notifPromo = v;
    notifyListeners();
  }

  void setInfo(bool v) {
    notifInfo = v;
    notifyListeners();
  }
}
