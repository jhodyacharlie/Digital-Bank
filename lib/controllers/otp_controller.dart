import '../models/otp_model.dart';

class OTPController {
  OTPModel? _otp;

  String? get generatedOTP => _otp?.code;

  String generateOTP(String email) {
    _otp = OTPModel(
      email: email,
      code: OTPModel.generateOTP(),
      createdAt: DateTime.now(),
    );

    return _otp!.code;
  }

  bool verifyOTP(String inputOTP) {
    if (_otp == null) return false;
    if (_otp!.isExpired) return false;

    return _otp!.code == inputOTP;
  }

  bool get hasOTP => _otp != null;

  String? get email => _otp?.email;

  void resetOTP() {
    _otp = null;
  }
}
