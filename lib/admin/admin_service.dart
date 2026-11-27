import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static const masterUids = <String>{
    'pujv8wh6fmVkVsCTqylwIraeeXB3',
    '32lwk7MOJkYXIJWnZucZpPrWU9u1',
    'M3YKpl63h0SVwo91DbjXAPzIPtH3',
  };

  final FirebaseFirestore db;
  final FirebaseAuth auth;
  AdminService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : db = firestore ?? FirebaseFirestore.instance,
      auth = firebaseAuth ?? FirebaseAuth.instance;

  bool get isAdmin => masterUids.contains(auth.currentUser?.uid);
  void _requireAdmin() {
    if (!isAdmin) throw StateError('Akses khusus admin master.');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> users() {
    _requireAdmin();
    return db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingTopUps() {
    _requireAdmin();
    return db
        .collection('topup_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> verifyUser(String uid, {required bool approve}) async {
    _requireAdmin();
    final ref = db.collection('users').doc(uid);
    await ref.update({
      'verificationStatus': approve ? 'approved' : 'rejected',
      'isVerified': approve,
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': auth.currentUser!.uid,
    });
    await ref.collection('notifications').add({
      'title': approve ? 'Akun Terverifikasi' : 'Verifikasi Ditolak',
      'message': approve ? 'Akun MyBCA kamu telah disetujui admin.' : 'Pendaftaran belum disetujui. Hubungi admin untuk informasi lebih lanjut.',
      'type': 'info',
      'isRead': false,
      'tanggal': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBalance(String uid, int amount, String note) async {
    _requireAdmin();
    if (amount <= 0) throw ArgumentError('Nominal harus lebih dari nol.');
    final userRef = db.collection('users').doc(uid);
    final mutationRef = userRef.collection('mutasi').doc();
    await db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) throw StateError('Pengguna tidak ditemukan.');
      final current = (snap.data()?['saldo'] as num?)?.toInt() ?? 0;
      tx.update(userRef, {'saldo': current + amount});
      tx.set(mutationRef, {
        'idTransaksi': mutationRef.id,
        'tanggal': FieldValue.serverTimestamp(),
        'tipe': 'kredit',
        'nominal': amount,
        'nama': 'Admin MyBCA',
        'berita': note,
        'status': 'Berhasil',
        'jenis': 'Penyesuaian Admin',
        'rekeningLawan': '-',
        'adminUid': auth.currentUser!.uid,
      });
      tx.set(userRef.collection('notifications').doc(), {
        'title': 'Saldo Ditambahkan Admin',
        'message':
            'Saldo ${amount.toString()} berhasil ditambahkan. Catatan: $note',
        'type': 'transaksi',
        'isRead': false,
        'tanggal': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _broadcastContentNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    _requireAdmin();
    final users = await db.collection('users').get();

    for (var start = 0; start < users.docs.length; start += 400) {
      final batch = db.batch();
      final end = (start + 400 < users.docs.length)
          ? start + 400
          : users.docs.length;
      for (final user in users.docs.sublist(start, end)) {
        final ref = user.reference.collection('notifications').doc();
        batch.set(ref, {
          'title': title,
          'message': message,
          'type': type,
          'isRead': false,
          'tanggal': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> publishNews({
    required String title,
    required String summary,
    required String body,
    required DateTime publishedAt,
    String? imageBase64,
  }) async {
    _requireAdmin();
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw ArgumentError('Judul dan isi berita wajib diisi.');
    }
    await db.collection('news').add({
      'title': title.trim(),
      'summary': summary.trim(),
      'body': body.trim(),
      'publishedAt': Timestamp.fromDate(publishedAt),
      'imageBase64': imageBase64,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': auth.currentUser!.uid,
    });
    await _broadcastContentNotification(
      title: 'Berita MyBCA: ${title.trim()}',
      message: summary.trim().isEmpty
          ? 'Ada berita baru di MyBCA.'
          : summary.trim(),
      type: 'info',
    );
  }

  Future<void> publishPromo({
    required String title,
    required String description,
    required String terms,
    required DateTime startsAt,
    required DateTime endsAt,
    String? imageBase64,
  }) async {
    _requireAdmin();
    if (title.trim().isEmpty || endsAt.isBefore(startsAt)) {
      throw ArgumentError('Judul atau periode promo tidak valid.');
    }
    await db.collection('promos').add({
      'title': title.trim(),
      'description': description.trim(),
      'terms': terms.trim(),
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'imageBase64': imageBase64,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': auth.currentUser!.uid,
    });
    await _broadcastContentNotification(
      title: 'Promo baru: ${title.trim()}',
      message: description.trim(),
      type: 'promo',
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> allPromos() {
    _requireAdmin();
    return db
        .collection('promos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> allNews() {
    _requireAdmin();
    return db
        .collection('news')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deletePromo(String id) async {
    _requireAdmin();
    await db.collection('promos').doc(id).delete();
  }

  Future<void> deleteNews(String id) async {
    _requireAdmin();
    await db.collection('news').doc(id).delete();
  }

  Future<void> reviewTopUp(String requestId, {required bool approve}) async {
    _requireAdmin();
    final ref = db.collection('topup_requests').doc(requestId);
    await db.runTransaction((tx) async {
      final req = await tx.get(ref);
      if (!req.exists || req.data()?['status'] != 'pending') {
        throw StateError('Permintaan sudah diproses atau tidak ditemukan.');
      }
      final data = req.data()!;
      final uid = data['uid'] as String;
      final amount = (data['amount'] as num).toInt();
      final expiry = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiry == null || expiry.isBefore(DateTime.now()))
        throw StateError('QR top up sudah kedaluwarsa.');
      tx.update(ref, {
        'status': approve ? 'paid' : 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': auth.currentUser!.uid,
      });
      if (approve) {
        final userRef = db.collection('users').doc(uid);
        final mutasi = userRef.collection('mutasi').doc();
        tx.update(userRef, {'saldo': FieldValue.increment(amount)});
        tx.set(mutasi, {
          'idTransaksi': mutasi.id,
          'tanggal': FieldValue.serverTimestamp(),
          'tipe': 'kredit',
          'nominal': amount,
          'nama': 'Top Up ${data['provider']}',
          'berita': 'Top up terverifikasi admin',
          'status': 'Berhasil',
          'jenis': 'Top Up',
          'rekeningLawan': '-',
        });
        tx.set(userRef.collection('notifications').doc(), {
          'title': 'Top Up Berhasil',
          'message':
              'Top up Rp${amount.toString()} telah diverifikasi dan saldo ditambahkan.',
          'type': 'transaksi',
          'isRead': false,
          'tanggal': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
