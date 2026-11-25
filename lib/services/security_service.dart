import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _hashPIN(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<bool> savePIN(String userId, String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      return false;
    }

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();

      if (!doc.exists) return false;

      await userRef.update({
        'pin': _hashPIN(pin),
        // OTP di aplikasi ini hanya simulasi lokal, bukan verifikasi email/HP.
        'otpDemoCompleted': true,
        'registrationCompleted': true,
        'accountStatus': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getPIN(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    final data = doc.data();
    return data?['pin'] as String?;
  }

  Future<bool> hasPIN(String userId) async {
    final pin = await getPIN(userId);
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> deletePIN(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'pin': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
