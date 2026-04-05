import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengelola_notifikasi_in_app.dart';
import 'package:sarypos/core/warisan_notifikasi_in_app.dart';

class BannerNotifikasiInApp extends StatelessWidget {
  const BannerNotifikasiInApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pengelola = WarisanNotifikasiInApp.mungkinDari(context);
    if (pengelola == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: pengelola,
      builder: (context, _) {
        final item = pengelola.aktif;
        if (item == null) {
          return const SizedBox.shrink();
        }
        final tema = Theme.of(context);

        late final Color latar;
        late final IconData ikon;
        switch (item.tipe) {
          case TipeNotifikasiInApp.sukses:
            latar = WarnaSarypos.hijauSukses;
            ikon = Icons.check_circle_outline;
            break;
          case TipeNotifikasiInApp.info:
            latar = WarnaSarypos.deepTeal;
            ikon = Icons.info_outline;
            break;
          case TipeNotifikasiInApp.peringatan:
            latar = WarnaSarypos.saryGold;
            ikon = Icons.warning_amber_rounded;
            break;
          case TipeNotifikasiInApp.error:
            latar = WarnaSarypos.saryRed;
            ikon = Icons.error_outline;
            break;
        }

        final latarGelap =
            ThemeData.estimateBrightnessForColor(latar) == Brightness.dark;
        final warnaTeks = switch (item.tipe) {
          TipeNotifikasiInApp.peringatan => tema.colorScheme.onSecondary,
          _ =>
            latarGelap
                ? tema.colorScheme.onPrimary
                : tema.colorScheme.onSurface,
        };
        final warnaIkonSekunder = warnaTeks.withValues(alpha: 0.78);

        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: InkWell(
            onTap: () => pengelola.tutup(),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      latar.withValues(alpha: 0.96),
                      latar.withValues(alpha: 0.74),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: -26,
                      top: -32,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarnaSarypos.saryGold.withValues(
                            alpha: item.tipe == TipeNotifikasiInApp.peringatan
                                ? 0.06
                                : 0.12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -46,
                      bottom: -72,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarnaSarypos.deepTeal.withValues(
                            alpha: item.tipe == TipeNotifikasiInApp.peringatan
                                ? 0.14
                                : 0.08,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(ikon, color: warnaTeks),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.pesan,
                              style: tema.textTheme.bodyMedium?.copyWith(
                                color: warnaTeks,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.close, size: 20, color: warnaIkonSekunder),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
