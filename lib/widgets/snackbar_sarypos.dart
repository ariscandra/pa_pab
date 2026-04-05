import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';

enum TipeSnackbarSarypos { sukses, error, info, peringatan }

void tampilkanSnackbarSarypos(
  BuildContext context, {
  required TipeSnackbarSarypos tipe,
  required String pesan,
}) {
  final tema = Theme.of(context);
  Color latar;
  IconData ikon;

  switch (tipe) {
    case TipeSnackbarSarypos.sukses:
      latar = WarnaSarypos.hijauSukses;
      ikon = Icons.check_circle_outline;
      break;
    case TipeSnackbarSarypos.error:
      latar = WarnaSarypos.saryRed;
      ikon = Icons.error_outline;
      break;
    case TipeSnackbarSarypos.info:
      latar = WarnaSarypos.deepTeal;
      ikon = Icons.info_outline;
      break;
    case TipeSnackbarSarypos.peringatan:
      latar = WarnaSarypos.saryGold;
      ikon = Icons.warning_amber_rounded;
      break;
  }

  final latarGelap =
      ThemeData.estimateBrightnessForColor(latar) == Brightness.dark;
  final warnaTeks = switch (tipe) {
    TipeSnackbarSarypos.peringatan => tema.colorScheme.onSecondary,
    _ => latarGelap ? tema.colorScheme.onPrimary : tema.colorScheme.onSurface,
  };
  final warnaIkonSekunder = warnaTeks.withValues(alpha: 0.78);

  final snackBar = SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    content: SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                latar.withValues(alpha: 0.96),
                latar.withValues(alpha: 0.76),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -24,
                top: -30,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WarnaSarypos.saryGold.withValues(
                      alpha: tipe == TipeSnackbarSarypos.peringatan
                          ? 0.06
                          : 0.12,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -36,
                bottom: -60,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WarnaSarypos.deepTeal.withValues(
                      alpha: tipe == TipeSnackbarSarypos.peringatan
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
                        pesan,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: warnaTeks,
                        ),
                      ),
                    ),
                    Icon(Icons.close, size: 20, color: warnaIkonSekunder),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(snackBar);
}
