import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';

class JudulBagianSarypos extends StatelessWidget {
  const JudulBagianSarypos({
    super.key,
    required this.judul,
    this.trailing,
  });

  final String judul;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: WarnaSarypos.saryRed.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            judul,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
