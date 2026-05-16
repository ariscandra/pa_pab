import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/penjaga_aksi_masuk.dart';
import 'package:sarypos/features/pos/halaman_pencatatan_transaksi.dart';
import 'package:sarypos/features/produk/halaman_daftar_produk.dart';
import 'package:sarypos/widgets/card_sarypos.dart';

class HalamanKasirMenu extends StatelessWidget {
  const HalamanKasirMenu({super.key});

  Widget _kartuUtama(
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    final skema = Theme.of(context).colorScheme;
    return CardSarypos(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [WarnaSarypos.saryRed, WarnaSarypos.saryGold],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: skema.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka POS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Catat transaksi penjualan sekarang.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: skema.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: skema.primary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuSekunder(
    BuildContext context, {
    required String judul,
    required String subjudul,
    required IconData ikon,
    required VoidCallback onTap,
  }) {
    final warnaIkon = warnaAksenJudulBagian(context);
    return CardSarypos(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      tampilkanKonturTipis: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: warnaIkon.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warnaIkon, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      subjudul,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _bukaPos(BuildContext context) {
    if (cegahJikaBelumLogin(
      context,
      pesan: 'Masuk ke akun terlebih dahulu untuk mencatat transaksi.',
    )) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HalamanPencatatanTransaksi(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _kartuUtama(context, onTap: () => _bukaPos(context)),
          Text(
            'Lainnya',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _kartuSekunder(
            context,
            judul: 'Manajemen Produk',
            subjudul: 'Tambah, ubah, atau nonaktifkan produk.',
            ikon: Icons.inventory_2_outlined,
            onTap: () {
              if (cegahJikaBelumLogin(
                context,
                pesan: 'Masuk ke akun terlebih dahulu untuk mengelola produk.',
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
        ],
      ),
    );
  }
}
