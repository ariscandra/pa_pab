import 'package:sarypos/data/models/item_keranjang.dart';
import 'package:sarypos/data/sources/produk_dan_stok_sumber.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';

class TransaksiSumber {
  final ProdukDanStokSumber _stokSumber = ProdukDanStokSumber();

  Future<String?> simpanTransaksi({
    String? idPengguna,
    required List<ItemKeranjang> itemKeranjang,
    required String metodePembayaran,
    int? totalAkhir,
  }) async {
    if (itemKeranjang.isEmpty) {
      return null;
    }

    final subtotal = itemKeranjang.fold<int>(
      0,
      (sebelumnya, item) => sebelumnya + item.subtotal,
    );
    final total = totalAkhir ?? subtotal;
    if (total < 0 || total > subtotal) {
      throw ArgumentError(
        'totalAkhir harus antara 0 dan subtotal ($subtotal), dapat: $total',
      );
    }
    final potongan = subtotal - total;

    final barisTransaksi = <String, dynamic>{
      'waktu': DateTime.now().toUtc().toIso8601String(),
      'subtotal': subtotal,
      'potongan': potongan,
      'total': total,
      'metode_pembayaran': metodePembayaran,
    };
    if (idPengguna != null) {
      barisTransaksi['id_pengguna'] = idPengguna;
    }

    final responsTransaksi = await supabaseKlien
        .from('transaksi')
        .insert(barisTransaksi)
        .select('id')
        .single();

    final transaksiId = responsTransaksi['id']?.toString();

    final detail = itemKeranjang
        .map(
          (item) => {
            'transaksi_id': transaksiId,
            'produk_id': item.produk.id,
            'kuantitas': item.kuantitas,
            'harga_saat_transaksi': item.produk.harga,
          },
        )
        .toList();

    await supabaseKlien.from('detail_transaksi').insert(detail);

    for (final item in itemKeranjang) {
      await _stokSumber.kurangiStokSetelahPenjualan(
        produkId: item.produk.id,
        kuantitasTerjual: item.kuantitas,
      );
    }

    return transaksiId;
  }
}
