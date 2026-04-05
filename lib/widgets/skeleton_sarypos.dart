import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1300),
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final dasar =
        baseColor ??
        (gelap
            ? skema.outline.withValues(alpha: 0.35)
            : WarnaSarypos.warmGray.withValues(alpha: 0.35));
    final sorot =
        highlightColor ??
        (gelap
            ? skema.surfaceContainerHigh.withValues(alpha: 0.9)
            : WarnaSarypos.cleanWhite.withValues(alpha: 0.75));

    return _ShimmerSkeletonCore(
      width: width,
      height: height,
      borderRadius: borderRadius,
      baseColor: dasar,
      highlightColor: sorot,
      duration: duration,
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    required this.width,
    this.height = 12,
    this.borderRadius = 999,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: diameter,
      height: diameter,
      borderRadius: diameter / 2,
    );
  }
}

class _ShimmerSkeletonCore extends StatefulWidget {
  const _ShimmerSkeletonCore({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<_ShimmerSkeletonCore> createState() => _ShimmerSkeletonCoreState();
}

class _ShimmerSkeletonCoreState extends State<_ShimmerSkeletonCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final w = widget.width;
          final dx = (w * 1.6) * (_controller.value * 2 - 1);
          final stripeWidth = w * 0.6;

          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: widget.baseColor),
                ),
                Positioned(
                  top: 0,
                  left: dx,
                  width: stripeWidth,
                  height: widget.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.highlightColor.withValues(alpha: 0),
                          widget.highlightColor.withValues(alpha: 0.55),
                          widget.highlightColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
