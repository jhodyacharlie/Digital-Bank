import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/security_controller.dart';
import '../login_screen.dart';

class SecurityView extends StatefulWidget {
  final String userId;

  const SecurityView({super.key, required this.userId});

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  final SecurityController _controller = SecurityController();

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  String? _message;
  bool _isSuccess = false;
  bool _isLoading = false;

  Future<void> _createPIN() async {
    setState(() {
      _message = null;
      _isSuccess = false;
    });

    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (!_controller.createPIN(pin)) {
      setState(() {
        _message = 'PIN harus terdiri dari 6 digit angka.';
      });
      return;
    }

    if (!_controller.confirmPIN(confirmPin)) {
      _controller.resetPIN();

      setState(() {
        _message = 'Konfirmasi PIN tidak cocok.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final saved = await _controller.savePIN(widget.userId);

      if (!mounted) return;

      if (!saved) {
        setState(() {
          _message = 'PIN gagal disimpan ke Firebase.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _message = 'PIN berhasil disimpan ke Firebase!';
        _isSuccess = true;
        _isLoading = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text(
            'Security PIN berhasil dibuat. '
            'Registrasi akun selesai. Silakan login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Terjadi kesalahan saat menyimpan PIN.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B3D91);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Security PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Buat Security PIN',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Buat PIN 6 digit untuk keamanan akun Digital Banking DIGEBOY.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Buat PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Konfirmasi PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPIN,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Buat PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
