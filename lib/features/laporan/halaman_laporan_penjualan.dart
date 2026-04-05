import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/ekspor/bagikan_csv.dart';
import 'package:sarypos/core/ekspor/bagikan_pdf.dart' as bagikan_pdf;
import 'package:sarypos/core/ekspor/penulis_csv_laporan.dart';
import 'package:sarypos/core/ekspor/penulis_pdf_laporan.dart';
import 'package:sarypos/core/format_rupiah.dart';
import 'package:sarypos/core/label_metode_pembayaran.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/data/sources/laporan_sumber.dart';
import 'package:sarypos/widgets/card_ringkasan.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanLaporanPenjualan extends StatefulWidget {
  const HalamanLaporanPenjualan({super.key});

  @override
  State<HalamanLaporanPenjualan> createState() =>
      _HalamanLaporanPenjualanState();
}

class _HalamanLaporanPenjualanState extends State<HalamanLaporanPenjualan> {
  final _sumber = LaporanSumber();
  RentangLaporan _rentang = RentangLaporan.hariIni;
  late Future<RingkasanLaporanPenjualan> _future;
  bool _sedangEkspor = false;

  @override
  void initState() {
    super.initState();
    _future = _sumber.ambilRingkasanPenjualan(_rentang);
  }

  void _gantiRentang(RentangLaporan? r) {
    if (r == null) {
      return;
    }
    setState(() {
      _rentang = r;
      _future = _sumber.ambilRingkasanPenjualan(r);
    });
  }

  Future<void> _tampilkanDialogEkspor() async {
    final label = labelRentangLaporan(_rentang);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ekspor Laporan'),
          content: Text(
            'Data yang diekspor mengikuti periode: $label.\n\n'
            'PDF cocok untuk cetak; CSV untuk Excel atau Google Sheets.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _eksporPdf();
              },
              child: const Text('PDF'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _eksporCsv();
              },
              child: const Text('CSV'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eksporPdf({RingkasanLaporanPenjualan? data}) async {
    setState(() => _sedangEkspor = true);
    final idPemilik = WarisanSesi.dari(context).pengguna?.id;
    try {
      final d = data ?? await _sumber.ambilRingkasanPenjualan(_rentang);
      final bytes = await buatBytesLaporanPdf(data: d, rentang: _rentang);
      if (!mounted) {
        return;
      }
      final label = labelRentangLaporan(_rentang);
      final namaFile =
          'laporan_sarypos_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final subjek = 'Laporan SaryPOS — $label';

      if (kIsWeb) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Laporan PDF Siap'),
            content: const Text(
              'Di browser, unduhan sering diblokir kecuali Anda menekan tombol di sini. '
              'Jika file tidak muncul, izinkan unduhan pop-up untuk situs ini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: namaFile,
                    subject: subjek,
                  );
                },
                child: const Text('Unduh PDF'),
              ),
            ],
          ),
        );
      } else {
        await bagikan_pdf.bagikanFilePdf(
          bytes: bytes,
          namaFile: namaFile,
          subject: subjek,
        );
      }

      if (!mounted) {
        return;
      }
      catatLogAktivitas(
        idPengguna: idPemilik,
        jenis: JenisLogAktivitas.eksporPdf,
        deskripsi: 'Ekspor PDF laporan · $label',
      );
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'PDF berhasil disiapkan.',
      );
    } catch (_) {
      if (mounted) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Gagal mengekspor PDF.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sedangEkspor = false);
      }
    }
  }

  Future<void> _eksporCsv() async {
    setState(() => _sedangEkspor = true);
    final idPemilik = WarisanSesi.dari(context).pengguna?.id;
    try {
      final d = await _sumber.ambilRingkasanPenjualan(_rentang);
      final label = labelRentangLaporan(_rentang);
      final csv = buatCsvRingkasanPenjualan(data: d, rentang: _rentang);
      final namaFile =
          'laporan_sarypos_${DateTime.now().millisecondsSinceEpoch}.csv';

      if (!mounted) {
        return;
      }

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: csv));
        catatLogAktivitas(
          idPengguna: idPemilik,
          jenis: JenisLogAktivitas.eksporCsv,
          deskripsi: 'Ekspor CSV (disalin) · $label',
        );
        if (!mounted) {
          return;
        }
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.info,
          pesan:
              'CSV disalin ke papan klip. Tempel di Excel atau Google Sheets.',
        );
      } else {
        await bagikanStringCsv(
          isiCsv: csv,
          namaFile: namaFile,
          subjek: 'Laporan SaryPOS — $label',
        );
        catatLogAktivitas(
          idPengguna: idPemilik,
          jenis: JenisLogAktivitas.eksporCsv,
          deskripsi: 'Ekspor CSV · $label',
        );
        if (!mounted) {
          return;
        }
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.sukses,
          pesan: 'Berkas CSV siap dibagikan.',
        );
      }
    } catch (_) {
      if (mounted) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Gagal mengekspor CSV.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sedangEkspor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fTanggal = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBarSarypos(
        judul: 'Laporan Penjualan',
        aksi: [
          IconButton(
            tooltip: 'Ekspor Laporan',
            icon: _sedangEkspor
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_outlined),
            onPressed: _sedangEkspor ? null : _tampilkanDialogEkspor,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DropdownButtonFormField<RentangLaporan>(
                // ignore: deprecated_member_use
                value: _rentang,
                decoration: const InputDecoration(
                  labelText: 'Periode',
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
                items: RentangLaporan.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(labelRentangLaporan(r)),
                      ),
                    )
                    .toList(),
                onChanged: _gantiRentang,
              ),
            ),
            Expanded(
              child: FutureBuilder<RingkasanLaporanPenjualan>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return EmptyStateGenerik(
                      ikon: Icons.error_outline,
                      judul: 'Gagal Memuat Laporan',
                      pesan: 'Tarik ke bawah atau ubah periode lalu coba lagi.',
                      labelTombol: 'Muat ulang',
                      onTekanTombol: () {
                        setState(() {
                          _future = _sumber.ambilRingkasanPenjualan(_rentang);
                        });
                      },
                    );
                  }

                  final data = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: () async {
                      final f = _sumber.ambilRingkasanPenjualan(_rentang);
                      setState(() => _future = f);
                      await f;
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CardRingkasan(
                                  judul: 'Jumlah Transaksi',
                                  nilaiUtama: '${data.jumlahTransaksi}',
                                  ikon: Icons.receipt_long,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CardRingkasan(
                                  judul: 'Total Penjualan',
                                  nilaiUtama: formatRupiah(
                                    data.totalNilaiPenjualan,
                                  ),
                                  ikon: Icons.payments_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _sedangEkspor
                              ? null
                              : _tampilkanDialogEkspor,
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Ekspor Laporan (PDF atau CSV)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: warnaAksenJudulBagian(context),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Transaksi Terbaru',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (data.transaksiRingkas.isEmpty)
                          const EmptyStateGenerik(
                            ikon: Icons.inventory_2_outlined,
                            pesan: 'Belum ada transaksi pada periode ini.',
                          )
                        else
                          ...data.transaksiRingkas.map(
                            (t) => CardSarypos(
                              child: ListTile(
                                isThreeLine: t.potongan > 0,
                                title: Text(
                                  formatRupiah(t.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: WarnaSarypos.saryRed,
                                  ),
                                ),
                                subtitle: Text(
                                  '${fTanggal.format(t.waktu.toLocal())} · '
                                  '${labelMetodePembayaran(t.metodePembayaran)} · '
                                  'Dicatat: ${t.namaPencatat}'
                                  '${t.potongan > 0 ? '\nSubtotal ${formatRupiah(t.subtotal)} · Potongan ${formatRupiah(t.potongan)}' : ''}',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
