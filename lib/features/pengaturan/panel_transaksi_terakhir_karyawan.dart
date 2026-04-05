import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/core/format_rupiah.dart';
import 'package:sarypos/core/label_metode_pembayaran.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/core/presentasi_log_aktivitas.dart';
import 'package:sarypos/data/models/transaksi_ringkas_model.dart';
import 'package:sarypos/data/sources/laporan_sumber.dart';

class PanelTransaksiTerakhirKaryawan extends StatefulWidget {
  const PanelTransaksiTerakhirKaryawan({super.key, required this.idPengguna});

  final String idPengguna;

  @override
  State<PanelTransaksiTerakhirKaryawan> createState() =>
      _PanelTransaksiTerakhirKaryawanState();
}

class _PanelTransaksiTerakhirKaryawanState
    extends State<PanelTransaksiTerakhirKaryawan> {
  final _laporan = LaporanSumber();
  late Future<List<TransaksiRingkasModel>> _future;
  PengaturSesi? _pengaturSesi;
  int _versiTransaksiTerakhir = 0;

  @override
  void initState() {
    super.initState();
    _future = _laporan.ambilTransaksiTerbaruUntukPengguna(
      idPengguna: widget.idPengguna,
      batas: 8,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sesi = WarisanSesi.dari(context);
    if (_pengaturSesi != sesi) {
      _pengaturSesi?.removeListener(_onTransaksiTerakhirBerubah);
      _pengaturSesi = sesi;
      _versiTransaksiTerakhir = sesi.versiTransaksiTerakhir;
      _pengaturSesi?.addListener(_onTransaksiTerakhirBerubah);
    }
  }

  void _onTransaksiTerakhirBerubah() {
    final sesi = _pengaturSesi;
    if (sesi == null) return;
    final versiBaru = sesi.versiTransaksiTerakhir;
    if (versiBaru == _versiTransaksiTerakhir) return;
    _versiTransaksiTerakhir = versiBaru;
    _muatUlang();
  }

  @override
  void dispose() {
    _pengaturSesi?.removeListener(_onTransaksiTerakhirBerubah);
    super.dispose();
  }

  void _muatUlang() {
    if (!mounted) return;
    setState(() {
      _future = _laporan.ambilTransaksiTerbaruUntukPengguna(
        idPengguna: widget.idPengguna,
        batas: 8,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final teks = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaksi Terakhir',
          style: teks.titleSmall?.copyWith(
            color: warnaAksenJudulBagian(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<TransaksiRingkasModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: warnaAksenJudulBagian(context),
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gagal memuat riwayat transaksi.',
                    style: teks.bodySmall?.copyWith(color: skema.onSurface),
                  ),
                  TextButton(
                    onPressed: _muatUlang,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      foregroundColor: warnaAksenJudulBagian(context),
                    ),
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }
            final daftar = snapshot.data ?? [];
            if (daftar.isEmpty) {
              return Text(
                'Belum ada transaksi tercatat untuk akun Anda.',
                style: teks.bodySmall?.copyWith(color: skema.onSurfaceVariant),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < daftar.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: warnaAksenJudulBagian(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatRupiah(daftar[i].total),
                                style: teks.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: skema.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${labelMetodePembayaran(daftar[i].metodePembayaran)} · ${waktuLogRelatif(daftar[i].waktu)}',
                                style: teks.bodySmall?.copyWith(
                                  color: skema.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
