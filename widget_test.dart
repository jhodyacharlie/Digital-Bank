import 'package:digital_payment/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('beranda tampil dan bisa membuka halaman Pembayaran',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Pembayaran'), findsOneWidget);
    expect(find.text('Status Transaksi'), findsOneWidget);

    await tester.tap(find.text('Pembayaran'));
    await tester.pumpAndSettle();

    expect(find.text('Bayar ke rekening Digeboy'), findsOneWidget);
  });
}
