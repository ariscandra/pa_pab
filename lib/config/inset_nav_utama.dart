import 'package:flutter/material.dart';



abstract final class InsetNavUtama {

  static const double tinggiKontenBottomBar = 88;

  static const double lebarTitikTengahNav = 80;

  static const double diameterFabKasir = 60;

  static const double diameterSubstractKasir = 70;

  static const double diameterDekorSudutNav = 72;

  static const double marginNotchNav = 8;

  static const double _marginAmanFab = 8;



  static double get offsetDekorSudutNav => diameterDekorSudutNav / 2;



  static double bottomLingkaranPutihDariDasarBar() =>

      tinggiKontenBottomBar - (diameterSubstractKasir / 2);



  static double bottomTombolKasirDariDasarBar() =>

      tinggiKontenBottomBar - (diameterFabKasir / 2);



  static double tinggiZonaNav() =>

      tinggiKontenBottomBar + (diameterFabKasir / 2) + _marginAmanFab;



  static double paddingBawahScroll(BuildContext context) {

    final aman = MediaQuery.viewPaddingOf(context).bottom;

    return tinggiZonaNav() + aman + 16;

  }



  static double paddingBawahKonten(

    BuildContext context, {

    required bool diAtasNavUtama,

  }) {

    if (diAtasNavUtama) {

      return paddingBawahScroll(context);

    }

    return MediaQuery.viewPaddingOf(context).bottom + 16;

  }



  static double paddingBawahDiAtasSafeArea() {

    return tinggiZonaNav() + 16;

  }



  static EdgeInsets paddingKontenTab(BuildContext context) {

    return EdgeInsets.fromLTRB(

      16,

      16,

      16,

      16 + paddingBawahDiAtasSafeArea(),

    );

  }



  /// Padding atas/samping tab; padding bawah diserahkan ke scroll (hindari gap kosong).

  static const EdgeInsets paddingKontenTabAtasSamping =

      EdgeInsets.fromLTRB(16, 16, 16, 0);

}

