import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/widgets/card_sarypos.dart';

class HalamanTentangSarypos extends StatefulWidget {
  const HalamanTentangSarypos({super.key});

  @override
  State<HalamanTentangSarypos> createState() => _HalamanTentangSaryposState();
}

class _HalamanTentangSaryposState extends State<HalamanTentangSarypos> {
  static const _fotoKelompok = 'assets/images/radar_pramuka.jpg';
  static const _logoAplikasi = 'assets/images/sarymart_logo.png';

  static const _carouselItem = [
    (judul: 'Logo Sary Mart', pathGambar: _logoAplikasi, mode: BoxFit.fitWidth),
    (judul: 'RADAR PRAMUKA', pathGambar: _fotoKelompok, mode: BoxFit.cover),
  ];

  final PageController _pengendaliCarousel = PageController();
  int _indeksAktif = 0;

  @override
  void dispose() {
    _pengendaliCarousel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gelap = tema.brightness == Brightness.dark;
    final warnaBingkai = gelap
        ? tema.colorScheme.outline.withValues(alpha: 0.45)
        : WarnaSarypos.warmGray.withValues(alpha: 0.7);

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang SaryPOS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 14),
            CardSarypos(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: gelap
                              ? tema.colorScheme.surfaceContainerHigh
                              : WarnaSarypos.cleanWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: warnaBingkai),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                                PointerDeviceKind.stylus,
                              },
                            ),
                            child: PageView.builder(
                              controller: _pengendaliCarousel,
                              itemCount: _carouselItem.length,
                              onPageChanged: (nilai) {
                                setState(() => _indeksAktif = nilai);
                              },
                              itemBuilder: (context, indeks) {
                                final item = _carouselItem[indeks];
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      item.pathGambar,
                                      fit: item.mode,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color: tema
                                                .colorScheme
                                                .surfaceContainerHigh,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 42,
                                            ),
                                          ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            tema.colorScheme.scrim.withValues(
                                              alpha: 0.55,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          item.judul,
                                          style: tema.textTheme.titleSmall
                                              ?.copyWith(
                                                color:
                                                    tema.colorScheme.onPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _carouselItem.length,
                        (indeks) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _indeksAktif == indeks ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _indeksAktif == indeks
                                ? WarnaSarypos.saryGold
                                : WarnaSarypos.warmGray.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CardSarypos(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'SaryPOS adalah aplikasi POS dan manajemen inventori yang '
                  'dikembangkan oleh kelompok RADAR PRAMUKA untuk membantu '
                  'kinerja karyawan serta pemilik Sary Mart di Jalan MT Haryono, '
                  'Samarinda. Aplikasi ini dikembangkan sebagai Proyek Akhir '
                  'mata kuliah Pemrograman Aplikasi Bergerak.',
                  style: tema.textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
