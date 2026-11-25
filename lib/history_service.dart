import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_model.dart';

class HistoryService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _txCollection =>
      _db.collection('users').doc(_uid).collection('transactions');

  /// Stream semua transaksi dengan filter opsional
  Stream<List<TransactionModel>> streamTransactions({
    DateTimeRange? dateRange,
    TransactionCategory? category,
    TransactionStatus? status,
    bool? isIncome,
  }) {
    Query query = _txCollection.orderBy('date', descending: true);

    if (dateRange != null) {
      query = query
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(
                  dateRange.end.add(const Duration(days: 1))));
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (isIncome != null) {
      query = query.where('isIncome', isEqualTo: isIncome);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList());
  }

  /// Ambil satu transaksi berdasarkan ID
  Future<TransactionModel?> getTransaction(String id) async {
    final doc = await _txCollection.doc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }

  /// Hitung ringkasan bulanan (income & expense)
  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end   = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snap = await _txCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .where('status', isEqualTo: 'berhasil')
        .get();

    double income = 0, expense = 0;
    for (final doc in snap.docs) {
      final data   = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      if (data['isIncome'] == true) {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return MonthlySummary(
      monthLabel:    DateFormat('MMMM yyyy', 'id').format(month),
      totalIncome:   income,
      totalExpense:  expense,
    );
  }

  /// Cari transaksi berdasarkan keyword (prefix search pada title)
  Future<List<TransactionModel>> searchTransactions(String query) async {
    final snap = await _txCollection
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();
    return snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList();
  }
}
