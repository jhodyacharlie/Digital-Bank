import '../models/security_model.dart';
import '../services/security_service.dart';

class SecurityController {
  String? _pin;
  final SecurityService _service = SecurityService();
  String? get saveError => _service.lastError;

  bool createPIN(String pin) {
    if (!SecurityModel.isValidPIN(pin)) {
      return false;
    }

    _pin = pin;
    return true;
  }

  bool confirmPIN(String confirmPin) {
    if (_pin == null) return false;

    return SecurityModel.confirmPIN(_pin!, confirmPin);
  }

  Future<bool> savePIN(Map<String, dynamic> profile) async {
    if (_pin == null) return false;

    return _service.savePIN(profile, _pin!);
  }

  Future<String?> getSavedPIN(String userId) async {
    return _service.getPIN(userId);
  }

  Future<bool> hasSavedPIN(String userId) async {
    return _service.hasPIN(userId);
  }

  Future<bool> deletePIN(String userId) async {
    _pin = null;
    return _service.deletePIN(userId);
  }

  String? get pin => _pin;

  void resetPIN() {
    _pin = null;
  }
}
