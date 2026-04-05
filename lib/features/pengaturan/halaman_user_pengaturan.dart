import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
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
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanUserPengaturan extends StatelessWidget {
  const HalamanUserPengaturan({super.key});

  @override
  Widget build(BuildContext context) {
    final sesi = WarisanSesi.dari(context);
    final tema = Theme.of(context);
    final p = sesi.pengguna;
    final owner = p?.isOwner ?? false;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p != null) ...[
            CardSarypos(
              child: ListTile(
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
            if (p == null) ...[
              ListTile(
                leading: const Icon(Icons.store_mall_directory_outlined),
                title: const Text('Masuk'),
                subtitle: const Text('Masuk sebagai pemilik atau karyawan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          HalamanLogin(pengatur: sesi, dariTabSaya: true),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Tentang SaryPOS'),
              subtitle: const Text('Profil aplikasi dan tim pengembang'),
              trailing: const Icon(Icons.chevron_right),
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
              ListTile(
                leading: Icon(Icons.logout, color: tema.colorScheme.error),
                title: Text(
                  'Keluar Dari Akun',
                  style: TextStyle(color: tema.colorScheme.error),
                ),
                subtitle: const Text('Anda keluar dari akun ini.'),
                onTap: () async {
                  final err = await sesi.keluar();
                  if (!context.mounted) {
                    return;
                  }
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
                      pesan: 'Anda keluar dari akun.',
                    );
                  }
                },
              ),
            ],
            if (sesi.adaOwnerAktif == false)
              ListTile(
                leading: Icon(
                  Icons.person_add_alt_1,
                  color: tema.colorScheme.error,
                ),
                title: const Text('Daftar Pemilik Toko (Pertama Kali)'),
                subtitle: const Text(
                  'Sekali saja. Setelahnya gunakan masuk pemilik.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HalamanDaftarOwner(pengatur: sesi),
                    ),
                  );
                },
              ),
            const Divider(height: 32),
          ],
          if (owner) ...[
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Tentang SaryPOS'),
              subtitle: const Text('Profil aplikasi dan tim pengembang'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HalamanTentangSarypos(),
                  ),
                );
              },
            ),
            const Divider(height: 24),
          ],
          if (owner) ...[
            Text(
              'Manajemen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: warnaAksenJudulBagian(context),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Laporan Penjualan'),
              subtitle: const Text('Periode & ekspor PDF'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                dorongJikaOwner(
                  context,
                  (_) => const HalamanLaporanPenjualan(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Karyawan & HR'),
              subtitle: const Text('Gaji, jadwal, foto, ID card'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                dorongJikaOwner(context, (_) => const HalamanDaftarKaryawan());
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Log Aktivitas'),
              subtitle: const Text('Riwayat peristiwa penting di toko'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                dorongJikaOwner(context, (_) => const HalamanLogAktivitas());
              },
            ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(Icons.logout, color: tema.colorScheme.error),
              title: Text(
                'Keluar Dari Akun Pemilik',
                style: TextStyle(color: tema.colorScheme.error),
              ),
              subtitle: const Text(
                'Kembali ke mode karyawan/staff, data toko tetap ada.',
              ),
              onTap: () async {
                final err = await sesi.keluar();
                if (!context.mounted) {
                  return;
                }
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
                    pesan: 'Anda kembali dalam mode karyawan/staff.',
                  );
                }
              },
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
