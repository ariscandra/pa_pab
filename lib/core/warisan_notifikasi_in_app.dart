import 'package:flutter/widgets.dart';
import 'package:sarypos/core/pengelola_notifikasi_in_app.dart';

class WarisanNotifikasiInApp
    extends InheritedNotifier<PengelolaNotifikasiInApp> {
  const WarisanNotifikasiInApp({
    super.key,
    required PengelolaNotifikasiInApp pengelola,
    required super.child,
  }) : super(notifier: pengelola);

  static PengelolaNotifikasiInApp dari(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<WarisanNotifikasiInApp>();
    assert(w != null, 'WarisanNotifikasiInApp tidak ada di pohon widget');
    return w!.notifier!;
  }

  static PengelolaNotifikasiInApp? mungkinDari(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WarisanNotifikasiInApp>()
        ?.notifier;
  }
}
