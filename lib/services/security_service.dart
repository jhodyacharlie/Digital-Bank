import '../user_service.dart';

class SecurityService {
  final UserService _users = UserService();
  String? lastError;

  Future<bool> savePIN(Map<String, dynamic> profile, String pin) async {
    lastError = null;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return false;
    try {
      await _users.registerWithPin(profile, pin);
      await _users.logout();
      return true;
    } catch (error) {
      lastError = error.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<String?> getPIN(String userId) async => null;

  Future<bool> hasPIN(String userId) => _users.hasPIN(userId);

  Future<bool> deletePIN(String userId) => _users.deletePIN(userId);
}
