class SecurityModel {
  final String pin;
  final DateTime createdAt;

  SecurityModel({required this.pin, required this.createdAt});

  static bool isValidPIN(String pin) {
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  static bool confirmPIN(String pin, String confirmPin) {
    return pin == confirmPin;
  }
}
