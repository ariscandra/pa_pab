import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';

class CardSarypos extends StatelessWidget {
  const CardSarypos({
    super.key,
    required this.child,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.onTap,
    this.tampilkanKonturTipis = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  final double? elevation;
  final VoidCallback? onTap;

  final bool tampilkanKonturTipis;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? const BorderRadius.all(Radius.circular(12));
    final skema = Theme.of(context).colorScheme;
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final temaKartu = Theme.of(context).cardTheme;
    final el = elevation ?? temaKartu.elevation ?? 2;
    final datar = el <= 0;
    final warnaDasarKartu = gelap
        ? skema.surfaceContainerHighest
        : WarnaSarypos.cleanWhite;
    final warnaAksenDasar = gelap
        ? WarnaSarypos.deepTeal.withValues(alpha: 0.22)
        : WarnaSarypos.deepTeal.withValues(alpha: 0.04);

    final kontur = datar && tampilkanKonturTipis
        ? BorderSide(
            color: WarnaSarypos.warmGray.withValues(alpha: gelap ? 0.35 : 0.5),
            width: 1,
          )
        : BorderSide.none;

    final isi = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [warnaDasarKartu, warnaAksenDasar],
        ),
        borderRadius: radius,
      ),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WarnaSarypos.saryGold.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: -90,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WarnaSarypos.saryRed.withValues(alpha: 0.07),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      elevation: el,
      shadowColor: datar ? Colors.transparent : null,
      surfaceTintColor: datar ? Colors.transparent : null,
      shape: RoundedRectangleBorder(borderRadius: radius, side: kontur),
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: radius, child: isi)
          : isi,
    );
  }
}
