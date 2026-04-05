import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/data/models/produk_inventaris_model.dart';
import 'package:sarypos/data/sources/produk_dan_stok_sumber.dart';
import 'package:sarypos/features/produk/halaman_form_produk.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

const List<double> _matriksAbuGambarProduk = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

enum FilterProdukManajemen {
  semua,
  mendekatiKadaluarsa,
  kedaluwarsa,
  stokMenipis,
  stokHabis,
}

enum UrutProdukManajemen {
  namaAtoZ,
  namaZtoA,
  stokTerendah,
  stokTertinggi,
  kadaluarsaTerdekat,
  kadaluarsaTerjauh,
  kategoriAtoZ,
}

class HalamanDaftarProduk extends StatefulWidget {
  const HalamanDaftarProduk({
    super.key,
    this.filterAwal = FilterProdukManajemen.semua,
    this.urutAwal = UrutProdukManajemen.namaAtoZ,
  });

  final FilterProdukManajemen filterAwal;
  final UrutProdukManajemen urutAwal;

  @override
  State<HalamanDaftarProduk> createState() => _HalamanDaftarProdukState();
}

class _HalamanDaftarProdukState extends State<HalamanDaftarProduk> {
  static const String kategoriTanpa = '__tanpa_kategori__';

  final _sumber = ProdukDanStokSumber();
  final _cari = TextEditingController();

  bool _sedangMemuat = false;
  bool _hanyaAktifProduk = true;
  String? _pesanError;

  List<ProdukInventarisModel> _produk = [];

  late FilterProdukManajemen _filterProduk;
  late UrutProdukManajemen _urutProduk;

  String? _kategoriFilter;
  List<String> _kategoriTersedia = [];

  bool _pastikanSesiValid() {
    final pengaturSesi = WarisanSesi.dari(context);
    if (pengaturSesi.sedangMemeriksaSesi) return false;
    final sesi = pengaturSesi.pengguna;
    if (sesi == null) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Sesi tidak valid.',
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _filterProduk = widget.filterAwal;
    _urutProduk = widget.urutAwal;
    _muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    try {
      final data = await _sumber.ambilProdukInventaris(
        hanyaAktifProduk: _hanyaAktifProduk,
      );

      final kueri = _cari.text.trim().toLowerCase();
      var hasil = kueri.isEmpty
          ? data
          : data.where((p) {
              final nama = p.produk.nama.toLowerCase();
              final kategori = (p.produk.kategori ?? '').toLowerCase();
              return nama.contains(kueri) || kategori.contains(kueri);
            }).toList();

      if (_filterProduk == FilterProdukManajemen.mendekatiKadaluarsa) {
        hasil = hasil.where(_mendekatiKadaluarsaFilter).toList();
      } else if (_filterProduk == FilterProdukManajemen.kedaluwarsa) {
        hasil = hasil.where(_kedaluwarsaFilter).toList();
      } else if (_filterProduk == FilterProdukManajemen.stokMenipis) {
        hasil = hasil.where(_stokMenipisFilter).toList();
      } else if (_filterProduk == FilterProdukManajemen.stokHabis) {
        hasil = hasil.where(_stokHabisFilter).toList();
      }

      _kategoriTersedia = hasil.map((p) => _kategoriKunci(p)).toSet().toList()
        ..sort((a, b) {
          if (a == kategoriTanpa) return 1;
          if (b == kategoriTanpa) return -1;
          return a.compareTo(b);
        });

      if (_kategoriFilter != null &&
          !_kategoriTersedia.contains(_kategoriFilter)) {
        _kategoriFilter = null;
      }

      final hasilKategori = _kategoriFilter == null
          ? hasil
          : hasil.where(_kategoriSesuaiFilter).toList();

      hasilKategori.sort(_bandingkanProduk);

      setState(() => _produk = hasilKategori);
    } catch (e) {
      setState(() => _pesanError = 'Gagal memuat produk. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  String _formatTanggalKadaluarsa(DateTime tgl) {
    final f = DateFormat('d MMM yyyy');
    return f.format(tgl);
  }

  Color _warnaBadgeStok(ProdukInventarisModel m) {
    final stok = m.stok;
    if (stok.jumlah <= 0) return WarnaSarypos.saryRed;
    if (stok.jumlah <= stok.batasKritis) return WarnaSarypos.saryGold;
    return WarnaSarypos.deepTeal;
  }

  String _teksBadgeStok(ProdukInventarisModel m) {
    final stok = m.stok;
    if (stok.jumlah <= 0) return 'Habis';
    if (stok.jumlah <= stok.batasKritis) return 'Menipis';
    return 'Normal';
  }

  bool _kadaluarsaDalam7Hari(ProdukInventarisModel m) {
    final tgl = m.produk.tanggalKadaluarsa;
    if (tgl == null) return false;
    final now = DateTime.now();
    final awal = DateTime(now.year, now.month, now.day);
    final akhir = awal.add(const Duration(days: 7));
    return (tgl.isAtSameMomentAs(awal) || tgl.isAfter(awal)) &&
        (tgl.isAtSameMomentAs(akhir) || tgl.isBefore(akhir));
  }

  bool _mendekatiKadaluarsaFilter(ProdukInventarisModel m) {
    if (m.produk.aktif != true) return false;
    return _kadaluarsaDalam7Hari(m);
  }

  bool _kedaluwarsaFilter(ProdukInventarisModel m) {
    if (m.produk.aktif != true) return false;
    return _sudahKadaluarsa(m);
  }

  bool _stokMenipisFilter(ProdukInventarisModel m) {
    if (m.produk.aktif != true) return false;
    final jumlah = m.stok.jumlah;
    return jumlah > 0 && jumlah <= m.stok.batasKritis;
  }

  bool _stokHabisFilter(ProdukInventarisModel m) {
    if (m.produk.aktif != true) return false;
    return m.stok.jumlah <= 0;
  }

  String _kategoriKunci(ProdukInventarisModel m) {
    final k = m.produk.kategori;
    if (k == null || k.trim().isEmpty) return kategoriTanpa;
    return k;
  }

  bool _kategoriSesuaiFilter(ProdukInventarisModel m) {
    if (_kategoriFilter == null) return true;
    return _kategoriKunci(m) == _kategoriFilter;
  }

  int _bandingkanProduk(ProdukInventarisModel a, ProdukInventarisModel b) {
    return switch (_urutProduk) {
      UrutProdukManajemen.namaAtoZ => a.produk.nama.compareTo(b.produk.nama),
      UrutProdukManajemen.namaZtoA => b.produk.nama.compareTo(a.produk.nama),
      UrutProdukManajemen.stokTerendah => a.stok.jumlah.compareTo(
        b.stok.jumlah,
      ),
      UrutProdukManajemen.stokTertinggi => b.stok.jumlah.compareTo(
        a.stok.jumlah,
      ),
      UrutProdukManajemen.kadaluarsaTerdekat => () {
        final ta = a.produk.tanggalKadaluarsa;
        final tb = b.produk.tanggalKadaluarsa;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb);
      }(),
      UrutProdukManajemen.kadaluarsaTerjauh => () {
        final ta = a.produk.tanggalKadaluarsa;
        final tb = b.produk.tanggalKadaluarsa;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      }(),
      UrutProdukManajemen.kategoriAtoZ => (a.produk.kategori ?? '').compareTo(
        b.produk.kategori ?? '',
      ),
    };
  }

  bool _sudahKadaluarsa(ProdukInventarisModel m) {
    final tgl = m.produk.tanggalKadaluarsa;
    if (tgl == null) return false;
    final now = DateTime.now();
    final awal = DateTime(now.year, now.month, now.day);
    return tgl.isBefore(awal);
  }

  Future<void> _konfirmasiNonaktifkan(ProdukInventarisModel m) async {
    if (!_pastikanSesiValid()) return;
    final aktif = m.produk.aktif;
    final dialog = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(aktif == true ? 'Nonaktifkan Produk' : 'Aktifkan Produk'),
          content: Text(
            aktif == true
                ? 'Produk "${m.produk.nama}" akan disembunyikan dari POS.'
                : 'Produk "${m.produk.nama}" akan ditampilkan kembali di POS.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(aktif == true ? 'Nonaktifkan' : 'Aktifkan'),
            ),
          ],
        );
      },
    );

    if (dialog != true) return;

    try {
      if (aktif == true) {
        await _sumber.nonaktifkanProduk(produkId: m.produk.id);
      } else {
        if (!mounted) return;
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => HalamanFormProduk(produkAwal: m)),
        );
        if (saved != true) {
          return;
        }
      }
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Perubahan status produk tersimpan.',
      );
      await _muat();
    } catch (_) {
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Gagal mengubah status produk.',
      );
    }
  }

  Future<void> _bukaFormTambahProduk() async {
    if (!_pastikanSesiValid()) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HalamanFormProduk()));
    if (!mounted) return;
    await _muat();
  }

  Widget _chipFilter({
    required String label,
    required bool selected,
    required VoidCallback onPilih,
  }) {
    final tema = Theme.of(context);
    final gayaTeks = tema.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      height: 1.1,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );
    return ChoiceChip(
      label: Text(label, style: gayaTeks),
      selected: selected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      side: BorderSide(
        color: selected
            ? WarnaSarypos.deepTeal
            : WarnaSarypos.warmGray.withValues(alpha: 0.9),
      ),
      selectedColor: WarnaSarypos.deepTeal.withValues(alpha: 0.18),
      onSelected: (_) => onPilih(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget isi;
    if (_sedangMemuat) {
      isi = const _DaftarProdukGridSkeleton();
    } else if (_pesanError != null) {
      isi = EmptyStateGenerik(
        ikon: Icons.error_outline,
        judul: 'Gagal Memuat Produk',
        pesan: _pesanError!,
        labelTombol: 'Coba lagi',
        onTekanTombol: _muat,
      );
    } else if (_produk.isEmpty) {
      final (judul, pesan) = switch (_filterProduk) {
        FilterProdukManajemen.mendekatiKadaluarsa => (
          'Belum Ada Produk Mendekati Kadaluarsa',
          'Produk yang aktif dan tanggal kadaluarsanya ≤ 7 hari belum tersedia.',
        ),
        FilterProdukManajemen.kedaluwarsa => (
          'Belum Ada Produk Kedaluwarsa',
          'Produk yang aktif dan tanggal kadaluarsanya sudah lewat belum tersedia.',
        ),
        FilterProdukManajemen.stokMenipis => (
          'Belum Ada Produk Stok Menipis',
          'Tidak ada produk aktif dengan jumlah stok > 0 dan ≤ batas kritis.',
        ),
        FilterProdukManajemen.stokHabis => (
          'Belum Ada Produk Stok Habis',
          'Tidak ada produk aktif dengan jumlah stok ≤ 0.',
        ),
        _ => (
          'Belum Ada Produk',
          'Tambahkan produk untuk memulai pencatatan transaksi.',
        ),
      };
      isi = EmptyStateGenerik(
        ikon: Icons.inventory_2_outlined,
        judul: judul,
        pesan: pesan,
      );
    } else {
      isi = GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _produk.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemBuilder: (context, indeks) {
          final tema = Theme.of(context);
          final m = _produk[indeks];
          final nonaktif = m.produk.aktif != true;
          final tgl = m.produk.tanggalKadaluarsa;
          final statusKadaluarsa = _sudahKadaluarsa(m)
              ? 'Kedaluwarsa'
              : _kadaluarsaDalam7Hari(m)
              ? '≤ 7 hari'
              : null;

          final warnaKadaluarsa = _sudahKadaluarsa(m)
              ? WarnaSarypos.saryRed
              : WarnaSarypos.saryGold;
          final warnaBadgeStok = _warnaBadgeStok(m);
          final labelBadgeStok = _teksBadgeStok(m);
          final gelap = tema.brightness == Brightness.dark;
          final (
            warnaLatarBadgeStok,
            warnaTeksBadgeStok,
          ) = switch (labelBadgeStok) {
            'Normal' =>
              gelap
                  ? (
                      tema.colorScheme.secondary.withValues(alpha: 0.34),
                      tema.colorScheme.onSurface,
                    )
                  : (warnaBadgeStok.withValues(alpha: 0.14), warnaBadgeStok),
            'Menipis' =>
              gelap
                  ? (
                      WarnaSarypos.saryGold.withValues(alpha: 0.40),
                      tema.colorScheme.onSurface,
                    )
                  : (
                      WarnaSarypos.saryGold.withValues(alpha: 0.24),
                      tema.colorScheme.onSecondary,
                    ),
            'Habis' =>
              gelap
                  ? (
                      WarnaSarypos.saryRed.withValues(alpha: 0.38),
                      tema.colorScheme.onSurface,
                    )
                  : (
                      WarnaSarypos.saryRed.withValues(alpha: 0.20),
                      const Color(0xFF7A1A15),
                    ),
            _ => (warnaBadgeStok.withValues(alpha: 0.14), warnaBadgeStok),
          };
          final (
            latarKadaluarsa,
            teksKadaluarsa,
          ) = warnaKadaluarsa == WarnaSarypos.saryGold
              ? (gelap
                    ? (
                        WarnaSarypos.saryGold.withValues(alpha: 0.40),
                        tema.colorScheme.onSurface,
                      )
                    : (
                        WarnaSarypos.saryGold.withValues(alpha: 0.24),
                        tema.colorScheme.onSecondary,
                      ))
              : (gelap
                    ? (
                        WarnaSarypos.saryRed.withValues(alpha: 0.38),
                        tema.colorScheme.onSurface,
                      )
                    : (
                        WarnaSarypos.saryRed.withValues(alpha: 0.20),
                        const Color(0xFF7A1A15),
                      ));

          return Opacity(
            opacity: nonaktif ? 0.74 : 1,
            child: CardSarypos(
              onTap: () async {
                if (!_pastikanSesiValid()) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HalamanFormProduk(produkAwal: m),
                  ),
                );
                if (!mounted) return;
                await _muat();
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Builder(
                          builder: (context) {
                            final Widget dasar = m.produk.gambarUrl != null
                                ? Image.network(
                                    m.produk.gambarUrl!,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.low,
                                    gaplessPlayback: true,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) {
                                        return TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOut,
                                          builder: (context, value, gambar) {
                                            return Opacity(
                                              opacity: value,
                                              child: gambar,
                                            );
                                          },
                                          child: child,
                                        );
                                      }
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: const [
                                          SkeletonBox(
                                            width: double.infinity,
                                            height: 100,
                                            borderRadius: 10,
                                          ),
                                          Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.8,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(Icons.inventory_2_outlined),
                                  );
                            if (nonaktif) {
                              return ColorFiltered(
                                colorFilter: const ColorFilter.matrix(
                                  _matriksAbuGambarProduk,
                                ),
                                child: dasar,
                              );
                            }
                            return dasar;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.produk.nama,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kategori: ${m.produk.kategori ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Kadaluarsa: ${tgl == null ? '-' : _formatTanggalKadaluarsa(tgl)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: warnaLatarBadgeStok,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${m.stok.jumlah} · $labelBadgeStok',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: warnaTeksBadgeStok,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (statusKadaluarsa != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: latarKadaluarsa,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusKadaluarsa,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: teksKadaluarsa,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: IconButton(
                        tooltip: m.produk.aktif == true
                            ? 'Nonaktifkan produk'
                            : 'Aktifkan (via edit)',
                        visualDensity: VisualDensity.compact,
                        iconSize: 24,
                        icon: Icon(
                          m.produk.aktif == true
                              ? Icons.toggle_on
                              : Icons.toggle_off,
                          color: m.produk.aktif == true
                              ? WarnaSarypos.deepTeal
                              : WarnaSarypos.darkStone,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _konfirmasiNonaktifkan(m),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final tema = Theme.of(context);
    final gayaKontrol =
        tema.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.2) ??
        const TextStyle(fontSize: 12, height: 1.2);
    final gayaLabelField = tema.textTheme.labelSmall?.copyWith(fontSize: 11);

    return Scaffold(
      appBar: AppBarSarypos(
        judul: 'Manajemen Produk',
        aksi: [
          IconButton(
            tooltip: 'Tambah produk',
            onPressed: _bukaFormTambahProduk,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _cari,
                onChanged: (_) => _muat(),
                style: gayaKontrol.copyWith(color: tema.colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nama atau kategori',
                  hintStyle: gayaKontrol.copyWith(color: tema.hintColor),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 36,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.82,
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      value: !_hanyaAktifProduk,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) {
                        setState(() => _hanyaAktifProduk = !v);
                        _muat();
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tampilkan nonaktif',
                      style: tema.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chipFilter(
                        label: 'Semua',
                        selected: _filterProduk == FilterProdukManajemen.semua,
                        onPilih: () {
                          setState(
                            () => _filterProduk = FilterProdukManajemen.semua,
                          );
                          _muat();
                        },
                      ),
                      const SizedBox(width: 6),
                      _chipFilter(
                        label: '≤7 hari',
                        selected:
                            _filterProduk ==
                            FilterProdukManajemen.mendekatiKadaluarsa,
                        onPilih: () {
                          setState(
                            () => _filterProduk =
                                FilterProdukManajemen.mendekatiKadaluarsa,
                          );
                          _muat();
                        },
                      ),
                      const SizedBox(width: 6),
                      _chipFilter(
                        label: 'Kedaluwarsa',
                        selected:
                            _filterProduk == FilterProdukManajemen.kedaluwarsa,
                        onPilih: () {
                          setState(
                            () => _filterProduk =
                                FilterProdukManajemen.kedaluwarsa,
                          );
                          _muat();
                        },
                      ),
                      const SizedBox(width: 6),
                      _chipFilter(
                        label: 'Menipis',
                        selected:
                            _filterProduk == FilterProdukManajemen.stokMenipis,
                        onPilih: () {
                          setState(
                            () => _filterProduk =
                                FilterProdukManajemen.stokMenipis,
                          );
                          _muat();
                        },
                      ),
                      const SizedBox(width: 6),
                      _chipFilter(
                        label: 'Habis',
                        selected:
                            _filterProduk == FilterProdukManajemen.stokHabis,
                        onPilih: () {
                          setState(
                            () =>
                                _filterProduk = FilterProdukManajemen.stokHabis,
                          );
                          _muat();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Urut',
                        labelStyle: gayaLabelField,
                        contentPadding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UrutProdukManajemen>(
                          value: _urutProduk,
                          isDense: true,
                          isExpanded: true,
                          style: gayaKontrol.copyWith(
                            color: tema.colorScheme.onSurface,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: UrutProdukManajemen.namaAtoZ,
                              child: Text('Nama A-Z'),
                            ),
                            DropdownMenuItem(
                              value: UrutProdukManajemen.namaZtoA,
                              child: Text('Nama Z-A'),
                            ),
                            DropdownMenuItem(
                              value: UrutProdukManajemen.stokTerendah,
                              child: Text('Stok ↑'),
                            ),
                            DropdownMenuItem(
                              value: UrutProdukManajemen.stokTertinggi,
                              child: Text('Stok ↓'),
                            ),
                            DropdownMenuItem(
                              value: UrutProdukManajemen.kadaluarsaTerdekat,
                              child: Text('Kadaluarsa dekat'),
                            ),
                            DropdownMenuItem(
                              value: UrutProdukManajemen.kadaluarsaTerjauh,
                              child: Text('Kadaluarsa jauh'),
                            ),
                            DropdownMenuItem(
                              value: UrutProdukManajemen.kategoriAtoZ,
                              child: Text('Kategori A-Z'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _urutProduk = v);
                            _muat();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Kategori',
                        labelStyle: gayaLabelField,
                        contentPadding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _kategoriFilter,
                          isDense: true,
                          isExpanded: true,
                          style: gayaKontrol.copyWith(
                            color: tema.colorScheme.onSurface,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua'),
                            ),
                            ..._kategoriTersedia.map(
                              (k) => DropdownMenuItem<String?>(
                                value: k,
                                child: Text(
                                  k == kategoriTanpa ? 'Tanpa' : k,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _kategoriFilter = v);
                            _muat();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: isi),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaftarProdukGridSkeleton extends StatelessWidget {
  const _DaftarProdukGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, indeks) {
        return CardSarypos(
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: SkeletonBox(
                          width: w,
                          height: 100,
                          borderRadius: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLine(width: w * 0.85, height: 18, borderRadius: 10),
                    const SizedBox(height: 2),
                    SkeletonLine(width: w * 0.75, height: 14, borderRadius: 10),
                    const SizedBox(height: 1),
                    SkeletonLine(width: w * 0.78, height: 14, borderRadius: 10),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonLine(
                            width: w * 0.45,
                            height: 14,
                            borderRadius: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SkeletonLine(
                            width: w * 0.45,
                            height: 14,
                            borderRadius: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Align(
                      alignment: Alignment.bottomLeft,
                      child: SkeletonBox(
                        width: 34,
                        height: 22,
                        borderRadius: 10,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
