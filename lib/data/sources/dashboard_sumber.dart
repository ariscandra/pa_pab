import 'package:sarypos/data/sources/supabase_klien.dart';

class RingkasanDashboardHariIni {
  const RingkasanDashboardHariIni({
    required this.totalPenjualan,
    required this.jumlahTransaksi,
  });

  final int totalPenjualan;
  final int jumlahTransaksi;
}

class DashboardSumber {
  Future<RingkasanDashboardHariIni> ambilRingkasanHariIni() async {
    final sekarang = DateTime.now();
    final awalHariLokal = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final akhirHariLokal = awalHariLokal.add(const Duration(days: 1));
    final awalUtc = awalHariLokal.toUtc().toIso8601String();
    final akhirUtc = akhirHariLokal.toUtc().toIso8601String();

    final transaksiHariIni = await supabaseKlien
        .from('transaksi')
        .select('total, waktu')
        .gte('waktu', awalUtc)
        .lt('waktu', akhirUtc);

    int totalPenjualan = 0;
    int jumlahTransaksi = 0;

    for (final row in (transaksiHariIni as List<dynamic>)) {
      final data = row as Map<String, dynamic>;
      final dynamic nilaiTotal = data['total'];
      final intTotal = switch (nilaiTotal) {
        num n => n.round(),
        String s => int.tryParse(s.split('.').first) ?? 0,
        _ => 0,
      };
      totalPenjualan += intTotal;
      jumlahTransaksi += 1;
    }

    return RingkasanDashboardHariIni(
      totalPenjualan: totalPenjualan,
      jumlahTransaksi: jumlahTransaksi,
    );
  }
}
