class SecurityModel {
  final String pin;
  final DateTime createdAt;

  SecurityModel({required this.pin, required this.createdAt});

  // Validasi PIN harus 6 digit angka
  static bool isValidPIN(String pin) {
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  // Validasi konfirmasi PIN
  static bool confirmPIN(String pin, String confirmPin) {
    return pin == confirmPin;
  }
}
