import 'package:sarypos/data/models/transaksi_ringkas_model.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';

enum RentangLaporan { hariIni, mingguIni, bulanIni }

class RingkasanLaporanPenjualan {
  const RingkasanLaporanPenjualan({
    required this.jumlahTransaksi,
    required this.totalNilaiPenjualan,
    required this.transaksiRingkas,
  });

  final int jumlahTransaksi;
  final int totalNilaiPenjualan;
  final List<TransaksiRingkasModel> transaksiRingkas;
}

class LaporanSumber {
  (String awalUtc, String akhirUtc) batasUtcUntukRentang(
    RentangLaporan rentang,
  ) {
    final sekarang = DateTime.now();
    late final DateTime awalLokal;
    final DateTime akhirLokal;

    switch (rentang) {
      case RentangLaporan.hariIni:
        awalLokal = DateTime(sekarang.year, sekarang.month, sekarang.day);
        akhirLokal = awalLokal.add(const Duration(days: 1));
      case RentangLaporan.mingguIni:
        final hanyaHari = DateTime(sekarang.year, sekarang.month, sekarang.day);
        awalLokal = hanyaHari.subtract(Duration(days: sekarang.weekday - 1));
        akhirLokal = awalLokal.add(const Duration(days: 7));
      case RentangLaporan.bulanIni:
        awalLokal = DateTime(sekarang.year, sekarang.month, 1);
        akhirLokal = DateTime(sekarang.year, sekarang.month + 1, 1);
    }

    return (
      awalLokal.toUtc().toIso8601String(),
      akhirLokal.toUtc().toIso8601String(),
    );
  }

  Future<RingkasanLaporanPenjualan> ambilRingkasanPenjualan(
    RentangLaporan rentang,
  ) async {
    final (awalUtc, akhirUtc) = batasUtcUntukRentang(rentang);

    final hasil = await supabaseKlien
        .from('transaksi')
        .select(
          'id, waktu, total, metode_pembayaran, subtotal, potongan, '
          'pengguna(nama_lengkap)',
        )
        .gte('waktu', awalUtc)
        .lt('waktu', akhirUtc)
        .order('waktu', ascending: false);

    final baris = hasil as List<dynamic>;
    int totalNilai = 0;
    final listRingkas = <TransaksiRingkasModel>[];

    for (final row in baris) {
      final map = Map<String, dynamic>.from(row as Map);
      final m = TransaksiRingkasModel.dariBaris(map);
      totalNilai += m.total;
      listRingkas.add(m);
    }

    return RingkasanLaporanPenjualan(
      jumlahTransaksi: listRingkas.length,
      totalNilaiPenjualan: totalNilai,
      transaksiRingkas: listRingkas,
    );
  }

  Future<List<TransaksiRingkasModel>> ambilTransaksiTerbaruUntukPengguna({
    required String idPengguna,
    int batas = 8,
  }) async {
    final jumlah = batas.clamp(1, 50);
    final hasil = await supabaseKlien
        .from('transaksi')
        .select(
          'id, waktu, total, metode_pembayaran, subtotal, potongan, '
          'pengguna(nama_lengkap)',
        )
        .eq('id_pengguna', idPengguna)
        .order('waktu', ascending: false)
        .limit(jumlah);

    final baris = hasil as List<dynamic>;
    return baris
        .map(
          (row) => TransaksiRingkasModel.dariBaris(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}
