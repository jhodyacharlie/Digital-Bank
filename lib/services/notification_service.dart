import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

/// Semua operasi Firestore untuk notifikasi.
/// Struktur: users/{userId}/notifications/{autoId}
///   title, message, type (transaksi|promo|info), isRead, tanggal
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  /// Realtime, terbaru di atas. Satu field orderBy -> tidak butuh index.
  Stream<List<NotificationModel>> watch(String userId) {
    return _col(userId)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
  }

  Future<void> markAsRead(String userId, String id) {
    return _col(userId).doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_col(userId).doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> delete(String userId, String id) {
    return _col(userId).doc(id).delete();
  }

  /// Dipanggil fitur lain (mis. halaman Transfer/QRIS) saat ada kejadian nyata:
  ///   await NotificationService().kirim(
  ///     userId: dariId,
  ///     title: 'Transfer Berhasil',
  ///     message: 'Transfer Rp500.000 ke Budi Santoso berhasil.',
  ///     type: NotificationType.transaksi,
  ///   );
  Future<void> kirim({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) {
    return _col(userId).add({
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': false,
      'tanggal': FieldValue.serverTimestamp(),
    });
  }

  /// Data contoh supaya halaman langsung bisa dicoba. Hanya jalan jika
  /// koleksi masih kosong.
  Future<void> seedContoh(String userId) async {
    final ada = await _col(userId).limit(1).get();
    if (ada.docs.isNotEmpty) return;

    final now = DateTime.now();
    final data = <(String, String, NotificationType, Duration, bool)>[
      ('Transfer Berhasil', 'Transfer Rp500.000 ke Budi Santoso berhasil.',
          NotificationType.transaksi, const Duration(minutes: 10), false),
      ('Promo Cashback 20%',
          'Dapatkan cashback 20% untuk pembayaran QRIS minggu ini.',
          NotificationType.promo, const Duration(hours: 3), false),
      ('Pembaruan Aplikasi',
          'Versi terbaru tersedia dengan peningkatan keamanan.',
          NotificationType.info, const Duration(days: 1), true),
      ('Pembayaran Listrik', 'Pembayaran tagihan PLN Rp350.000 berhasil.',
          NotificationType.transaksi, const Duration(days: 2), true),
    ];

    final batch = _db.batch();
    for (final d in data) {
      batch.set(_col(userId).doc(), {
        'title': d.$1,
        'message': d.$2,
        'type': d.$3.name,
        'isRead': d.$5,
        'tanggal': Timestamp.fromDate(now.subtract(d.$4)),
      });
    }
    await batch.commit();
  }
}
