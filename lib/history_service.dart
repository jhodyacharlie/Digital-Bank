import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'transaction_model.dart';

class HistoryService {
  HistoryService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Pengguna belum login untuk membuka riwayat transaksi.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _txCollection =>
      _db.collection('users').doc(_uid).collection('mutasi');

  TransactionModel _modelFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final dateValue = data['tanggal'];
    final date = dateValue is Timestamp ? dateValue.toDate() : DateTime.now();
    final type = (data['tipe'] ?? 'debit').toString().toLowerCase();
    final kind = (data['jenis'] ?? '').toString().toLowerCase();
    final status = (data['status'] ?? 'berhasil').toString().toLowerCase();
    final name = (data['nama'] ?? '').toString().trim();
    final description = (data['berita'] ?? '').toString().trim();

    return TransactionModel(
      id: doc.id,
      title: description.isNotEmpty
          ? description
          : (kind.isNotEmpty ? kind : 'Transaksi'),
      subtitle: name.isNotEmpty ? name : null,
      amount: ((data['nominal'] as num?) ?? 0).abs().toDouble(),
      isIncome: type == 'kredit' || type == 'credit',
      date: date,
      category: _categoryFrom(kind),
      status: _statusFrom(status),
      referenceNumber: (data['idTransaksi'] ?? doc.id).toString(),
      notes: description.isNotEmpty ? description : null,
      recipientName: name.isNotEmpty ? name : null,
      recipientAccount: data['rekeningLawan']?.toString(),
    );
  }

  TransactionCategory _categoryFrom(String kind) {
    if (kind.contains('qris')) return TransactionCategory.qris;
    if (kind.contains('tunai') || kind.contains('tarik')) {
      return TransactionCategory.tunai;
    }
    if (kind.contains('top up') ||
        kind.contains('topup') ||
        kind.contains('pulsa')) {
      return TransactionCategory.topUp;
    }
    if (kind.contains('bayar') ||
        kind.contains('tagihan') ||
        kind.contains('bpjs')) {
      return TransactionCategory.tagihan;
    }
    if (kind.contains('beli') ||
        kind.contains('belanja') ||
        kind.contains('pembelian')) {
      return TransactionCategory.belanja;
    }
    return TransactionCategory.transfer;
  }

  TransactionStatus _statusFrom(String status) {
    if (status.contains('pending')) return TransactionStatus.pending;
    if (status.contains('gagal') || status.contains('failed')) {
      return TransactionStatus.gagal;
    }
    return TransactionStatus.berhasil;
  }

  bool _matches(
    TransactionModel tx, {
    DateTimeRange? dateRange,
    TransactionCategory? category,
    TransactionStatus? status,
    bool? isIncome,
  }) {
    if (category != null && tx.category != category) return false;
    if (status != null && tx.status != status) return false;
    if (isIncome != null && tx.isIncome != isIncome) return false;
    if (dateRange != null) {
      final start = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
      );
      final endExclusive = DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
      ).add(const Duration(days: 1));
      if (tx.date.isBefore(start) || !tx.date.isBefore(endExclusive)) {
        return false;
      }
    }
    return true;
  }

  Stream<List<TransactionModel>> streamTransactions({
    DateTimeRange? dateRange,
    TransactionCategory? category,
    TransactionStatus? status,
    bool? isIncome,
  }) {
    return _txCollection
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(_modelFromDoc)
              .where(
                (tx) => _matches(
                  tx,
                  dateRange: dateRange,
                  category: category,
                  status: status,
                  isIncome: isIncome,
                ),
              )
              .toList(),
        );
  }

  Future<TransactionModel?> getTransaction(String id) async {
    final doc = await _txCollection.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final dateValue = data['tanggal'];
    final date = dateValue is Timestamp ? dateValue.toDate() : DateTime.now();
    final type = (data['tipe'] ?? 'debit').toString().toLowerCase();
    final kind = (data['jenis'] ?? '').toString().toLowerCase();
    final status = (data['status'] ?? 'berhasil').toString().toLowerCase();
    final name = (data['nama'] ?? '').toString().trim();
    final description = (data['berita'] ?? '').toString().trim();

    return TransactionModel(
      id: doc.id,
      title: description.isNotEmpty
          ? description
          : (kind.isNotEmpty ? kind : 'Transaksi'),
      subtitle: name.isNotEmpty ? name : null,
      amount: ((data['nominal'] as num?) ?? 0).abs().toDouble(),
      isIncome: type == 'kredit' || type == 'credit',
      date: date,
      category: _categoryFrom(kind),
      status: _statusFrom(status),
      referenceNumber: (data['idTransaksi'] ?? doc.id).toString(),
      notes: description.isNotEmpty ? description : null,
      recipientName: name.isNotEmpty ? name : null,
      recipientAccount: data['rekeningLawan']?.toString(),
    );
  }

  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final snap = await _txCollection
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('tanggal', isLessThan: Timestamp.fromDate(end))
        .get();

    double income = 0;
    double expense = 0;
    for (final doc in snap.docs) {
      final tx = _modelFromDoc(doc);
      if (tx.status != TransactionStatus.berhasil) continue;
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return MonthlySummary(
      monthLabel: DateFormat('MMMM yyyy', 'id').format(month),
      totalIncome: income,
      totalExpense: expense,
    );
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final q = query.trim().toLowerCase();
    final snap = await _txCollection.orderBy('tanggal', descending: true).get();
    if (q.isEmpty) return snap.docs.map(_modelFromDoc).toList();
    return snap.docs
        .map(_modelFromDoc)
        .where(
          (tx) =>
              tx.title.toLowerCase().contains(q) ||
              (tx.subtitle?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
}
