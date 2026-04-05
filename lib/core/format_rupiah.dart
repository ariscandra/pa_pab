import 'package:intl/intl.dart';

final NumberFormat _formatRupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRupiah(int nilai) {
  return _formatRupiah.format(nilai);
}

String formatRupiahAscii(int nilai) {
  final neg = nilai < 0;
  final n = nilai.abs();
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      b.write('.');
    }
    b.write(s[i]);
  }
  return '${neg ? '-' : ''}Rp ${b.toString()}';
}
