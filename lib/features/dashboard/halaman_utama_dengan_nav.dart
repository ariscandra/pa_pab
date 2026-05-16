import 'package:flutter/material.dart';
import 'package:sarypos/config/inset_nav_utama.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/features/dashboard/halaman_dashboard.dart';
import 'package:sarypos/features/log_aktivitas/halaman_log_aktivitas.dart';
import 'package:sarypos/features/pengaturan/halaman_user_pengaturan.dart';
import 'package:sarypos/features/pos/halaman_kasir_tab.dart';
import 'package:sarypos/core/penjaga_rute_owner.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';

class HalamanUtamaDenganNav extends StatefulWidget {
  const HalamanUtamaDenganNav({super.key});

  @override
  State<HalamanUtamaDenganNav> createState() => _HalamanUtamaDenganNavState();
}

class _HalamanUtamaDenganNavState extends State<HalamanUtamaDenganNav> {
  int _indeksSaatIni = 0;
  final _kunciDashboard = GlobalKey<HalamanDashboardState>();
  static const double _tinggiBottomBar = InsetNavUtama.tinggiKontenBottomBar;
  static const double _lebarTitikTengah = InsetNavUtama.lebarTitikTengahNav;
  static const double _diameterKasir = InsetNavUtama.diameterFabKasir;
  static const double _diameterSubstractKasir = InsetNavUtama.diameterSubstractKasir;
  static double get _tinggiZonaNav => InsetNavUtama.tinggiZonaNav();

  static const _judulTab = ['Beranda', 'Kasir', 'Saya'];

  Color _warnaIkon(bool aktif) =>
      aktif ? WarnaSarypos.saryGold : WarnaSarypos.warmGray;

  @override
  Widget build(BuildContext context) {
    final isKasirAktif = _indeksSaatIni == 1;
    final pemilikBeranda =
        _indeksSaatIni == 0 &&
        (WarisanSesi.dari(context).pengguna?.isOwner ?? false);
    final tabKasir = _indeksSaatIni == 1;
    final sudahMasuk = WarisanSesi.dari(context).pengguna != null;
    final aksiAppBar = <Widget>[
      if (pemilikBeranda)
        IconButton(
          onPressed: () async {
            await dorongJikaOwner(
              context,
              (_) => const HalamanLogAktivitas(),
            );
          },
          icon: const Icon(Icons.notifications_none_outlined),
          tooltip: 'Log Aktivitas',
        ),
      if (tabKasir && sudahMasuk)
        IconButton(
          onPressed: () => bukaManajemenProdukDariKasir(context),
          icon: const Icon(Icons.inventory_2_outlined),
          tooltip: 'Manajemen produk',
        ),
    ];
    return Scaffold(
      extendBody: true,
      appBar: AppBarSarypos(
        judul: _judulTab[_indeksSaatIni],
        aksi: aksiAppBar.isEmpty ? null : aksiAppBar,
      ),
      body: IndexedStack(
        index: _indeksSaatIni,
        children: [
          HalamanDashboard(key: _kunciDashboard),
          HalamanKasirTab(
            onMintaTabSaya: () => setState(() => _indeksSaatIni = 2),
          ),
          const HalamanUserPengaturan(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: _tinggiZonaNav,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomAppBar(
                  height: _tinggiBottomBar,
                  shape: const CircularNotchedRectangle(),
                  notchMargin: InsetNavUtama.marginNotchNav,
                  color: WarnaSarypos.deepTeal,
                  padding: EdgeInsets.zero,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    fit: StackFit.expand,
                    children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              WarnaSarypos.deepTeal,
                              WarnaSarypos.deepTeal.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -InsetNavUtama.offsetDekorSudutNav,
                      top: -InsetNavUtama.offsetDekorSudutNav,
                      child: Container(
                        width: InsetNavUtama.diameterDekorSudutNav,
                        height: InsetNavUtama.diameterDekorSudutNav,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarnaSarypos.saryGold.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -InsetNavUtama.offsetDekorSudutNav,
                      bottom: -InsetNavUtama.offsetDekorSudutNav,
                      child: Container(
                        width: InsetNavUtama.diameterDekorSudutNav,
                        height: InsetNavUtama.diameterDekorSudutNav,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarnaSarypos.saryRed.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                          label: 'Tab Beranda',
                          selected: _indeksSaatIni == 0,
                          button: true,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              splashColor: WarnaSarypos.saryGold.withValues(
                                alpha: 0.12,
                              ),
                              highlightColor: WarnaSarypos.saryGold.withValues(
                                alpha: 0.06,
                              ),
                              onTap: () {
                                setState(() => _indeksSaatIni = 0);
                                _kunciDashboard.currentState
                                    ?.muatUlangRingkasan();
                              },
                              child: SizedBox.expand(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _indeksSaatIni == 0
                                            ? Icons.home_rounded
                                            : Icons.home_outlined,
                                        color: _warnaIkon(_indeksSaatIni == 0),
                                        size: 22,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Beranda',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: 12,
                                              height: 1.15,
                                              color: _warnaIkon(
                                                _indeksSaatIni == 0,
                                              ),
                                              fontWeight: _indeksSaatIni == 0
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: _lebarTitikTengah),
                      Expanded(
                        child: Semantics(
                          label: 'Tab Saya',
                          selected: _indeksSaatIni == 2,
                          button: true,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              splashColor: WarnaSarypos.saryGold.withValues(
                                alpha: 0.12,
                              ),
                              highlightColor: WarnaSarypos.saryGold.withValues(
                                alpha: 0.06,
                              ),
                              onTap: () =>
                                  setState(() => _indeksSaatIni = 2),
                              child: SizedBox.expand(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _indeksSaatIni == 2
                                            ? Icons.person_rounded
                                            : Icons.person_outline,
                                        color: _warnaIkon(_indeksSaatIni == 2),
                                        size: 22,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Saya',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: 12,
                                              height: 1.15,
                                              color: _warnaIkon(
                                                _indeksSaatIni == 2,
                                              ),
                                              fontWeight: _indeksSaatIni == 2
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: InsetNavUtama.bottomLingkaranPutihDariDasarBar(),
                child: Center(
                  child: Container(
                    width: _diameterSubstractKasir,
                    height: _diameterSubstractKasir,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: InsetNavUtama.bottomTombolKasirDariDasarBar(),
                child: Center(
                  child: SizedBox(
                    width: _diameterKasir,
                    height: _diameterKasir,
                    child: Tooltip(
                      message: 'Buka Kasir (POS)',
                      child: _TombolKasirDocked(
                        aktif: isKasirAktif,
                        diameter: _diameterKasir,
                        onTap: () => setState(() => _indeksSaatIni = 1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TombolKasirDocked extends StatefulWidget {
  const _TombolKasirDocked({
    required this.aktif,
    required this.diameter,
    required this.onTap,
  });

  final bool aktif;
  final double diameter;
  final VoidCallback onTap;

  @override
  State<_TombolKasirDocked> createState() => _TombolKasirDockedState();
}

class _TombolKasirDockedState extends State<_TombolKasirDocked> {
  bool _sedangDitekan = false;

  @override
  Widget build(BuildContext context) {
    final warnaBorder = WarnaSarypos.saryGold.withValues(
      alpha: widget.aktif ? 0.75 : 0.45,
    );
    return Semantics(
      label: 'Kasir, POS',
      button: true,
      selected: widget.aktif,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
        onTapDown: (_) => setState(() => _sedangDitekan = true),
        onTapUp: (_) => setState(() => _sedangDitekan = false),
        onTapCancel: () => setState(() => _sedangDitekan = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scaleByDouble(
              _sedangDitekan ? 0.98 : 1.0,
              _sedangDitekan ? 0.98 : 1.0,
              _sedangDitekan ? 0.98 : 1.0,
              1.0,
            ),
          width: widget.diameter,
          height: widget.diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WarnaSarypos.saryRed, WarnaSarypos.saryGold],
            ),
            border: Border.all(
              color: warnaBorder,
              width: widget.aktif ? 1.5 : 1,
            ),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      ),
    );
  }
}
