import 'package:flutter/material.dart';
import 'package:sarypos/core/penjaga_aksi_masuk.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/features/pos/halaman_pos.dart';
import 'package:sarypos/features/produk/halaman_daftar_produk.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';

class HalamanKasirTab extends StatelessWidget {
  const HalamanKasirTab({
    super.key,
    this.onMintaTabSaya,
  });

  final VoidCallback? onMintaTabSaya;

  @override
  Widget build(BuildContext context) {
    final sesi = WarisanSesi.dari(context);
    if (sesi.sedangMemeriksaSesi) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sesi.pengguna == null) {
      return EmptyStateGenerik(
        ikon: Icons.point_of_sale_outlined,
        judul: 'Masuk untuk POS',
        pesan:
            'Akun diperlukan agar transaksi tercatat dengan benar di sistem.',
        labelTombol: 'Ke tab Saya',
        onTekanTombol: onMintaTabSaya,
      );
    }
    return const HalamanPos();
  }
}

void bukaManajemenProdukDariKasir(BuildContext context) {
  if (cegahJikaBelumLogin(
    context,
    pesan: 'Masuk ke akun terlebih dahulu untuk mengelola produk.',
  )) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const HalamanDaftarProduk()),
  );
}
