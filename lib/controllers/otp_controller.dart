import '../models/otp_model.dart';

class OTPController {
  OTPModel? _otp;

  String? get generatedOTP => _otp?.code;

  // Generate OTP untuk email
  String generateOTP(String email) {
    _otp = OTPModel(
      email: email,
      code: OTPModel.generateOTP(),
      createdAt: DateTime.now(),
    );

    return _otp!.code;
  }

  // Validasi OTP
  bool verifyOTP(String inputOTP) {
    if (_otp == null) return false;
    if (_otp!.isExpired) return false;

    return _otp!.code == inputOTP;
  }

  // Mengecek apakah OTP masih tersedia
  bool get hasOTP => _otp != null;

  // Mengecek email OTP
  String? get email => _otp?.email;

  // Reset OTP
  void resetOTP() {
    _otp = null;
  }
}
