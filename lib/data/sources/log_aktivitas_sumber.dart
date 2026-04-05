import 'package:sarypos/data/models/log_aktivitas_model.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';

class LogAktivitasSumber {
  Future<void> sisipkan({
    String? idPengguna,
    required String jenis,
    required String deskripsi,
    Map<String, dynamic>? metadataJson,
  }) async {
    await supabaseKlien.from('log_aktivitas').insert({
      'id_pengguna': idPengguna,
      'jenis': jenis,
      'deskripsi': deskripsi,
      'metadata_json': metadataJson,
    });
  }

  Future<List<LogAktivitasModel>> ambilTerbaru({int batas = 50}) async {
    final hasil = await supabaseKlien
        .from('log_aktivitas')
        .select()
        .order('waktu', ascending: false)
        .limit(batas);

    final list = hasil as List<dynamic>;
    return list
        .map(
          (e) =>
              LogAktivitasModel.dariBaris(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<LogAktivitasModel>> ambilTerbaruUntukBeranda({
    required bool untukPemilik,
    int batas = 3,
  }) async {
    final jumlah = batas.clamp(2, 8);
    var kueri = supabaseKlien.from('log_aktivitas').select();
    if (!untukPemilik) {
      kueri = kueri.inFilter('jenis', const [
        'transaksi',
        'ubah_stok',
        'error',
      ]);
    }
    final hasil = await kueri.order('waktu', ascending: false).limit(jumlah);

    final list = hasil as List<dynamic>;
    return list
        .map(
          (e) =>
              LogAktivitasModel.dariBaris(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
