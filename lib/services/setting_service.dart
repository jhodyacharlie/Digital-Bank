import 'package:cloud_firestore/cloud_firestore.dart';

import '../user_service.dart';

class SettingService {
  SettingService({FirebaseFirestore? firestore, UserService? users})
    : _db = firestore ?? FirebaseFirestore.instance,
      _users = users ?? UserService();

  final FirebaseFirestore _db;
  final UserService _users;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  Future<Map<String, dynamic>?> getUser(String uid) async =>
      (await _user(uid).get()).data();

  Future<void> updateSettings(String uid, Map<String, dynamic> values) =>
      _user(uid).update({
        for (final entry in values.entries)
          'settings.${entry.key}': entry.value,
      });

  Future<bool> cekPin(String uid, String pin) => _users.cekPin(uid, pin);

  Future<void> ubahPin(String uid, String newPin, {required String oldPin}) =>
      _users.changePin(uid, newPin, pinLama: oldPin);

  Future<void> ubahPassword(
    String uid,
    String oldPassword,
    String newPassword,
  ) => _users.changeAccountPassword(oldPassword, newPassword);

  Future<void> ubahEmail(String uid, String email) =>
      _users.changeAccountEmail(email);
}
