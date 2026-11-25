import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'app_colors.dart';
import 'transaction_model.dart';
import 'history_widgets.dart';

class ReceiptPage extends StatelessWidget {
  final TransactionModel transaction;
  const ReceiptPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Scaffold(
      backgroundColor: BCAColors.lightGray,
      appBar: AppBar(
        backgroundColor: BCAColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Bukti Transaksi',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () => _downloadReceipt(tx),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiptCard(tx),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _shareText(tx),
                icon: const Icon(Icons.share_outlined,
                    color: Colors.white),
                label: const Text(
                  'Bagikan Bukti',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BCAColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(TransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header logo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    BCAColors.primaryBlue,
                    BCAColors.secondaryBlue
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('BCA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MyBCA',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: BCAColors.primaryBlue,
                          fontSize: 15)),
                  Text('Bank Central Asia',
                      style: TextStyle(
                          color: BCAColors.secondaryText,
                          fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: BCAColors.divider),
          const SizedBox(height: 16),

          // Status icon
          Icon(
            tx.status == TransactionStatus.berhasil
                ? Icons.check_circle_rounded
                : tx.status == TransactionStatus.pending
                    ? Icons.access_time_rounded
                    : Icons.cancel_rounded,
            size: 56,
            color: tx.status.color,
          ),
          const SizedBox(height: 8),
          Text(
            tx.status.label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tx.status.color),
          ),
          const SizedBox(height: 4),
          Text(tx.title,
              style: const TextStyle(
                  color: BCAColors.secondaryText, fontSize: 13)),
          const SizedBox(height: 12),
          Text(
            '${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: tx.isIncome
                  ? BCAColors.incomeGreen
                  : BCAColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: BCAColors.divider),
          const SizedBox(height: 12),

          // Detail rows
          _receiptRow('Tanggal',
              DateFormat('d MMMM yyyy', 'id').format(tx.date)),
          _receiptRow(
              'Waktu', DateFormat('HH:mm WIB').format(tx.date)),
          _receiptRow('Kategori', tx.category.label),
          if (tx.recipientName != null)
            _receiptRow('Penerima', tx.recipientName!),
          if (tx.recipientAccount != null)
            _receiptRow('No. Rekening', tx.recipientAccount!),
          if (tx.bankName != null) _receiptRow('Bank', tx.bankName!),
          if (tx.referenceNumber != null) ...[
            const SizedBox(height: 8),
            const Divider(color: BCAColors.divider),
            const SizedBox(height: 8),
            _receiptRow(
              'No. Referensi',
              tx.referenceNumber!,
              valueStyle: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: BCAColors.textDark,
                  fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: BCAColors.divider),
          const SizedBox(height: 8),
          const Text(
            'Simpan bukti transaksi ini sebagai tanda pembayaran yang sah.',
            style: TextStyle(
                fontSize: 11, color: BCAColors.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: BCAColors.secondaryText)),
          Text(value,
              style: valueStyle ??
                  const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BCAColors.textDark)),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(TransactionModel tx) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (pw.Context ctx) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('MyBCA – Bank Central Asia',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Bukti Transaksi',
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text(tx.status.label,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(tx.title),
            pw.SizedBox(height: 12),
            pw.Text(
                '${tx.isIncome ? '+' : '-'}${formatCurrency(tx.amount)}',
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              data: [
                ['Tanggal',
                    DateFormat('d MMMM yyyy', 'id').format(tx.date)],
                ['Waktu', DateFormat('HH:mm').format(tx.date)],
                ['Kategori', tx.category.label],
                if (tx.recipientName != null)
                  ['Penerima', tx.recipientName!],
                if (tx.referenceNumber != null)
                  ['No. Ref', tx.referenceNumber!],
              ],
            ),
          ],
        ),
      ),
    ));

    final bytes = await pdf.save();
    await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'bukti-mybca-${tx.id}.pdf');
  }

  Future<void> _shareText(TransactionModel tx) async {
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
