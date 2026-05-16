import 'package:flutter/material.dart';
import 'package:sarypos/core/label_metode_pembayaran.dart';

class BarisMetodePembayaran extends StatelessWidget {
  const BarisMetodePembayaran({
    super.key,
    required this.kodeMetode,
    required this.terpilih,
    required this.onPilih,
    this.nonaktif = false,
  });

  final List<String> kodeMetode;
  final String terpilih;
  final ValueChanged<String> onPilih;
  final bool nonaktif;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final teksKecil = Theme.of(context).textTheme.labelSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode pembayaran',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kodeMetode.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, indeks) {
              final k = kodeMetode[indeks];
              final dipilih = terpilih == k;
              return FilterChip(
                label: Text(
                  labelMetodePembayaran(k),
                  style: teksKecil?.copyWith(
                    fontWeight: dipilih ? FontWeight.w600 : FontWeight.w500,
                    color: dipilih ? skema.primary : skema.onSurface,
                  ),
                ),
                selected: dipilih,
                onSelected: nonaktif
                    ? null
                    : (_) {
                        onPilih(k);
                      },
                showCheckmark: true,
                selectedColor: skema.primary.withValues(alpha: 0.14),
                checkmarkColor: skema.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              );
            },
          ),
        ),
      ],
    );
  }
}
