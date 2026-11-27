import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const windows = WindowsInitializationSettings(
        appName: 'MyBCA',
        appUserModelId: 'com.example.digital_banking',
        guid: '8f16a540-4a91-4b23-8c7b-3f55b6c2f41a',
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        windows: windows,
      );
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init skipped: $e');
    }
  }

  Future<void> show({
    required String idKey,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'mybca_general',
        'MyBCA Notifikasi',
        channelDescription: 'Notifikasi promo, berita, dan transaksi MyBCA',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );
      final id = idKey.hashCode & 0x7fffffff;
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('LocalNotificationService show failed: $e');
    }
  }
}
