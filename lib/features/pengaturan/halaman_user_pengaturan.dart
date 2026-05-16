import 'package:flutter/material.dart';
import 'package:sarypos/config/inset_nav_utama.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/core/penjaga_rute_owner.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/features/auth/halaman_daftar_owner.dart';
import 'package:sarypos/features/auth/halaman_login.dart';
import 'package:sarypos/features/karyawan/halaman_daftar_karyawan.dart';
import 'package:sarypos/features/log_aktivitas/halaman_log_aktivitas.dart';
import 'package:sarypos/features/pengaturan/panel_transaksi_terakhir_karyawan.dart';
import 'package:sarypos/features/laporan/halaman_laporan_penjualan.dart';
import 'package:sarypos/features/pengaturan/halaman_tentang_sarypos.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/dialog_konfirmasi_sarypos.dart';
import 'package:sarypos/widgets/judul_bagian_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanUserPengaturan extends StatefulWidget {
  const HalamanUserPengaturan({super.key});

  @override
  State<HalamanUserPengaturan> createState() => _HalamanUserPengaturanState();
}

class _HalamanUserPengaturanState extends State<HalamanUserPengaturan> {
  bool _sedangKeluar = false;

  Future<void> _keluarAkun({
    required PengaturSesi sesi,
    required bool pemilik,
  }) async {
    if (_sedangKeluar) return;
    final setuju = await tampilkanDialogKonfirmasiSarypos(
      context,
      judul: pemilik ? 'Keluar dari akun pemilik?' : 'Keluar dari akun?',
      pesan: pemilik
          ? 'Anda kembali ke mode karyawan/staff. Data toko tetap tersimpan.'
          : 'Anda perlu masuk lagi untuk mencatat transaksi atas nama akun ini.',
      labelLanjut: 'Keluar',
      destruktif: true,
    );
    if (!setuju || !mounted) return;

    setState(() => _sedangKeluar = true);
    final err = await sesi.keluar();
    if (!mounted) return;
    setState(() => _sedangKeluar = false);

    if (err != null) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: err,
      );
    } else {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: pemilik
            ? 'Anda kembali dalam mode karyawan/staff.'
            : 'Anda keluar dari akun.',
      );
    }
  }

  Widget _kartuMenu(List<Widget> anak) {
    return CardSarypos(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: anak,
      ),
    );
  }

  Widget _tileMenu({
    required IconData ikon,
    required String judul,
    String? subtitle,
    Color? warnaIkon,
    Color? warnaJudul,
    bool sedangMemuat = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      minVerticalPadding: 12,
      leading: sedangMemuat
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: warnaIkon ?? Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(ikon, color: warnaIkon),
      title: Text(
        judul,
        style: warnaJudul != null ? TextStyle(color: warnaJudul) : null,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: sedangMemuat
          ? null
          : const Icon(Icons.chevron_right_rounded),
      onTap: sedangMemuat ? null : onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesi = WarisanSesi.dari(context);
    final tema = Theme.of(context);
    final p = sesi.pengguna;
    final owner = p?.isOwner ?? false;

    return SafeArea(
      child: ListView(
        padding: InsetNavUtama.paddingKontenTab(context),
        children: [
          if (p != null) ...[
            CardSarypos(
              child: ListTile(
                minVerticalPadding: 12,
                leading: CircleAvatar(
                  backgroundColor: WarnaSarypos.deepTeal,
                  foregroundColor: tema.colorScheme.onTertiary,
                  child: Text(
                    p.namaLengkap.isNotEmpty
                        ? p.namaLengkap[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(p.namaLengkap),
                subtitle: Text(
                  '${p.email}\nPeran: ${p.peran == 'owner' ? 'Pemilik' : 'Karyawan'}',
                ),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (p != null && !owner) ...[
            CardSarypos(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PanelTransaksiTerakhirKaryawan(idPengguna: p.id),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!owner) ...[
            _kartuMenu([
              if (p == null)
                _tileMenu(
                  ikon: Icons.store_mall_directory_outlined,
                  judul: 'Masuk',
                  subtitle: 'Masuk sebagai pemilik atau karyawan',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HalamanLogin(pengatur: sesi, dariTabSaya: true),
                      ),
                    );
                  },
                ),
              if (p == null) const Divider(height: 1),
              _tileMenu(
                ikon: Icons.info_outline_rounded,
                judul: 'Tentang SaryPOS',
                subtitle: 'Profil aplikasi dan tim pengembang',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HalamanTentangSarypos(),
                    ),
                  );
                },
              ),
              if (p != null) ...[
                const Divider(height: 1),
                _tileMenu(
                  ikon: Icons.logout,
                  judul: 'Keluar dari akun',
                  subtitle: 'Anda keluar dari akun ini',
                  warnaIkon: tema.colorScheme.error,
                  warnaJudul: tema.colorScheme.error,
                  sedangMemuat: _sedangKeluar,
                  onTap: () => _keluarAkun(sesi: sesi, pemilik: false),
                ),
              ],
              if (sesi.adaOwnerAktif == false) ...[
                const Divider(height: 1),
                _tileMenu(
                  ikon: Icons.person_add_alt_1,
                  judul: 'Daftar pemilik toko (pertama kali)',
                  subtitle: 'Sekali saja. Setelahnya gunakan masuk pemilik.',
                  warnaIkon: tema.colorScheme.error,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HalamanDaftarOwner(pengatur: sesi),
                      ),
                    );
                  },
                ),
              ],
            ]),
            const SizedBox(height: 24),
          ],
          if (owner) ...[
            _kartuMenu([
              _tileMenu(
                ikon: Icons.info_outline_rounded,
                judul: 'Tentang SaryPOS',
                subtitle: 'Profil aplikasi dan tim pengembang',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HalamanTentangSarypos(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
            const JudulBagianSarypos(judul: 'Manajemen'),
            const SizedBox(height: 8),
            _kartuMenu([
              _tileMenu(
                ikon: Icons.assessment_outlined,
                judul: 'Laporan penjualan',
                subtitle: 'Periode & ekspor PDF',
                onTap: () {
                  dorongJikaOwner(
                    context,
                    (_) => const HalamanLaporanPenjualan(),
                  );
                },
              ),
              const Divider(height: 1),
              _tileMenu(
                ikon: Icons.groups_outlined,
                judul: 'Karyawan & HR',
                subtitle: 'Gaji, jadwal, foto, ID card',
                onTap: () {
                  dorongJikaOwner(
                    context,
                    (_) => const HalamanDaftarKaryawan(),
                  );
                },
              ),
              const Divider(height: 1),
              _tileMenu(
                ikon: Icons.history,
                judul: 'Log aktivitas',
                subtitle: 'Riwayat peristiwa penting di toko',
                onTap: () {
                  dorongJikaOwner(
                    context,
                    (_) => const HalamanLogAktivitas(),
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
            _kartuMenu([
              _tileMenu(
                ikon: Icons.logout,
                judul: 'Keluar dari akun pemilik',
                subtitle: 'Kembali ke mode karyawan/staff',
                warnaIkon: tema.colorScheme.error,
                warnaJudul: tema.colorScheme.error,
                sedangMemuat: _sedangKeluar,
                onTap: () => _keluarAkun(sesi: sesi, pemilik: true),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
