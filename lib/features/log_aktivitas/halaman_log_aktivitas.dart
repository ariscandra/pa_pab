import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/presentasi_log_aktivitas.dart';
import 'package:sarypos/data/models/log_aktivitas_model.dart';
import 'package:sarypos/data/sources/log_aktivitas_sumber.dart';
import 'package:sarypos/core/warisan_tema.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/chip_filter_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';

const _kunciFilterLog = [
  'semua',
  'transaksi',
  'stok',
  'karyawan',
  'akun',
  'laporan',
  'gangguan',
];

class HalamanLogAktivitas extends StatefulWidget {
  const HalamanLogAktivitas({super.key});

  @override
  State<HalamanLogAktivitas> createState() => _HalamanLogAktivitasState();
}

class _HalamanLogAktivitasState extends State<HalamanLogAktivitas> {
  final _sumber = LogAktivitasSumber();
  final _cari = TextEditingController();
  Timer? _debounceCari;

  List<LogAktivitasModel> _semua = [];
  bool _sedangMuat = true;
  bool _sedangMuatUlang = false;
  Object? _error;
  String _filterKategori = 'semua';
  String _kueriCari = '';

  @override
  void initState() {
    super.initState();
    _cari.addListener(_onCariBerubah);
    _muatPertama();
  }

  @override
  void dispose() {
    _debounceCari?.cancel();
    _cari.removeListener(_onCariBerubah);
    _cari.dispose();
    super.dispose();
  }

  void _onCariBerubah() {
    _debounceCari?.cancel();
    _debounceCari = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _kueriCari = _cari.text.trim().toLowerCase());
    });
  }

  Future<void> _muatPertama() async {
    setState(() {
      _sedangMuat = true;
      _error = null;
    });
    await _ambilData(menandaiMuatUlang: false);
  }

  Future<void> _muatUlang() async {
    setState(() => _sedangMuatUlang = true);
    await _ambilData(menandaiMuatUlang: true);
  }

  Future<void> _ambilData({required bool menandaiMuatUlang}) async {
    try {
      final daftar = await _sumber.ambilTerbaru(batas: 100);
      if (!mounted) return;
      setState(() {
        _semua = daftar;
        _error = null;
        _sedangMuat = false;
        _sedangMuatUlang = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _sedangMuat = false;
        _sedangMuatUlang = false;
      });
    }
  }

  List<LogAktivitasModel> get _terfilter {
    return _semua.where((log) {
      if (!logMasukKategoriFilter(log.jenis, _filterKategori)) {
        return false;
      }
      if (_kueriCari.isEmpty) return true;
      return teksPencarianLog(
        jenis: log.jenis,
        deskripsi: log.deskripsi,
        metadata: log.metadataJson,
      ).contains(_kueriCari);
    }).toList();
  }

  void _bukaDetail(LogAktivitasModel log) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final warnaJenis = warnaAksenJenisLog(context, log.jenis);
    final lokasi = teksLokasiDariMetadataJson(log.metadataJson);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final tinggiMaks = MediaQuery.sizeOf(ctx).height * 0.85;
        final aksen = warnaAksenJudulBagian(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: tinggiMaks),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  20 + MediaQuery.viewPaddingOf(ctx).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: warnaJenis.withValues(alpha: 0.16),
                          foregroundColor: warnaJenis,
                          child: Icon(ikonLogAktivitas(log.jenis), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                judulRingkasLog(log.jenis),
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatWaktuLogLengkap(log.waktu),
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: skema.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      log.deskripsi,
                      style: tema.textTheme.bodyMedium,
                    ),
                    if (lokasi != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: aksen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lokasi,
                              style: tema.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WarisanTema.dari(context);
    final skema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBarSarypos(
        judul: 'Log Aktivitas',
        aksi: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: (_sedangMuat || _sedangMuatUlang) ? null : _muatUlang,
            icon: _sedangMuatUlang
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: skema.onPrimary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _bangunIsi(context),
          ),
        ),
      ),
    );
  }

  Widget _bangunIsi(BuildContext context) {
    if (_sedangMuat) {
      return const _LogAktivitasSkeleton(denganHeader: true);
    }
    if (_error != null) {
      return EmptyStateGenerik(
        ikon: Icons.cloud_off_outlined,
        judul: 'Tidak dapat memuat log',
        pesan: 'Periksa koneksi lalu coba muat ulang.',
        labelTombol: 'Coba lagi',
        onTekanTombol: _muatUlang,
      );
    }

    final terfilter = _terfilter;
    final adaData = _semua.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Cari log aktivitas',
                child: TextField(
                  controller: _cari,
                  enabled: adaData,
                  textInputAction: TextInputAction.search,
                  onSubmitted: adaData ? (_) => FocusScope.of(context).unfocus() : null,
                  decoration: InputDecoration(
                    hintText: adaData
                        ? 'Cari aktivitas, deskripsi, atau lokasi'
                        : 'Belum ada data untuk dicari',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _kueriCari.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _debounceCari?.cancel();
                              _cari.clear();
                              setState(() => _kueriCari = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kunciFilterLog.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final kunci = _kunciFilterLog[i];
                    final dipilih = _filterKategori == kunci;
                    return ChipFilterSarypos(
                      label: labelKategoriFilterLog(kunci),
                      selected: dipilih,
                      enabled: adaData,
                      onPilih: () => setState(() => _filterKategori = kunci),
                    );
                  },
                ),
              ),
              if (adaData) ...[
                const SizedBox(height: 10),
                Text(
                  terfilter.isEmpty
                      ? 'Tidak ada catatan yang cocok'
                      : 'Menampilkan ${terfilter.length} dari ${_semua.length} catatan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<String>(_filterKategori),
              child: _bangunDaftar(context, terfilter, adaData),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bangunDaftar(
    BuildContext context,
    List<LogAktivitasModel> terfilter,
    bool adaData,
  ) {
    if (!adaData) {
      return RefreshIndicator(
        onRefresh: _muatUlang,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 48),
            EmptyStateGenerik(
              ikon: Icons.history,
              judul: 'Belum ada catatan',
              pesan:
                  'Log akan muncul setelah ada transaksi, perubahan stok, atau aktivitas lain.',
            ),
          ],
        ),
      );
    }

    if (terfilter.isEmpty) {
      return RefreshIndicator(
        onRefresh: _muatUlang,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 32),
            EmptyStateGenerik(
              ikon: Icons.filter_alt_off_outlined,
              judul: 'Tidak ada hasil',
              pesan: _kueriCari.isNotEmpty
                  ? 'Coba kata kunci lain atau hapus filter kategori.'
                  : 'Ubah filter kategori untuk melihat catatan lain.',
              labelTombol: 'Reset filter',
              onTekanTombol: () {
                _debounceCari?.cancel();
                setState(() {
                  _filterKategori = 'semua';
                  _cari.clear();
                  _kueriCari = '';
                });
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatUlang,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: terfilter.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final log = terfilter[i];
          return _KartuLogAktivitas(
            log: log,
            onTap: () => _bukaDetail(log),
          );
        },
      ),
    );
  }
}

class _KartuLogAktivitas extends StatelessWidget {
  const _KartuLogAktivitas({
    required this.log,
    required this.onTap,
  });

  final LogAktivitasModel log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final warnaJenis = warnaAksenJenisLog(context, log.jenis);
    final lokasi = teksLokasiDariMetadataJson(log.metadataJson);
    final ringkas = waktuLogRelatif(log.waktu);
    final labelA11y =
        '${judulRingkasLog(log.jenis)}. ${log.deskripsi}${lokasi != null ? '. Lokasi $lokasi' : ''}. $ringkas. Ketuk untuk detail.';

    return Semantics(
      button: true,
      label: labelA11y,
      child: CardSarypos(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: warnaJenis.withValues(alpha: 0.16),
                foregroundColor: warnaJenis,
                child: Icon(ikonLogAktivitas(log.jenis), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: warnaJenis.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ikonLogAktivitas(log.jenis),
                                  size: 14,
                                  color: warnaJenis,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    judulRingkasLog(log.jenis),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tema.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: warnaJenis,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: skema.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ringkas,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: skema.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      log.deskripsi,
                      style: tema.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lokasi != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: skema.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lokasi,
                              style: tema.textTheme.labelSmall?.copyWith(
                                color: skema.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 10),
                child: Semantics(
                  label: 'Buka detail',
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: skema.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogAktivitasSkeleton extends StatelessWidget {
  const _LogAktivitasSkeleton({this.denganHeader = false});

  final bool denganHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (denganHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                const SkeletonBox(
                  width: double.infinity,
                  height: 52,
                  borderRadius: 12,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, _) => const SkeletonBox(
                      width: 72,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    return SkeletonLine(width: c.maxWidth * 0.5, height: 12);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return CardSarypos(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonCircle(diameter: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonLine(
                                  width: c.maxWidth * 0.55,
                                  height: 14,
                                ),
                                const SizedBox(height: 8),
                                SkeletonLine(
                                  width: c.maxWidth * 0.92,
                                  height: 11,
                                ),
                                const SizedBox(height: 6),
                                SkeletonLine(
                                  width: c.maxWidth * 0.7,
                                  height: 11,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
