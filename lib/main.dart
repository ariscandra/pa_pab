import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menyiapkan SaryPOS…'),
            ],
          ),
        ),
      );
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
