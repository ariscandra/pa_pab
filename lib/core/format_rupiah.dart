import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _formatRupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRupiah(int nilai) {
  return _formatRupiah.format(nilai);
}

TextStyle gayaTeksNominal(BuildContext context, {TextStyle? dasar}) {
  final basis = dasar ?? Theme.of(context).textTheme.bodyMedium;
  return (basis ?? const TextStyle()).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class TeksRupiah extends StatelessWidget {
  const TeksRupiah(
    this.nilai, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final int nilai;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatRupiah(nilai),
      style: gayaTeksNominal(context, dasar: style),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
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
