enum NotificationType { transaksi, promo, info }

class NotificationModel {
  final int id;
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
}
