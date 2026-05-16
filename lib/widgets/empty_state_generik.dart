import 'package:flutter/material.dart';

class EmptyStateGenerik extends StatelessWidget {
  const EmptyStateGenerik({
    super.key,
    this.ikon,
    this.judul,
    required this.pesan,
    this.labelTombol,
    this.onTekanTombol,
  });

  final IconData? ikon;
  final String? judul;
  final String pesan;
  final String? labelTombol;
  final VoidCallback? onTekanTombol;

  @override
  Widget build(BuildContext context) {
    final teksTema = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTinggi = constraints.maxHeight;
        final tinggiTerbatas =
            maxTinggi.isFinite && maxTinggi < double.infinity;
        final areaKecil = tinggiTerbatas && maxTinggi > 0 && maxTinggi < 90;

        final padding = areaKecil
            ? const EdgeInsets.fromLTRB(16, 4, 16, 4)
            : const EdgeInsets.all(24);
        final iconSize = areaKecil ? 24.0 : 56.0;
        final jarakIkon = areaKecil ? 4.0 : 16.0;
        final jarakJudul = areaKecil ? 4.0 : 8.0;
        final jarakTombol = areaKecil ? 8.0 : 20.0;
        final fontJudul = areaKecil ? 14.0 : null;
        final fontPesan = areaKecil ? 11.0 : null;

        final skema = Theme.of(context).colorScheme;

        final Widget? isiIkon = ikon == null
            ? null
            : areaKecil
                ? Icon(ikon, size: iconSize, color: skema.onSurfaceVariant)
                : Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skema.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      border: Border.all(
                        color: skema.outline.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      ikon,
                      size: iconSize,
                      color: skema.onSurfaceVariant,
                    ),
                  );
        final teksPesan = Text(
          pesan,
          style: teksTema.bodyMedium?.copyWith(
            color: skema.onSurfaceVariant,
            fontSize: fontPesan,
          ),
          textAlign: TextAlign.center,
          maxLines: areaKecil ? 2 : null,
          overflow: areaKecil ? TextOverflow.ellipsis : TextOverflow.visible,
          softWrap: true,
        );

        return Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: tinggiTerbatas
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ?isiIkon,
                if (isiIkon != null) SizedBox(height: jarakIkon),
                if (judul != null)
                  Text(
                    judul!,
                    style: teksTema.titleMedium?.copyWith(fontSize: fontJudul),
                    textAlign: TextAlign.center,
                  ),
                if (judul != null) SizedBox(height: jarakJudul),
                if (tinggiTerbatas)
                  Flexible(fit: FlexFit.loose, child: teksPesan)
                else
                  teksPesan,
                if (onTekanTombol != null && labelTombol != null) ...[
                  SizedBox(height: jarakTombol),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTekanTombol,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(labelTombol!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
