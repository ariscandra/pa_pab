import 'package:flutter/widgets.dart';
import 'package:sarypos/core/pengatur_tema.dart';

class WarisanTema extends InheritedNotifier<PengaturTema> {
  const WarisanTema({
    super.key,
    required PengaturTema pengatur,
    required super.child,
  }) : super(notifier: pengatur);

  static PengaturTema dari(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<WarisanTema>();
    assert(w != null, 'WarisanTema tidak ditemukan di pohon widget');
    return w!.notifier!;
  }
}
