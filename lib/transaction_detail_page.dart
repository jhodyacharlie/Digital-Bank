import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'app_colors.dart';
import 'transaction_model.dart';
import 'history_widgets.dart';
import 'receipt_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Scaffold(
      backgroundColor: BCAColors.lightGray,
      appBar: AppBar(
        backgroundColor: BCAColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _shareReceipt(tx),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AmountCard(tx: tx),
            const SizedBox(height: 16),
            _DetailCard(tx: tx),
            const SizedBox(height: 16),
            _buildActions(context, tx),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, TransactionModel tx) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ReceiptPage(transaction: tx)),
            ),
            icon: const Icon(Icons.receipt_outlined, size: 18),
            label: const Text('Lihat Bukti'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BCAColors.primaryBlue,
              side: const BorderSide(color: BCAColors.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareReceipt(tx),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Bagikan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BCAColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareReceipt(TransactionModel tx) async {
    final text = '''
*Bukti Transaksi MyBCA*
------------------------
${tx.title}
Tanggal : ${DateFormat('d MMMM yyyy HH:mm', 'id').format(tx.date)}
Kategori: ${tx.category.label}
Jumlah  : ${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}
Status  : ${tx.status.label}
${tx.referenceNumber != null ? 'No. Ref : ${tx.referenceNumber}' : ''}
------------------------
MyBCA – Bank Central Asia
''';
    await Share.share(text, subject: 'Bukti Transaksi MyBCA');
  }
}

// ── Amount Card ───────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final TransactionModel tx;
  const _AmountCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tx.isIncome
              ? [BCAColors.incomeGreen, const Color(0xFF0FAD5F)]
              : [BCAColors.primaryBlue, BCAColors.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(tx.category.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(tx.title,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            '${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          StatusBadge(status: tx.status),
        ],
      ),
    );
  }
}

// ── Detail Card ───────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final TransactionModel tx;
  const _DetailCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Transaksi',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BCAColors.textDark),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: BCAColors.divider),
          const SizedBox(height: 12),
          _row('Tanggal',
              DateFormat('d MMMM yyyy', 'id').format(tx.date)),
          _row('Waktu', DateFormat('HH:mm:ss').format(tx.date)),
          _row('Kategori', tx.category.label),
          if (tx.recipientName != null)
            _row('Nama Penerima', tx.recipientName!),
          if (tx.recipientAccount != null)
            _row('No. Rekening', tx.recipientAccount!),
          if (tx.bankName != null) _row('Bank', tx.bankName!),
          if (tx.referenceNumber != null)
            _row('No. Referensi', tx.referenceNumber!),
          if (tx.notes != null) _row('Catatan', tx.notes!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: BCAColors.secondaryText)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BCAColors.textDark),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
