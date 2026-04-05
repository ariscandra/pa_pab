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
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanDaftarKaryawan extends StatefulWidget {
  const HalamanDaftarKaryawan({super.key});

  @override
  State<HalamanDaftarKaryawan> createState() => _HalamanDaftarKaryawanState();
}

class _HalamanDaftarKaryawanState extends State<HalamanDaftarKaryawan> {
  final _sumber = PenggunaSumber();
  late Future<List<KaryawanLengkapModel>> _future;
  String? _sedangUbahStatusPenggunaId;

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

  Future<void> _toggleAktif(KaryawanLengkapModel k) async {
    final sebelumAktif = k.pengguna.aktif;
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
      body: FutureBuilder<List<KaryawanLengkapModel>>(
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
            return EmptyStateGenerik(
              ikon: Icons.groups_outlined,
              judul: 'Belum Ada Karyawan',
              pesan:
                  'Tambah karyawan lalu lengkapi profil HR (gaji, tanggal gajian).',
              labelTombol: 'Muat ulang',
              onTekanTombol: _muatUlang,
            );
          }

          return RefreshIndicator(
            onRefresh: _muatUlang,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final k = list[i];
                final url = k.profil?.fotoUrl;
                return CardSarypos(
                  child: ListTile(
                    leading: _AvatarKaryawan(
                      namaLengkap: k.pengguna.namaLengkap,
                      fotoUrl: url,
                    ),
                    title: Text(k.pengguna.namaLengkap),
                    subtitle: Text(_subjudul(k)),
                    isThreeLine: true,
                    trailing: Switch(
                      value: k.pengguna.aktif,
                      onChanged: _sedangUbahStatusPenggunaId == k.pengguna.id
                          ? null
                          : (_) => _toggleAktif(k),
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HalamanFormKaryawanEdit(karyawanAwal: k.pengguna),
                        ),
                      );
                      await _muatUlang();
                    },
                  ),
                );
              },
            ),
          );
        },
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
