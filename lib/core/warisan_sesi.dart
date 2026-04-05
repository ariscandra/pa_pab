import 'package:flutter/widgets.dart';
import 'package:sarypos/core/pengatur_sesi.dart';

class WarisanSesi extends InheritedNotifier<PengaturSesi> {
  const WarisanSesi({
    super.key,
    required PengaturSesi pengatur,
    required super.child,
  }) : super(notifier: pengatur);

  static PengaturSesi dari(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<WarisanSesi>();
    assert(w != null, 'WarisanSesi tidak ditemukan di pohon widget');
    return w!.notifier!;
  }

  static PengaturSesi? mungkinDari(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WarisanSesi>()?.notifier;
  }
}
