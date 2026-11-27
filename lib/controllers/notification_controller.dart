import 'dart:async';

import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/setting_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({
    required this.userId,
    NotificationService? service,
    SettingService? settingService,
    this.onIncoming,
  }) : _service = service ?? NotificationService(),
       _settings = settingService ?? SettingService();

  final String userId;
  final NotificationService _service;
  final SettingService _settings;
  final void Function(NotificationModel notification)? onIncoming;

  List<NotificationModel> _items = [];
  StreamSubscription<List<NotificationModel>>? _sub;
  final Set<String> _seenIds = {};
  bool _initialLoaded = false;

  bool loading = true;
  String? error;

  bool notifTransaksi = true;
  bool notifPromo = true;
  bool notifInfo = true;

  bool _isTypeEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.transaksi:
        return notifTransaksi;
      case NotificationType.promo:
        return notifPromo;
      case NotificationType.info:
        return notifInfo;
    }
  }

  Future<void> start() async {
    await LocalNotificationService.instance.init();
    _sub?.cancel();
    _sub = _service
        .watch(userId)
        .listen(
          (list) {
            if (!_initialLoaded) {
              _seenIds.addAll(list.map((e) => e.id));
              _initialLoaded = true;
            } else {
              for (final item in list) {
                if (_seenIds.add(item.id) &&
                    !item.isRead &&
                    _isTypeEnabled(item.type)) {
                  LocalNotificationService.instance.show(
                    idKey: item.id,
                    title: item.title,
                    body: item.message,
                  );
                  onIncoming?.call(item);
                }
              }
            }
            _items = list;
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (Object e) {
            loading = false;
            error = 'Gagal memuat notifikasi';
            notifyListeners();
          },
        );

    try {
      final data = await _settings.getUser(userId);
      final s = (data?['settings'] as Map<String, dynamic>?) ?? const {};
      notifTransaksi = (s['notifTransaksi'] as bool?) ?? true;
      notifPromo = (s['notifPromo'] as bool?) ?? true;
      notifInfo = (s['notifInfo'] as bool?) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat pilihan notifikasi: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<NotificationModel> get items {
    return _items.where((n) => _isTypeEnabled(n.type)).toList();
  }

  int get unreadCount => items.where((n) => !n.isRead).length;

  Future<void> markAsRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].isRead) return;
    _items[i] = _items[i].copyWith(isRead: true);
    notifyListeners();
    await _jalankan(() => _service.markAsRead(userId, id));
  }

  Future<void> markAllAsRead() async {
    final belum = _items.where((n) => !n.isRead).map((n) => n.id).toList();
    if (belum.isEmpty) return;
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _jalankan(() => _service.markAllAsRead(userId, belum));
  }

  Future<void> delete(String id) async {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
    await _jalankan(() => _service.delete(userId, id));
  }

  Future<void> setTransaksi(bool v) {
    notifTransaksi = v;
    notifyListeners();
    return _simpanPilihan('notifTransaksi', v);
  }

  Future<void> setPromo(bool v) {
    notifPromo = v;
    notifyListeners();
    return _simpanPilihan('notifPromo', v);
  }

  Future<void> setInfo(bool v) {
    notifInfo = v;
    notifyListeners();
    return _simpanPilihan('notifInfo', v);
  }

  Future<void> _simpanPilihan(String key, bool v) =>
      _jalankan(() => _settings.updateSettings(userId, {key: v}));

  Future<void> _jalankan(Future<void> Function() aksi) async {
    try {
      await aksi();
    } catch (e) {
      debugPrint('Operasi Firestore gagal: $e');
      error = 'Perubahan belum tersimpan ke server';
      notifyListeners();
    }
  }
}
