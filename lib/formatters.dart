/// Format angka & tanggal tanpa paket tambahan (tidak perlu intl).
const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _bulanSingkat = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// 2250000 -> "Rp 2.250.000"
String rupiah(num value, {bool prefix = true}) {
  final s = value.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  final sign = value < 0 ? '-' : '';
  return '$sign${prefix ? 'Rp ' : ''}$buf';
}

/// "12 Januari 2024"
String tanggalPanjang(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// "12 Jan 2024"
String tanggalSingkat(DateTime d) =>
    '${d.day} ${_bulanSingkat[d.month - 1]} ${d.year}';

/// "16:05"
String jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
