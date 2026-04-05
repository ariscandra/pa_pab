import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/features/auth/halaman_daftar_owner.dart';
import 'package:sarypos/features/auth/halaman_login.dart';

class HalamanPembukaOwnerPertama extends StatelessWidget {
  const HalamanPembukaOwnerPertama({super.key, required this.pengatur});

  final PengaturSesi pengatur;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    size: 72,
                    color: warnaAksenJudulBagian(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SaryPOS',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: warnaAksenJudulBagian(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sary Mart',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada pemilik toko terdaftar. Daftarkan pemilik sekali, '
                    'atau lanjut sebagai kasir tanpa akun pemilik (data demo).',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                HalamanDaftarOwner(pengatur: pengatur),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: WarnaSarypos.saryRed,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Daftar pemilik toko'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HalamanLogin(pengatur: pengatur),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: warnaAksenJudulBagian(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Sudah punya akun pemilik? Masuk'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => pengatur.lanjutSebagaiKasirTanpaOwner(),
                    child: const Text('Lanjut sebagai kasir tanpa pemilik'),
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
