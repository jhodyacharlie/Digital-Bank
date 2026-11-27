import 'dart:math';

class OTPModel {
  final String email;
  final String code;
  final DateTime createdAt;
  final bool isVerified;

  OTPModel({
    required this.email,
    required this.code,
    required this.createdAt,
    this.isVerified = false,
  });

  static String generateOTP() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  bool get isExpired {
    return DateTime.now().difference(createdAt).inMinutes >= 3;
  }
}
