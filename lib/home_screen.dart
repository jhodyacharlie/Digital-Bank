import 'package:flutter/material.dart';

import 'app_style.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        title: const Text('Digeboy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Digeboy',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.biruTua,
          ),
        ),
      ),
    );
  }
}
