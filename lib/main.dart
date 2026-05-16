import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/core/pengatur_tema.dart';
import 'package:sarypos/core/pengelola_notifikasi_in_app.dart';
import 'package:sarypos/core/warisan_notifikasi_in_app.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/core/warisan_tema.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';
import 'package:sarypos/features/auth/halaman_pembuka_owner_pertama.dart';
import 'package:sarypos/features/dashboard/halaman_utama_dengan_nav.dart';
import 'package:sarypos/widgets/banner_notifikasi_in_app.dart';
import 'package:sarypos/widgets/halaman_error_koneksi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()]);
  } catch (_) {}

  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  await inisialisasiSupabase();

  final pengaturTema = PengaturTema();
  await pengaturTema.muatAwal();

  runApp(MainApp(pengaturTema: pengaturTema));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.pengaturTema});

  final PengaturTema pengaturTema;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final PengaturSesi _sesi = PengaturSesi();
  late final PengelolaNotifikasiInApp _notifikasiInApp =
      PengelolaNotifikasiInApp();

  @override
  void dispose() {
    _notifikasiInApp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.pengaturTema, _sesi]),
      builder: (context, _) {
        return WarisanTema(
          pengatur: widget.pengaturTema,
          child: WarisanSesi(
            pengatur: _sesi,
            child: WarisanNotifikasiInApp(
              pengelola: _notifikasiInApp,
              child: GetMaterialApp(
                title: 'SaryPOS',
                theme: temaSaryposTerang(),
                darkTheme: temaSaryposGelap(),
                themeMode: widget.pengaturTema.modeMaterial,
                home: _pilihHome(),
                builder: (context, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child ?? const SizedBox.shrink(),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: BannerNotifikasiInApp(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pilihHome() {
    if (_sesi.sedangMemeriksaSesi) {
      return const _SedangMemuatSarypos();
    }
    if (_sesi.sedangMengalamiError) {
      return HalamanErrorKoneksi(
        pesan: _sesi.pesanErrorSesi ?? 'Gagal menyiapkan SaryPOS.',
        cobaLagi: _sesi.muatUlangSesi,
      );
    }
    if (_sesi.perluHalamanPembukaOwner) {
      return HalamanPembukaOwnerPertama(pengatur: _sesi);
    }
    return const HalamanUtamaDenganNav();
  }
}

class _SedangMemuatSarypos extends StatelessWidget {
  const _SedangMemuatSarypos();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Logo Sary Mart',
                    image: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/sarymart_logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.storefront_rounded,
                          size: 64,
                          color: tema.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'SaryPOS',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: warnaAksenJudulBagian(context),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menyiapkan sesi dan data…',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
