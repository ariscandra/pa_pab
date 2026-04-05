import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/features/dashboard/halaman_dashboard.dart';
import 'package:sarypos/features/log_aktivitas/halaman_log_aktivitas.dart';
import 'package:sarypos/features/pengaturan/halaman_user_pengaturan.dart';
import 'package:sarypos/features/pos/halaman_kasir_menu.dart';
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
  static const double _tinggiBottomBar = 32;
  static const double _lebarTitikTengah = 80;
  static const double _diameterKasir = 60;
  static const double _diameterSubstractKasir = 70;
  static const double _offsetSubstractKasir = 14;

  static const _judulTab = ['Beranda', 'Kasir', 'Saya'];

  Color _warnaIkon(bool aktif) =>
      aktif ? WarnaSarypos.saryGold : WarnaSarypos.warmGray;

  @override
  Widget build(BuildContext context) {
    final isKasirAktif = _indeksSaatIni == 1;
    final pemilikBeranda =
        _indeksSaatIni == 0 &&
        (WarisanSesi.dari(context).pengguna?.isOwner ?? false);
    return Scaffold(
      extendBody: true,
      appBar: AppBarSarypos(
        judul: _judulTab[_indeksSaatIni],
        aksi: pemilikBeranda
            ? [
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
              ]
            : null,
      ),
      body: IndexedStack(
        index: _indeksSaatIni,
        children: [
          HalamanDashboard(key: _kunciDashboard),
          const HalamanKasirMenu(),
          const HalamanUserPengaturan(),
        ],
      ),
      floatingActionButton: SizedBox(
        width: _diameterKasir,
        height: _diameterKasir,
        child: _TombolKasirDocked(
          aktif: isKasirAktif,
          diameter: _diameterKasir,
          onTap: () => setState(() => _indeksSaatIni = 1),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: PreferredSize(
        preferredSize: const Size.fromHeight(_tinggiBottomBar),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: WarnaSarypos.deepTeal,
          padding: EdgeInsets.zero,
          child: Stack(
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
                left: -40,
                top: -38,
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
                right: -40,
                bottom: -55,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WarnaSarypos.saryRed.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top:
                    (_tinggiBottomBar / 2) -
                    (_diameterSubstractKasir / 2) -
                    _offsetSubstractKasir,
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
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        setState(() => _indeksSaatIni = 0);
                        _kunciDashboard.currentState?.muatUlangRingkasan();
                      },
                      child: SizedBox.expand(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _indeksSaatIni == 0
                                    ? Icons.home
                                    : Icons.home_outlined,
                                color: _warnaIkon(_indeksSaatIni == 0),
                                size: 20,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Beranda',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: _warnaIkon(_indeksSaatIni == 0),
                                      fontWeight: _indeksSaatIni == 0
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _lebarTitikTengah),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => setState(() => _indeksSaatIni = 2),
                      child: SizedBox.expand(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _indeksSaatIni == 2
                                    ? Icons.person
                                    : Icons.person_outline,
                                color: _warnaIkon(_indeksSaatIni == 2),
                                size: 20,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Saya',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: _warnaIkon(_indeksSaatIni == 2),
                                      fontWeight: _indeksSaatIni == 2
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ],
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
    return MouseRegion(
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
    );
  }
}
