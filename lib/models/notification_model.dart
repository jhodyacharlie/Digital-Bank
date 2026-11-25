import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { transaksi, promo, info }

/// Dokumen Firestore: users/{userId}/notifications/{id}
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      date: date,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final tgl = d['tanggal'];
    return NotificationModel(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      message: (d['message'] ?? '') as String,
      // serverTimestamp bisa null sesaat sebelum server membalas
      date: tgl is Timestamp ? tgl.toDate() : DateTime.now(),
      type: NotificationType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => NotificationType.info,
      ),
      isRead: (d['isRead'] ?? false) as bool,
    );
  }
}
