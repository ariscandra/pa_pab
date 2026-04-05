import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/format_rupiah.dart';
import 'package:sarypos/core/logika_preview_produk_perhatian.dart';
import 'package:sarypos/core/penjaga_aksi_masuk.dart';
import 'package:sarypos/core/penjaga_rute_owner.dart';
import 'package:sarypos/core/presentasi_log_aktivitas.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/data/models/log_aktivitas_model.dart';
import 'package:sarypos/data/models/produk_inventaris_model.dart';
import 'package:sarypos/data/sources/dashboard_sumber.dart';
import 'package:sarypos/data/sources/log_aktivitas_sumber.dart';
import 'package:sarypos/data/sources/produk_dan_stok_sumber.dart';
import 'package:sarypos/features/laporan/halaman_laporan_penjualan.dart';
import 'package:sarypos/features/log_aktivitas/halaman_log_aktivitas.dart';
import 'package:sarypos/features/produk/halaman_daftar_produk.dart';
import 'package:sarypos/features/produk/halaman_form_produk.dart';
import 'package:sarypos/widgets/card_ringkasan.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';

Color _warnaKanvasBeranda(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    final skema = Theme.of(context).colorScheme;
    return Color.alphaBlend(
      WarnaSarypos.deepTeal.withValues(alpha: 0.14),
      skema.surface,
    );
  }
  return Color.alphaBlend(
    WarnaSarypos.warmGray.withValues(alpha: 0.16),
    WarnaSarypos.cleanWhite,
  );
}

class HalamanDashboard extends StatefulWidget {
  const HalamanDashboard({super.key});

  @override
  HalamanDashboardState createState() => HalamanDashboardState();
}

class HalamanDashboardState extends State<HalamanDashboard> {
  final _sumber = DashboardSumber();
  final _sumberLog = LogAktivitasSumber();
  final _sumberProduk = ProdukDanStokSumber();
  late Future<RingkasanDashboardHariIni> _futureRingkasan;
  late Future<List<LogAktivitasModel>> _futureAktivitasTerbaru;
  late Future<List<ProdukInventarisModel>> _futureProdukPerhatian;
  String? _kunciSesiBeranda;

  final _kunciCarousel = PageController(viewportFraction: 1.0);
  int _indeksRingkasan = 0;

  static const _prefPrefixTutupModeKaryawan =
      'sarypos_beranda_mode_karyawan_ditutup_';
  bool _permintaanMuatPrefBannerModeKaryawan = false;
  bool _prefBannerModeKaryawanSiap = false;
  bool _bannerModeKaryawanDitutup = false;

  Widget _buildIndikatorDot(int indeksAktif) {
    const jumlah = 2;
    return IgnorePointer(
      ignoring: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(jumlah, (i) {
          final aktif = i == indeksAktif;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: aktif ? 10 : 8,
            height: aktif ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aktif
                  ? WarnaSarypos.saryRed.withValues(alpha: 0.70)
                  : WarnaSarypos.warmGray.withValues(alpha: 0.30),
            ),
          );
        }),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _futureRingkasan = _sumber.ambilRingkasanHariIni();
    _kunciCarousel.addListener(_sinkronkanIndeksRingkasan);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_permintaanMuatPrefBannerModeKaryawan) {
      _permintaanMuatPrefBannerModeKaryawan = true;
      _muatPreferensiBannerModeKaryawan();
    }
    final sesi = WarisanSesi.dari(context).pengguna;
    final pemilik = sesi?.isOwner ?? false;
    final kunci = '${sesi?.id ?? 'anon'}_${pemilik ? 'o' : 'x'}';
    if (_kunciSesiBeranda == kunci) return;
    _kunciSesiBeranda = kunci;
    _futureAktivitasTerbaru = pemilik
        ? _sumberLog.ambilTerbaruUntukBeranda(
            untukPemilik: true,
            batas: 3,
          )
        : Future.value(const []);
    _futureProdukPerhatian = _sumberProduk.ambilPreviewProdukPerluPerhatian(
      maks: 4,
    );
  }

  Future<void> _muatPreferensiBannerModeKaryawan() async {
    final id = WarisanSesi.dari(context).pengguna?.id;
    final p = await SharedPreferences.getInstance();
    final ditutup =
        p.getBool('$_prefPrefixTutupModeKaryawan${id ?? 'tanpa_id'}') ?? false;
    if (!mounted) return;
    setState(() {
      _bannerModeKaryawanDitutup = ditutup;
      _prefBannerModeKaryawanSiap = true;
    });
  }

  Future<void> _tutupBannerModeKaryawan() async {
    final id = WarisanSesi.dari(context).pengguna?.id;
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_prefPrefixTutupModeKaryawan${id ?? 'tanpa_id'}', true);
    if (!mounted) return;
    setState(() => _bannerModeKaryawanDitutup = true);
  }

  @override
  void dispose() {
    _kunciCarousel.removeListener(_sinkronkanIndeksRingkasan);
    _kunciCarousel.dispose();
    super.dispose();
  }

  void _sinkronkanIndeksRingkasan() {
    final p = _kunciCarousel.page;
    if (p == null) return;
    final i = p.round().clamp(0, 1);
    if (!mounted || i == _indeksRingkasan) return;
    setState(() => _indeksRingkasan = i);
  }

  void muatUlangRingkasan() {
    if (!mounted) return;
    final sesi = WarisanSesi.dari(context).pengguna;
    final pemilik = sesi?.isOwner ?? false;
    setState(() {
      _futureRingkasan = _sumber.ambilRingkasanHariIni();
      _futureAktivitasTerbaru = pemilik
          ? _sumberLog.ambilTerbaruUntukBeranda(
              untukPemilik: true,
              batas: 3,
            )
          : Future.value(const []);
      _futureProdukPerhatian = _sumberProduk.ambilPreviewProdukPerluPerhatian(
        maks: 4,
      );
    });
  }

  void _muatUlangHanyaAktivitasTerbaru() {
    if (!mounted) return;
    final pemilik = WarisanSesi.dari(context).pengguna?.isOwner ?? false;
    if (!pemilik) return;
    setState(() {
      _futureAktivitasTerbaru = _sumberLog.ambilTerbaruUntukBeranda(
        untukPemilik: true,
        batas: 3,
      );
    });
  }

  void _muatUlangHanyaProdukPerhatian() {
    setState(() {
      _futureProdukPerhatian = _sumberProduk.ambilPreviewProdukPerluPerhatian(
        maks: 4,
      );
    });
  }

  Widget _stackCardJumlahTransaksi(int jumlahTransaksi) {
    return Stack(
      children: [
        CardRingkasan(
          margin: EdgeInsets.zero,
          judul: 'Jumlah Transaksi',
          nilaiUtama: '$jumlahTransaksi',
          ikon: Icons.receipt_long,
        ),
        Positioned(
          top: 18,
          right: 18,
          child: _buildIndikatorDot(_indeksRingkasan),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      left: false,
      right: false,
      child: FutureBuilder<RingkasanDashboardHariIni>(
        future: _futureRingkasan,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final sedangMemuat =
              snapshot.connectionState == ConnectionState.waiting;
          final adaError = snapshot.hasError;

          final totalPenjualan = data?.totalPenjualan ?? 0;
          final jumlahTransaksi = data?.jumlahTransaksi ?? 0;
          final isOwner = WarisanSesi.dari(context).pengguna?.isOwner ?? false;
          final kanvas = _warnaKanvasBeranda(context);
          final inset = MediaQuery.paddingOf(context);

          return LayoutBuilder(
            builder: (context, kotak) {
              return ColoredBox(
                color: kanvas,
                child: RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  onRefresh: () async {
                    final pemilik =
                        WarisanSesi.dari(context).pengguna?.isOwner ?? false;
                    final f1 = _sumber.ambilRingkasanHariIni();
                    final f2 = pemilik
                        ? _sumberLog.ambilTerbaruUntukBeranda(
                            untukPemilik: true,
                            batas: 3,
                          )
                        : Future.value(const <LogAktivitasModel>[]);
                    final f3 = _sumberProduk.ambilPreviewProdukPerluPerhatian(
                      maks: 4,
                    );
                    setState(() {
                      _futureRingkasan = f1;
                      _futureAktivitasTerbaru = f2;
                      _futureProdukPerhatian = f3;
                    });
                    await f1;
                    await f2;
                    await f3;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: kotak.maxHeight),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: kanvas),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_prefBannerModeKaryawanSiap &&
                                  !(WarisanSesi.dari(
                                        context,
                                      ).pengguna?.isOwner ??
                                      false) &&
                                  !_bannerModeKaryawanDitutup)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    16 + inset.left,
                                    12,
                                    16 + inset.right,
                                    10,
                                  ),
                                  child: Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh
                                        .withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        6,
                                        2,
                                        6,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Icon(
                                              Icons.storefront_outlined,
                                              size: 20,
                                              color: warnaAksenJudulBagian(
                                                context,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Mode Karyawan',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'POS dan ringkasan tersedia. Laporan lengkap hanya untuk pemilik di tab Saya.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        height: 1.25,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 20,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            tooltip: 'Sembunyikan',
                                            onPressed: _tutupBannerModeKaryawan,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16 + inset.left,
                                  16,
                                  16 + inset.right,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (adaError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          'Gagal memuat ringkasan. Tarik ke bawah untuk coba lagi.',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    if (!adaError) ...[
                                      Text(
                                        'RINGKASAN',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.9,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 140,
                                        child: PageView(
                                          controller: _kunciCarousel,
                                          scrollDirection: Axis.horizontal,
                                          physics: sedangMemuat
                                              ? const NeverScrollableScrollPhysics()
                                              : null,
                                          onPageChanged: sedangMemuat
                                              ? null
                                              : (i) => setState(() {
                                                  _indeksRingkasan = i;
                                                }),
                                          padEnds: false,
                                          children: sedangMemuat
                                              ? List.generate(
                                                  2,
                                                  (i) => Stack(
                                                    children: [
                                                      const _CardRingkasanSkeleton(),
                                                      Positioned(
                                                        top: 18,
                                                        right: 18,
                                                        child:
                                                            _buildIndikatorDot(
                                                              _indeksRingkasan,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : [
                                                  GestureDetector(
                                                    onTap: () {
                                                      dorongJikaOwner(
                                                        context,
                                                        (_) =>
                                                            const HalamanLaporanPenjualan(),
                                                        pesanDitolak:
                                                            'Hanya pemilik yang membuka laporan lengkap.',
                                                      );
                                                    },
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    child: Stack(
                                                      children: [
                                                        CardRingkasan(
                                                          margin:
                                                              EdgeInsets.zero,
                                                          judul:
                                                              'Penjualan Hari Ini',
                                                          nilaiUtama:
                                                              formatRupiah(
                                                                totalPenjualan,
                                                              ),
                                                          ikon: Icons
                                                              .attach_money,
                                                        ),
                                                        Positioned(
                                                          top: 18,
                                                          right: 18,
                                                          child:
                                                              _buildIndikatorDot(
                                                                _indeksRingkasan,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  isOwner
                                                      ? GestureDetector(
                                                          onTap: () {
                                                            dorongJikaOwner(
                                                              context,
                                                              (_) =>
                                                                  const HalamanLaporanPenjualan(),
                                                              pesanDitolak:
                                                                  'Hanya pemilik yang membuka laporan lengkap.',
                                                            );
                                                          },
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          child:
                                                              _stackCardJumlahTransaksi(
                                                                jumlahTransaksi,
                                                              ),
                                                        )
                                                      : _stackCardJumlahTransaksi(
                                                          jumlahTransaksi,
                                                        ),
                                                ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: adaError ? 10 : 14),
                                    _PanelSectionBeranda(
                                      judul: 'Produk Perlu Perhatian',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Wrap(
                                            spacing: 2,
                                            runSpacing: 0,
                                            children: [
                                              _TombolKapsulOutline(
                                                onPressed: () {
                                                  if (cegahJikaBelumLogin(
                                                    context,
                                                    pesan:
                                                        'Masuk ke akun terlebih dahulu untuk membuka daftar produk.',
                                                  )) {
                                                    return;
                                                  }
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          const HalamanDaftarProduk(
                                                            filterAwal:
                                                                FilterProdukManajemen
                                                                    .stokMenipis,
                                                            urutAwal:
                                                                UrutProdukManajemen
                                                                    .stokTerendah,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                label: 'Stok Menipis',
                                              ),
                                              _TombolKapsulOutline(
                                                onPressed: () {
                                                  if (cegahJikaBelumLogin(
                                                    context,
                                                    pesan:
                                                        'Masuk ke akun terlebih dahulu untuk membuka daftar produk.',
                                                  )) {
                                                    return;
                                                  }
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) => const HalamanDaftarProduk(
                                                        filterAwal:
                                                            FilterProdukManajemen
                                                                .mendekatiKadaluarsa,
                                                        urutAwal:
                                                            UrutProdukManajemen
                                                                .kadaluarsaTerdekat,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                label: 'Mendekati Kadaluarsa',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          FutureBuilder<
                                            List<ProdukInventarisModel>
                                          >(
                                            future: _futureProdukPerhatian,
                                            builder: (context, snapProduk) {
                                              if (snapProduk.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const _DaftarProdukPerhatianSkeleton();
                                              }
                                              if (snapProduk.hasError) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Gagal memuat preview produk.',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'Tarik layar untuk memuat ulang atau buka daftar produk.',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          _muatUlangHanyaProdukPerhatian,
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        foregroundColor:
                                                            warnaAksenJudulBagian(
                                                              context,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'Coba lagi',
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }
                                              final daftar =
                                                  snapProduk.data ?? [];
                                              if (daftar.isEmpty) {
                                                return _KosongPanelBeranda(
                                                  ikon: Icons
                                                      .inventory_2_outlined,
                                                  pesan:
                                                      'Tidak ada produk yang perlu perhatian.',
                                                );
                                              }
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  for (
                                                    var i = 0;
                                                    i < daftar.length;
                                                    i++
                                                  ) ...[
                                                    if (i > 0)
                                                      Divider(
                                                        height: 1,
                                                        thickness: 1,
                                                        color: Theme.of(context)
                                                            .dividerColor
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                    _BarisProdukPerhatianBeranda(
                                                      item: daftar[i],
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(height: 14),
                                      _PanelSectionBeranda(
                                        judul: 'Aktivitas Terbaru',
                                        trailingHeader: _TombolKapsulOutline(
                                          onPressed: () {
                                            dorongJikaOwner(
                                              context,
                                              (_) =>
                                                  const HalamanLogAktivitas(),
                                              pesanDitolak:
                                                  'Log lengkap hanya untuk pemilik toko.',
                                            );
                                          },
                                          label: 'Lihat Semua',
                                        ),
                                        child: FutureBuilder<
                                            List<LogAktivitasModel>>(
                                          future: _futureAktivitasTerbaru,
                                          builder: (context, snapAktivitas) {
                                            if (snapAktivitas.connectionState ==
                                                ConnectionState.waiting) {
                                              return const _DaftarAktivitasSkeleton();
                                            }
                                            if (snapAktivitas.hasError) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Gagal memuat aktivitas terbaru.',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Periksa koneksi atau izin akun. Tarik layar untuk memuat ulang.',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        _muatUlangHanyaAktivitasTerbaru,
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      foregroundColor:
                                                          warnaAksenJudulBagian(
                                                            context,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Coba lagi',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                            final daftar =
                                                snapAktivitas.data ?? [];
                                            if (daftar.isEmpty) {
                                              return const _KosongPanelBeranda(
                                                ikon: Icons.history,
                                                pesan:
                                                    'Belum ada aktivitas di feed ini.',
                                              );
                                            }
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                for (
                                                  var i = 0;
                                                  i < daftar.length;
                                                  i++
                                                ) ...[
                                                  if (i > 0)
                                                    Divider(
                                                      height: 1,
                                                      thickness: 1,
                                                      color: Theme.of(context)
                                                          .dividerColor
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    ),
                                                  _BarisAktivitasBeranda(
                                                    log: daftar[i],
                                                  ),
                                                ],
                                                const _IndikatorAktivitasAdaLagi(),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PanelSectionBeranda extends StatelessWidget {
  const _PanelSectionBeranda({
    required this.judul,
    this.trailingHeader,
    required this.child,
  });

  final String judul;
  final Widget? trailingHeader;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return CardSarypos(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: WarnaSarypos.saryRed.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    judul,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: skema.onSurface,
                    ),
                  ),
                ),
                ?trailingHeader,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _KosongPanelBeranda extends StatelessWidget {
  const _KosongPanelBeranda({required this.ikon, required this.pesan});

  final IconData ikon;
  final String pesan;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ikon,
            size: 26,
            color: skema.onSurfaceVariant.withValues(alpha: 0.42),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pesan,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: skema.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardRingkasanSkeleton extends StatelessWidget {
  const _CardRingkasanSkeleton();

  @override
  Widget build(BuildContext context) {
    return CardSarypos(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, teksConstraints) {
                      final w = teksConstraints.maxWidth;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: w * 0.75, height: 12),
                          const SizedBox(height: 8),
                          SkeletonLine(width: w * 0.56, height: 20),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const SkeletonCircle(diameter: 44),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BarisAktivitasBeranda extends StatelessWidget {
  const _BarisAktivitasBeranda({required this.log});

  final LogAktivitasModel log;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final teks = Theme.of(context).textTheme;
    final warnaAksen = warnaAksenJudulBagian(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: warnaAksen.withValues(alpha: 0.14),
            foregroundColor: warnaAksen,
            radius: 14,
            child: Icon(ikonLogAktivitas(log.jenis), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        judulRingkasLog(log.jenis),
                        style: teks.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: skema.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: teks.labelSmall?.copyWith(
                        color: skema.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Text(
                        waktuLogRelatif(log.waktu),
                        style: teks.labelSmall?.copyWith(
                          color: skema.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  log.deskripsi,
                  style: teks.bodySmall?.copyWith(
                    color: skema.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndikatorAktivitasAdaLagi extends StatelessWidget {
  const _IndikatorAktivitasAdaLagi();

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final teks = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Center(
        child: Text(
          '···',
          style: teks.titleMedium?.copyWith(
            letterSpacing: 6,
            height: 1,
            color: skema.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _DaftarAktivitasSkeleton extends StatelessWidget {
  const _DaftarAktivitasSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        3,
        (index) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonCircle(diameter: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(width: c.maxWidth * 0.62, height: 10),
                            const SizedBox(height: 5),
                            SkeletonLine(width: c.maxWidth * 0.92, height: 11),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void navigasiDaftarProdukDariPreviewBeranda(
  BuildContext context,
  ProdukInventarisModel m,
) {
  if (cegahJikaBelumLogin(
    context,
    pesan:
        'Masuk ke akun terlebih dahulu untuk melihat detail produk.',
  )) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => HalamanFormProduk(produkAwal: m)),
  );
}

class _TombolKapsulOutline extends StatelessWidget {
  const _TombolKapsulOutline({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final aksen = warnaAksenJudulBagian(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.standard,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: aksen.withValues(alpha: 0.5), width: 0.8),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        foregroundColor: aksen,
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

class _MiniGambarProdukBeranda extends StatelessWidget {
  const _MiniGambarProdukBeranda({required this.item});

  final ProdukInventarisModel item;

  @override
  Widget build(BuildContext context) {
    final url = item.produk.gambarUrl;
    final warnaAksen = warnaAksenJudulBagian(context);
    const s = 48.0;
    final latarIkon = warnaAksen.withValues(alpha: 0.12);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: s,
        height: s,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: latarIkon,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: warnaAksen,
                    size: 22,
                  ),
                ),
              )
            : ColoredBox(
                color: latarIkon,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: warnaAksen,
                  size: 22,
                ),
              ),
      ),
    );
  }
}

class _SegelPerhatianProduk extends StatelessWidget {
  const _SegelPerhatianProduk({required this.teks, required this.warnaDasar});

  final String teks;
  final Color warnaDasar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gelap = tema.brightness == Brightness.dark;
    final warnaTeks = warnaDasar == WarnaSarypos.saryGold
        ? (gelap ? tema.colorScheme.onSurface : tema.colorScheme.onSecondary)
        : warnaDasar;
    final alphaLatar = warnaDasar == WarnaSarypos.saryGold
        ? (gelap ? 0.38 : 0.22)
        : 0.14;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warnaDasar.withValues(alpha: alphaLatar),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        teks,
        style: tema.textTheme.labelSmall?.copyWith(
          color: warnaTeks,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BarisProdukPerhatianBeranda extends StatelessWidget {
  const _BarisProdukPerhatianBeranda({required this.item});

  final ProdukInventarisModel item;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final teks = Theme.of(context).textTheme;
    final kad = kadaluarsaDalam7HariInventaris(item);
    final tgl = item.produk.tanggalKadaluarsa;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => navigasiDaftarProdukDariPreviewBeranda(context, item),
        borderRadius: BorderRadius.circular(10),
        splashColor: skema.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniGambarProdukBeranda(item: item),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.produk.nama,
                      style: teks.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: skema.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.stok.jumlah <= 0)
                          const _SegelPerhatianProduk(
                            teks: 'Habis',
                            warnaDasar: WarnaSarypos.saryRed,
                          ),
                        if (item.stok.jumlah > 0 &&
                            item.stok.jumlah <= item.stok.batasKritis)
                          const _SegelPerhatianProduk(
                            teks: 'Stok Menipis',
                            warnaDasar: WarnaSarypos.saryGold,
                          ),
                        if (kad)
                          const _SegelPerhatianProduk(
                            teks: 'Perlu Cek Kadaluarsa',
                            warnaDasar: WarnaSarypos.saryGold,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok: ${item.stok.jumlah}${tgl != null ? ' · EXP ${DateFormat('d MMM yyyy').format(tgl)}' : ''}',
                      style: teks.bodySmall?.copyWith(
                        color: skema.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: skema.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaftarProdukPerhatianSkeleton extends StatelessWidget {
  const _DaftarProdukPerhatianSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        3,
        (index) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(
                    width: 48,
                    height: 48,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(width: c.maxWidth * 0.72, height: 12),
                            const SizedBox(height: 8),
                            SkeletonLine(width: c.maxWidth * 0.4, height: 18),
                            const SizedBox(height: 6),
                            SkeletonLine(width: c.maxWidth * 0.55, height: 11),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
