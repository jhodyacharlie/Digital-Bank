import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

// ── Enums ────────────────────────────────────────────────────

enum TransactionCategory { transfer, qris, topUp, tagihan, belanja, tunai }

enum TransactionStatus { berhasil, pending, gagal }

// ── Category Extensions ───────────────────────────────────────

extension TransactionCategoryExt on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.transfer: return 'Transfer';
      case TransactionCategory.qris:     return 'QRIS';
      case TransactionCategory.topUp:    return 'Top Up';
      case TransactionCategory.tagihan:  return 'Tagihan';
      case TransactionCategory.belanja:  return 'Belanja';
      case TransactionCategory.tunai:    return 'Tunai';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionCategory.transfer: return Icons.swap_horiz_rounded;
      case TransactionCategory.qris:     return Icons.qr_code_rounded;
      case TransactionCategory.topUp:    return Icons.add_circle_outline_rounded;
      case TransactionCategory.tagihan:  return Icons.receipt_long_rounded;
      case TransactionCategory.belanja:  return Icons.shopping_bag_outlined;
      case TransactionCategory.tunai:    return Icons.payments_outlined;
    }
  }

  Color get color {
    switch (this) {
      case TransactionCategory.transfer: return const Color(0xFF5B7FDE);
      case TransactionCategory.qris:     return const Color(0xFF9B59B6);
      case TransactionCategory.topUp:    return const Color(0xFF16864B);
      case TransactionCategory.tagihan:  return const Color(0xFFE6A817);
      case TransactionCategory.belanja:  return const Color(0xFFE67E22);
      case TransactionCategory.tunai:    return const Color(0xFF07549A);
    }
  }

  static TransactionCategory fromString(String s) {
    return TransactionCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TransactionCategory.transfer,
    );
  }
}

// ── Status Extensions ─────────────────────────────────────────

extension TransactionStatusExt on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.berhasil: return 'Berhasil';
      case TransactionStatus.pending:  return 'Pending';
      case TransactionStatus.gagal:    return 'Gagal';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.berhasil: return BCAColors.incomeGreen;
      case TransactionStatus.pending:  return BCAColors.pendingOrange;
      case TransactionStatus.gagal:    return BCAColors.expenseRed;
    }
  }

  Color get bgColor {
    switch (this) {
      case TransactionStatus.berhasil: return BCAColors.successBg;
      case TransactionStatus.pending:  return BCAColors.pendingBg;
      case TransactionStatus.gagal:    return BCAColors.failedBg;
    }
  }

  static TransactionStatus fromString(String s) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TransactionStatus.berhasil,
    );
  }
}

// ── TransactionModel ──────────────────────────────────────────

class TransactionModel {
  final String id;
  final String title;
  final String? subtitle;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final TransactionCategory category;
  final TransactionStatus status;
  final String? referenceNumber;
  final String? notes;
  final String? recipientName;
  final String? recipientAccount;
  final String? bankName;

  TransactionModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
    required this.status,
    this.referenceNumber,
    this.notes,
    this.recipientName,
    this.recipientAccount,
    this.bankName,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id:               doc.id,
      title:            data['title'] ?? '',
      subtitle:         data['subtitle'],
      amount:           (data['amount'] as num).toDouble(),
      isIncome:         data['isIncome'] ?? false,
      date:             (data['date'] as Timestamp).toDate(),
      category:         TransactionCategoryExt.fromString(data['category'] ?? 'transfer'),
      status:           TransactionStatusExt.fromString(data['status'] ?? 'berhasil'),
      referenceNumber:  data['referenceNumber'],
      notes:            data['notes'],
      recipientName:    data['recipientName'],
      recipientAccount: data['recipientAccount'],
      bankName:         data['bankName'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':            title,
    'subtitle':         subtitle,
    'amount':           amount,
    'isIncome':         isIncome,
    'date':             Timestamp.fromDate(date),
    'category':         category.name,
    'status':           status.name,
    'referenceNumber':  referenceNumber,
    'notes':            notes,
    'recipientName':    recipientName,
    'recipientAccount': recipientAccount,
    'bankName':         bankName,
  };
}

// ── MonthlySummary ────────────────────────────────────────────

class MonthlySummary {
  final String monthLabel;
  final double totalIncome;
  final double totalExpense;
  double get netCashFlow => totalIncome - totalExpense;

  MonthlySummary({
    required this.monthLabel,
    required this.totalIncome,
    required this.totalExpense,
  });
}
