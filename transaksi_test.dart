import 'package:digital_payment/memory_transaksi_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryTransaksiRepository repo;

  setUp(() {
    repo = MemoryTransaksiRepository();
  });

  group('bayar', () {
    test('berhasil: saldo pindah dan tercatat di kedua sisi', () async {
      final hasil = await repo.bayar(
        dariId: 'budi',
        keId: 'siti',
        nominal: 100000,
        berita: 'Tes',
      );

      expect(hasil.berhasil, isTrue);
      expect(hasil.struk!.labelStatus, 'Terkirim');

      expect((await repo.pantauAkun('budi').first).saldo, 15000000 - 100000);
      expect((await repo.pantauAkun('siti').first).saldo, 8500000 + 100000);

      final riwayatBudi = await repo.pantau('budi').first;
      final riwayatSiti = await repo.pantau('siti').first;
      expect(riwayatBudi.single.labelStatus, 'Terkirim');
      expect(riwayatSiti.single.labelStatus, 'Diterima');
      expect(riwayatSiti.single.id, riwayatBudi.single.id);
      expect(riwayatSiti.single.nama, 'Budi Santoso');
    });

    test('saldo kurang: dicatat Gagal, saldo tidak berubah', () async {
      final hasil = await repo.bayar(
        dariId: 'andi',
        keId: 'budi',
        nominal: 999999999,
      );

      expect(hasil.berhasil, isFalse);
      expect(hasil.error, 'Saldo tidak cukup');
      expect(hasil.struk!.gagal, isTrue);

      expect((await repo.pantauAkun('andi').first).saldo, 2250000);
      expect((await repo.pantauAkun('budi').first).saldo, 15000000);
      expect(await repo.pantau('budi').first, isEmpty);
      expect((await repo.pantau('andi').first).single.status, 'Gagal');
    });

    test('nominal 0 dan bayar ke diri sendiri ditolak tanpa catatan', () async {
      final nol = await repo.bayar(dariId: 'budi', keId: 'siti', nominal: 0);
      final sendiri =
          await repo.bayar(dariId: 'budi', keId: 'budi', nominal: 1000);

      expect(nol.berhasil, isFalse);
      expect(sendiri.berhasil, isFalse);
      expect(await repo.pantau('budi').first, isEmpty);
    });

    test('rekening tidak dikenal ditolak', () async {
      final hasil =
          await repo.bayar(dariId: 'budi', keId: 'tidak-ada', nominal: 1000);

      expect(hasil.berhasil, isFalse);
      expect(hasil.error, 'Rekening tidak ditemukan');
    });
  });

  group('pencarian dan PIN', () {
    test('cariByRekening menemukan pemilik yang benar', () async {
      expect((await repo.cariByRekening('1000000002'))!.id, 'siti');
      expect(await repo.cariByRekening('0000'), isNull);
    });

    test('cekPin hanya menerima PIN yang benar', () async {
      expect(await repo.cekPin('budi', '123456'), isTrue);
      expect(await repo.cekPin('budi', '654321'), isFalse);
      expect(await repo.cekPin('tidak-ada', '123456'), isFalse);
    });
  });

  test('riwayat penerima berubah sendiri saat uang masuk', () async {
    final jumlah = <int>[];
    final langganan = repo.pantau('siti').listen((d) => jumlah.add(d.length));

    await Future<void>.delayed(Duration.zero);
    await repo.bayar(dariId: 'budi', keId: 'siti', nominal: 1000);
    await Future<void>.delayed(Duration.zero);
    await langganan.cancel();

    expect(jumlah, [0, 1]);
  });
}
