import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';

class HalamanErrorKoneksi extends StatelessWidget {
  const HalamanErrorKoneksi({
    super.key,
    required this.pesan,
    required this.cobaLagi,
  });

  final String pesan;
  final Future<void> Function() cobaLagi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final teks = tema.textTheme;

    return Scaffold(
      appBar: const AppBarSarypos(judul: 'Koneksi Bermasalah'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    size: 50,
                    color: WarnaSarypos.saryRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak bisa menyiapkan SaryPOS.',
                    style: teks.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pesan,
                    style: teks.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async => cobaLagi(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarnaSarypos.saryRed,
                        foregroundColor: tema.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tip: jika memungkinkan, hidupkan internet lalu coba ulang.',
                    style: teks.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
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
