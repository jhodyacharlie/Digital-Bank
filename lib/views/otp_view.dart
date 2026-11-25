import 'package:flutter/material.dart';

import '../controllers/otp_controller.dart';
import 'security_view.dart';

class OTPView extends StatefulWidget {
  final String email;
  final String userId;

  const OTPView({super.key, required this.email, required this.userId});

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final OTPController _controller = OTPController();
  final TextEditingController _otpInput = TextEditingController();

  String? _generatedOTP;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generatedOTP = _controller.generateOTP(widget.email);
  }

  void _verifyOTP() {
    final input = _otpInput.text.trim();

    if (_controller.verifyOTP(input)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecurityView(userId: widget.userId),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'OTP salah atau sudah kedaluwarsa.';
      });
    }
  }

  void _regenerateOTP() {
    setState(() {
      _generatedOTP = _controller.generateOTP(widget.email);
      _otpInput.clear();
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _otpInput.dispose();
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
        title: const Text('Email Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Verifikasi Email',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              'Masukkan kode OTP untuk ${widget.email}',
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'CODE OTP',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _generatedOTP ?? '',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Kode ini hanya untuk keperluan simulasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _otpInput,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Masukkan OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Verifikasi OTP'),
              ),
            ),

            Center(
              child: TextButton(
                onPressed: _regenerateOTP,
                child: const Text('Generate OTP Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
