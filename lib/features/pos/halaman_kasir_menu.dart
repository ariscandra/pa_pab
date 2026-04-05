import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/penjaga_aksi_masuk.dart';
import 'package:sarypos/features/pos/halaman_pencatatan_transaksi.dart';
import 'package:sarypos/features/produk/halaman_daftar_produk.dart';
import 'package:sarypos/widgets/card_sarypos.dart';

class HalamanKasirMenu extends StatelessWidget {
  const HalamanKasirMenu({super.key});

  Widget _kartu(
    BuildContext context, {
    required String judul,
    required String subjudul,
    required IconData ikon,
    required Color warnaAksen,
    required VoidCallback onTap,
  }) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final warnaIkon = gelap && warnaAksen == WarnaSarypos.deepTeal
        ? warnaAksenJudulBagian(context)
        : warnaAksen;

    return CardSarypos(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warnaIkon.withValues(alpha: gelap ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warnaIkon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subjudul,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _kartu(
            context,
            judul: 'Manajemen Produk',
            subjudul: 'Tambah, ubah, nonaktifkan produk dan stok.',
            ikon: Icons.inventory_2_outlined,
            warnaAksen: WarnaSarypos.deepTeal,
            onTap: () {
              if (cegahJikaBelumLogin(
                context,
                pesan:
                    'Masuk ke akun terlebih dahulu untuk mengelola produk.',
              )) {
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HalamanDaftarProduk(),
                ),
              );
            },
          ),
          _kartu(
            context,
            judul: 'Pencatatan Transaksi',
            subjudul: 'Buka POS untuk input transaksi.',
            ikon: Icons.shopping_cart_outlined,
            warnaAksen: WarnaSarypos.saryRed,
            onTap: () {
              if (cegahJikaBelumLogin(
                context,
                pesan:
                    'Masuk ke akun terlebih dahulu untuk mencatat transaksi.',
              )) {
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HalamanPencatatanTransaksi(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
