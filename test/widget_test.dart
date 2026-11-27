import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:digital_banking/forgot_pin_screen.dart';
import 'package:digital_banking/login_screen.dart';
import 'package:digital_banking/services/locale_service.dart';
import 'package:digital_banking/user_service.dart';
import 'package:digital_banking/widgets/mybca_mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Lupa PIN?'), findsOneWidget);
    expect(find.text('Daftar sekarang'), findsOneWidget);
  });

  testWidgets('ForgotPinScreen renders email step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPinScreen()));
    expect(find.text('Lupa PIN'), findsOneWidget);
    expect(find.text('Kirim Email'), findsOneWidget);
  });

  test('UserService.normalisasiPhone formats Indonesian numbers', () {
    expect(UserService.normalisasiPhone('+62 812-3456-7890'), '081234567890');
    expect(UserService.normalisasiPhone('6281234567890'), '081234567890');
    expect(UserService.normalisasiPhone('081234567890'), '081234567890');
  });

  test('kirimResetPin rejects invalid email format before Firebase call', () {
    final service = UserService();
    expect(
      () => service.kirimResetPin('bukan-email'),
      throwsA(isA<RegisterException>()),
    );
  });

  test('LocaleService switches between Indonesian and English', () async {
    await LocaleService.setLanguage(LocaleService.english);
    expect(LocaleService.tr('Beranda', 'Home'), 'Home');
    await LocaleService.setLanguage(LocaleService.indonesian);
    expect(LocaleService.tr('Beranda', 'Home'), 'Beranda');
  });

  testWidgets('MyBcaMascot renders and handles tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyBcaMascot(speechText: 'Halo!', onTap: () => tapped = true),
        ),
      ),
    );
    expect(find.byType(MyBcaMascot), findsOneWidget);
    expect(find.text('Halo!'), findsOneWidget);
    await tester.tap(find.byType(MyBcaMascot));
    expect(tapped, isTrue);
  });
}
