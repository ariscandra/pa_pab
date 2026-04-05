import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/widgets/card_sarypos.dart';

class CardRingkasan extends StatelessWidget {
  const CardRingkasan({
    super.key,
    required this.judul,
    required this.nilaiUtama,
    required this.ikon,
    this.warnaAksen,
    this.margin,
  });

  final String judul;
  final String nilaiUtama;
  final IconData ikon;
  final Color? warnaAksen;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final teksTema = tema.textTheme;
    final warna =
        warnaAksen ??
        (tema.brightness == Brightness.dark
            ? tema.colorScheme.secondary
            : WarnaSarypos.deepTeal);
    final latarIkon = tema.brightness == Brightness.dark
        ? warna.withValues(alpha: 0.24)
        : warna.withValues(alpha: 0.12);

    return CardSarypos(
      margin: margin ?? EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: teksTema.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    nilaiUtama,
                    style: teksTema.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: latarIkon,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(ikon, color: warna),
            ),
          ],
        ),
      ),
    );
  }
}
