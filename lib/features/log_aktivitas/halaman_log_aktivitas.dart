import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/presentasi_log_aktivitas.dart';
import 'package:sarypos/data/models/log_aktivitas_model.dart';
import 'package:sarypos/data/sources/log_aktivitas_sumber.dart';
import 'package:sarypos/core/warisan_tema.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';

class HalamanLogAktivitas extends StatefulWidget {
  const HalamanLogAktivitas({super.key});

  @override
  State<HalamanLogAktivitas> createState() => _HalamanLogAktivitasState();
}

class _HalamanLogAktivitasState extends State<HalamanLogAktivitas> {
  final _sumber = LogAktivitasSumber();
  late Future<List<LogAktivitasModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _sumber.ambilTerbaru(batas: 100);
  }

  @override
  Widget build(BuildContext context) {
    WarisanTema.dari(context);
    final skema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const AppBarSarypos(judul: 'Log Aktivitas'),
      body: SafeArea(
        child: FutureBuilder<List<LogAktivitasModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return EmptyStateGenerik(
                ikon: Icons.cloud_off_outlined,
                judul: 'Tidak Dapat Memuat Log',
                pesan:
                    'Periksa koneksi dan pastikan tabel log_aktivitas ada di Supabase.',
                labelTombol: 'Coba lagi',
                onTekanTombol: () {
                  setState(() {
                    _future = _sumber.ambilTerbaru(batas: 100);
                  });
                },
              );
            }

            final daftar = snapshot.data ?? [];
            if (daftar.isEmpty) {
              return const EmptyStateGenerik(
                ikon: Icons.history,
                judul: 'Belum Ada Catatan',
                pesan:
                    'Log akan muncul setelah ada transaksi, perubahan stok, atau aktivitas lain.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final f = _sumber.ambilTerbaru(batas: 100);
                setState(() => _future = f);
                await f;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: daftar.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: skema.outlineVariant.withValues(alpha: 0.75),
                ),
                itemBuilder: (context, i) {
                  final log = daftar[i];
                  final warnaAksen = warnaAksenJudulBagian(context);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: warnaAksen.withValues(alpha: 0.18),
                      foregroundColor: warnaAksen,
                      child: Icon(ikonLogAktivitas(log.jenis), size: 22),
                    ),
                    title: Text(
                      judulRingkasLog(log.jenis),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${log.deskripsi}\n${waktuLogRelatif(log.waktu)}',
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
