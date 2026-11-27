import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'formatters.dart';
import 'mutasi_model.dart';

Future<void> exportMutasiPdf({
  required MutasiProfile profile,
  required List<MutasiTransaction> items,
  required String periode,
}) async {
  final blue = PdfColor.fromInt(0xFF07549A);
  final green = PdfColor.fromInt(0xFF16864B);
  final red = PdfColor.fromInt(0xFFD94343);

  final totalMasuk = items
      .where((e) => e.isKredit)
      .fold<int>(0, (s, e) => s + e.nominal);
  final totalKeluar = items
      .where((e) => !e.isKredit)
      .fold<int>(0, (s, e) => s + e.nominal);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text(
          'MyBCA - Mutasi Rekening',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: blue,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Nama      : ${profile.nama}'),
        pw.Text('No. Rek   : ${profile.noRekening}'),
        pw.Text('Periode   : $periode'),
        pw.Text('Saldo     : ${rupiah(profile.saldo)}'),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Keterangan', 'Status', 'Jumlah'],
          data: items
              .map(
                (e) => [
                  '${tanggalSingkat(e.tanggal)}\n${jam(e.tanggal)}',
                  '${e.nama}\n${e.berita}',
                  e.status,
                  '${e.isKredit ? '+' : '-'} ${rupiah(e.nominal)}',
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          headerDecoration: pw.BoxDecoration(color: blue),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
          },
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 5,
          ),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Total uang masuk : ${rupiah(totalMasuk)}',
                  style: pw.TextStyle(
                    color: green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Total uang keluar: ${rupiah(totalKeluar)}',
                  style: pw.TextStyle(
                    color: red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'mutasi_mycba.pdf',
  );
}
