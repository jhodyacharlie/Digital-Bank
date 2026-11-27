import 'package:cloud_firestore/cloud_firestore.dart';

import 'mutasi_model.dart';

class MutasiService {
  MutasiService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _db.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _user(userId).collection('mutasi');

  Future<MutasiProfile> fetchProfile(String userId) async {
    final snap = await _user(userId).get();
    return MutasiProfile.fromMap(snap.data());
  }

  Future<List<MutasiTransaction>> fetchTransactions(String userId) async {
    final snap = await _col(userId).orderBy('tanggal', descending: true).get();
    return snap.docs.map(MutasiTransaction.fromDoc).toList();
  }
}
