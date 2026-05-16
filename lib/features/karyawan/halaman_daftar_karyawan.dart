import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/format_rupiah.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/data/models/karyawan_lengkap_model.dart';
import 'package:sarypos/data/sources/pengguna_sumber.dart';
import 'package:sarypos/features/karyawan/halaman_form_karyawan.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/chip_filter_sarypos.dart';
import 'package:sarypos/widgets/dialog_konfirmasi_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

const _kunciFilterStatusKaryawan = ['semua', 'aktif', 'nonaktif'];

class HalamanDaftarKaryawan extends StatefulWidget {
  const HalamanDaftarKaryawan({super.key});

  @override
  State<HalamanDaftarKaryawan> createState() => _HalamanDaftarKaryawanState();
}

class _HalamanDaftarKaryawanState extends State<HalamanDaftarKaryawan> {
  final _sumber = PenggunaSumber();
  late Future<List<KaryawanLengkapModel>> _future;
  String? _sedangUbahStatusPenggunaId;
  String _filterStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _future = _sumber.ambilKaryawanDenganProfil();
  }

  Future<void> _muatUlang() async {
    setState(() {
      _future = _sumber.ambilKaryawanDenganProfil();
    });
    await _future;
  }

  List<KaryawanLengkapModel> _terfilter(List<KaryawanLengkapModel> list) {
    switch (_filterStatus) {
      case 'aktif':
        return list.where((k) => k.pengguna.aktif).toList();
      case 'nonaktif':
        return list.where((k) => !k.pengguna.aktif).toList();
      default:
        return list;
    }
  }

  Future<void> _toggleAktif(KaryawanLengkapModel k) async {
    final sebelumAktif = k.pengguna.aktif;
    if (sebelumAktif) {
      final setuju = await tampilkanDialogKonfirmasiSarypos(
        context,
        judul: 'Nonaktifkan karyawan?',
        pesan:
            '${k.pengguna.namaLengkap} tidak bisa masuk hingga diaktifkan kembali.',
        labelLanjut: 'Nonaktifkan',
        destruktif: true,
      );
      if (!setuju || !mounted) {
        return;
      }
    }
    setState(() => _sedangUbahStatusPenggunaId = k.pengguna.id);
    try {
      await _sumber.ubahStatusAktif(
        idPengguna: k.pengguna.id,
        aktif: !k.pengguna.aktif,
      );
      await _muatUlang();
      if (!mounted) {
        return;
      }
      final oid = WarisanSesi.dari(context).pengguna?.id;
      if (oid != null) {
        catatLogAktivitas(
          idPengguna: oid,
          jenis: JenisLogAktivitas.karyawanStatus,
          deskripsi: sebelumAktif
              ? 'Menonaktifkan ${k.pengguna.namaLengkap}'
              : 'Mengaktifkan ${k.pengguna.namaLengkap}',
          metadataJson: {'pengguna_id': k.pengguna.id},
        );
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: sebelumAktif
            ? 'Karyawan dinonaktifkan.'
            : 'Karyawan diaktifkan kembali.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Gagal mengubah status. Coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _sedangUbahStatusPenggunaId = null);
      }
    }
  }

  String _subjudul(KaryawanLengkapModel k) {
    final p = k.profil;
    final gaji = p?.gajiBulanan != null
        ? formatRupiah(p!.gajiBulanan!)
        : 'Gaji belum diisi';
    final hg = p?.hariGajian != null
        ? 'Gajian: tgl ${p!.hariGajian}'
        : 'Tanggal gajian belum diisi';
    return '${k.pengguna.email}\n$gaji · $hg';
  }

  @override
  Widget build(BuildContext context) {
    final pengatur = WarisanSesi.dari(context);

    return Scaffold(
      appBar: AppBarSarypos(
        judul: 'Karyawan',
        aksi: [
          IconButton(
            tooltip: 'Tambah karyawan',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HalamanFormKaryawanTambah(pengatur: pengatur),
                ),
              );
              await _muatUlang();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: FutureBuilder<List<KaryawanLengkapModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _DaftarKaryawanSkeleton();
                }
                if (snapshot.hasError) {
                  return EmptyStateGenerik(
                    ikon: Icons.error_outline,
                    judul: 'Gagal Memuat Data',
                    pesan: 'Periksa koneksi dan izin Supabase, lalu coba lagi.',
                    labelTombol: 'Coba lagi',
                    onTekanTombol: _muatUlang,
                  );
                }

                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _muatUlang,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        EmptyStateGenerik(
                          ikon: Icons.groups_outlined,
                          judul: 'Belum ada karyawan',
                          pesan:
                              'Tambah karyawan lalu lengkapi profil HR (gaji, tanggal gajian).',
                          labelTombol: 'Tambah karyawan',
                          onTekanTombol: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HalamanFormKaryawanTambah(
                                  pengatur: pengatur,
                                ),
                              ),
                            );
                            await _muatUlang();
                          },
                        ),
                      ],
                    ),
                  );
                }

                final terfilter = _terfilter(list);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _kunciFilterStatusKaryawan.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, i) {
                                final kunci = _kunciFilterStatusKaryawan[i];
                                final label = switch (kunci) {
                                  'aktif' => 'Aktif',
                                  'nonaktif' => 'Nonaktif',
                                  _ => 'Semua',
                                };
                                return ChipFilterSarypos(
                                  label: label,
                                  selected: _filterStatus == kunci,
                                  onPilih: () =>
                                      setState(() => _filterStatus = kunci),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            terfilter.isEmpty
                                ? 'Tidak ada karyawan pada filter ini'
                                : 'Menampilkan ${terfilter.length} dari ${list.length} karyawan',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Expanded(
                      child: terfilter.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _muatUlang,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 32),
                                  EmptyStateGenerik(
                                    ikon: Icons.filter_alt_off_outlined,
                                    judul: 'Tidak ada hasil',
                                    pesan:
                                        'Ubah filter status untuk melihat karyawan lain.',
                                    labelTombol: 'Tampilkan semua',
                                    onTekanTombol: () => setState(
                                      () => _filterStatus = 'semua',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _muatUlang,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                itemCount: terfilter.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final k = terfilter[i];
                                  return _KartuKaryawan(
                                    karyawan: k,
                                    sedangUbahStatus:
                                        _sedangUbahStatusPenggunaId ==
                                        k.pengguna.id,
                                    subjudul: _subjudul(k),
                                    onToggleAktif: () => _toggleAktif(k),
                                    onBukaDetail: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              HalamanFormKaryawanEdit(
                                            karyawanAwal: k.pengguna,
                                          ),
                                        ),
                                      );
                                      await _muatUlang();
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuKaryawan extends StatelessWidget {
  const _KartuKaryawan({
    required this.karyawan,
    required this.sedangUbahStatus,
    required this.subjudul,
    required this.onToggleAktif,
    required this.onBukaDetail,
  });

  final KaryawanLengkapModel karyawan;
  final bool sedangUbahStatus;
  final String subjudul;
  final VoidCallback onToggleAktif;
  final VoidCallback onBukaDetail;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final aktif = karyawan.pengguna.aktif;
    final url = karyawan.profil?.fotoUrl;

    return CardSarypos(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label:
                    '${karyawan.pengguna.namaLengkap}. ${aktif ? 'Aktif' : 'Nonaktif'}. Ketuk untuk ubah profil.',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onBukaDetail,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: aktif ? 1 : 0.65,
                          child: _AvatarKaryawan(
                            namaLengkap: karyawan.pengguna.namaLengkap,
                            fotoUrl: url,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      karyawan.pengguna.namaLengkap,
                                      style: tema.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (!aktif)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: skema.errorContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_off_outlined,
                                            size: 14,
                                            color: skema.onErrorContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Nonaktif',
                                            style: tema.textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: skema.onErrorContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subjudul,
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: skema.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            sedangUbahStatus
                  ? const SizedBox(
                      width: 52,
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Semantics(
                      label: aktif
                          ? 'Nonaktifkan karyawan'
                          : 'Aktifkan karyawan',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: aktif,
                            onChanged: (_) => onToggleAktif(),
                          ),
                          Text(
                            'Aktif',
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: skema.onSurfaceVariant,
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

class _AvatarKaryawan extends StatelessWidget {
  const _AvatarKaryawan({required this.namaLengkap, required this.fotoUrl});

  final String namaLengkap;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final hurufAwal = namaLengkap.isNotEmpty
        ? namaLengkap[0].toUpperCase()
        : '?';
    final urlValid = fotoUrl != null && fotoUrl!.isNotEmpty;

    if (!urlValid) {
      return CircleAvatar(
        backgroundColor: WarnaSarypos.warmGray,
        foregroundColor: tema.colorScheme.onSurface,
        child: Text(hurufAwal),
      );
    }

    return CircleAvatar(
      backgroundColor: WarnaSarypos.warmGray.withValues(alpha: 0.35),
      child: ClipOval(
        child: Image.network(
          fotoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return Container(
              width: 40,
              height: 40,
              color: WarnaSarypos.warmGray.withValues(alpha: 0.4),
              alignment: Alignment.center,
              child: Text(
                hurufAwal,
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurface,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 40,
              height: 40,
              color: WarnaSarypos.warmGray,
              alignment: Alignment.center,
              child: Text(
                hurufAwal,
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DaftarKaryawanSkeleton extends StatelessWidget {
  const _DaftarKaryawanSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return CardSarypos(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const SkeletonCircle(diameter: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: c.maxWidth * 0.54, height: 14),
                          const SizedBox(height: 7),
                          SkeletonLine(width: c.maxWidth * 0.82, height: 11),
                          const SizedBox(height: 6),
                          SkeletonLine(width: c.maxWidth * 0.7, height: 11),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const SkeletonBox(width: 42, height: 24, borderRadius: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
