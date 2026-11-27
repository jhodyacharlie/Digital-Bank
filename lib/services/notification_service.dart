import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

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
}
