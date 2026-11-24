import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> seedUsers() async {
    final cek = await users.limit(1).get();
    if (cek.docs.isNotEmpty) return;

    final dataContoh = [
      {
        'id': 'budi',
        'nama': 'Budi Santoso',
        'email': 'budi@digeboy.com',
        'phone': '081234567890',
        'pin': '123456',
        'saldo': 15000000,
      },
      {
        'id': 'siti',
        'nama': 'Siti Aminah',
        'email': 'siti@digeboy.com',
        'phone': '081298765432',
        'pin': '654321',
        'saldo': 8500000,
      },
      {
        'id': 'andi',
        'nama': 'Andi Pratama',
        'email': 'andi@digeboy.com',
        'phone': '085711112222',
        'pin': '246810',
        'saldo': 2250000,
      },
    ];

    for (final u in dataContoh) {
      await users.doc(u['id'] as String).set({
        'nama': u['nama'],
        'email': u['email'],
        'phone': u['phone'],
        'pin': hashPin(u['pin'] as String),
        'saldo': u['saldo'],
      });
    }
  }

  Future<Map<String, dynamic>?> findUser(String input) async {
    input = input.trim().toLowerCase().replaceAll(' ', '');
    final field = input.contains('@') ? 'email' : 'phone';

    final hasil = await users.where(field, isEqualTo: input).limit(1).get();
    if (hasil.docs.isEmpty) return null;

    final doc = hasil.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<Map<String, dynamic>?> login(String input, String pin) async {
    final user = await findUser(input);
    if (user == null) return null;
    if (user['pin'] != hashPin(pin)) return null;
    return user;
  }

  Future<String> createResetCode(String userId) async {
    final kode = (100000 + Random().nextInt(900000)).toString();
    final batas = DateTime.now().add(const Duration(minutes: 5));

    await users.doc(userId).update({
      'resetCode': kode,
      'resetExpired': batas.millisecondsSinceEpoch,
    });
    return kode;
  }

  Future<bool> checkResetCode(String userId, String kode) async {
    final doc = await users.doc(userId).get();
    final data = doc.data() as Map<String, dynamic>;

    final kodeAsli = data['resetCode'];
    final batas = data['resetExpired'] ?? 0;

    if (kodeAsli == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > batas) return false;
    return kodeAsli == kode;
  }

  Future<void> changePin(String userId, String pinBaru) async {
    await users.doc(userId).update({
      'pin': hashPin(pinBaru),
      'resetCode': FieldValue.delete(),
      'resetExpired': FieldValue.delete(),
    });
  }

  Future<void> simpanFoto(String userId, String fotoBase64) async {
    await users.doc(userId).update({'foto': fotoBase64});
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    final doc = await users.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<Map<String, dynamic>?> findByRekening(String rekening) async {
    final hasil =
        await users.where('rekening', isEqualTo: rekening).limit(1).get();
    if (hasil.docs.isEmpty) return null;
    final doc = hasil.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<String> ambilRekening(Map<String, dynamic> user) async {
    final ada = user['rekening'];
    if (ada != null) return ada as String;

    final baru = (1000000000 + Random().nextInt(900000000)).toString();
    await users.doc(user['id']).update({'rekening': baru});
    user['rekening'] = baru;
    return baru;
  }

  Future<String?> transfer(String dariId, String keId, int nominal) {
    return FirebaseFirestore.instance.runTransaction<String?>((trx) async {
      final dariRef = users.doc(dariId);
      final keRef = users.doc(keId);

      final dari = await trx.get(dariRef);
      final ke = await trx.get(keRef);

      final saldoDari =
          ((dari.data() as Map<String, dynamic>)['saldo'] as num).toInt();
      final saldoKe =
          ((ke.data() as Map<String, dynamic>)['saldo'] as num).toInt();

      if (saldoDari < nominal) return 'Saldo tidak cukup';

      trx.update(dariRef, {'saldo': saldoDari - nominal});
      trx.update(keRef, {'saldo': saldoKe + nominal});
      return null;
    });
  }
}
