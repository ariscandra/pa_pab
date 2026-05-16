import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';

class ChipFilterSarypos extends StatelessWidget {
  const ChipFilterSarypos({
    super.key,
    required this.label,
    required this.selected,
    required this.onPilih,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onPilih;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gayaTeks = tema.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      height: 1.1,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );
    return ChoiceChip(
      label: Text(label, style: gayaTeks),
      selected: selected,
      onSelected: enabled ? (_) => onPilih() : null,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      side: BorderSide(
        color: selected
            ? WarnaSarypos.deepTeal
            : WarnaSarypos.warmGray.withValues(alpha: 0.9),
      ),
      selectedColor: WarnaSarypos.deepTeal.withValues(alpha: 0.18),
    );
  }
}
