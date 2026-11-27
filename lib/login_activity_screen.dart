import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class LoginActivityScreen extends StatelessWidget {
  const LoginActivityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Activity'),
        actions: [
          IconButton(
            tooltip: 'Keluar dari perangkat ini',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('login_activity')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, s) {
          if (s.hasError)
            return Center(child: Text('Gagal memuat aktivitas: ${s.error}'));
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          if (s.data!.docs.isEmpty)
            return const Center(child: Text('Belum ada aktivitas login'));
          return ListView(
            children: s.data!.docs.map((d) {
              final x = d.data();
              final time = (x['createdAt'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.devices),
                title: Text((x['deviceLabel'] ?? 'Perangkat').toString()),
                subtitle: Text(
                  '${x['platform'] ?? 'Flutter'}\n${time?.toLocal() ?? 'Waktu tidak tersedia'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Hapus catatan aktivitas',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => d.reference.delete(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
