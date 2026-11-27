import 'package:cloud_firestore/cloud_firestore.dart';

import 'saved_account.dart';

class TransferReferenceService {
  TransferReferenceService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('referensi');

  Stream<List<SavedAccount>> watch(String userId) {
    return _col(userId).snapshots().map((snap) {
      final list = snap.docs.map(SavedAccount.fromDoc).toList();
      list.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return list;
    });
  }

  Future<bool> exists(
    String userId,
    String bank,
    String noRekening, {
    String? exceptId,
  }) async {
    final q = await _col(userId)
        .where('bank', isEqualTo: bank)
        .where('noRekening', isEqualTo: noRekening)
        .get();
    return q.docs.any((d) => d.id != exceptId);
  }

  Future<void> add(String userId, SavedAccount a) {
    return _col(userId)
        .add({...a.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> update(String userId, SavedAccount a) {
    return _col(userId).doc(a.id).update(a.toMap());
  }

  Future<void> toggleFavorite(String userId, SavedAccount a) {
    return _col(userId).doc(a.id).update({'favorit': !a.favorit});
  }

  Future<void> delete(String userId, String id) {
    return _col(userId).doc(id).delete();
  }
}
