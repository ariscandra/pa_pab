import 'package:sarypos/data/models/karyawan_lengkap_model.dart';
import 'package:sarypos/data/models/pengguna_model.dart';
import 'package:sarypos/data/sources/profil_karyawan_sumber.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';

class PenggunaSumber {
  Future<bool> apakahAdaOwnerAktif() async {
    final hasil = await supabaseKlien
        .from('pengguna')
        .select('id')
        .eq('peran', 'owner')
        .eq('aktif', true)
        .limit(1);
    return (hasil as List<dynamic>).isNotEmpty;
  }

  Future<PenggunaModel?> ambilPenggunaDariIdAuth(String idAuth) async {
    final baris = await supabaseKlien
        .from('pengguna')
        .select()
        .eq('id_auth', idAuth)
        .maybeSingle();

    if (baris == null) {
      return null;
    }
    return PenggunaModel.dariBaris(Map<String, dynamic>.from(baris));
  }

  Future<PenggunaModel> sisipkanPengguna({
    required String idAuth,
    required String namaLengkap,
    required String email,
    required String peran,
    bool aktif = true,
    String? sandiLogin,
  }) async {
    if (peran == 'owner' && aktif) {
      final sudah = await apakahAdaOwnerAktif();
      if (sudah) {
        throw Exception(
          'Sudah ada pemilik aktif. Tidak dapat menambah owner kedua.',
        );
      }
    }
    final baris = await supabaseKlien
        .from('pengguna')
        .insert({
          'id_auth': idAuth,
          'nama_lengkap': namaLengkap,
          'email': email,
          'peran': peran,
          'aktif': aktif,
          'sandi_login': sandiLogin,
        })
        .select()
        .single();
    return PenggunaModel.dariBaris(Map<String, dynamic>.from(baris));
  }

  Future<List<KaryawanLengkapModel>> ambilKaryawanDenganProfil() async {
    final daftar = await ambilDaftarKaryawan();
    final profilSumber = ProfilKaryawanSumber();
    final out = <KaryawanLengkapModel>[];
    for (final p in daftar) {
      final profil = await profilSumber.ambilUntukPengguna(p.id);
      out.add(KaryawanLengkapModel(pengguna: p, profil: profil));
    }
    return out;
  }

  Future<List<PenggunaModel>> ambilDaftarKaryawan() async {
    final hasil = await supabaseKlien
        .from('pengguna')
        .select()
        .eq('peran', 'karyawan')
        .order('nama_lengkap');

    final list = hasil as List<dynamic>;
    return list
        .map(
          (e) => PenggunaModel.dariBaris(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> perbaruiNama({
    required String idPengguna,
    required String namaLengkap,
  }) async {
    await supabaseKlien
        .from('pengguna')
        .update({'nama_lengkap': namaLengkap})
        .eq('id', idPengguna);
  }

  Future<void> ubahStatusAktif({
    required String idPengguna,
    required bool aktif,
  }) async {
    await supabaseKlien
        .from('pengguna')
        .update({'aktif': aktif})
        .eq('id', idPengguna);
  }

  Future<void> perbaruiEmailDanSandiLogin({
    required String idPengguna,
    required String email,
    required String sandiLogin,
  }) async {
    await supabaseKlien
        .from('pengguna')
        .update({'email': email, 'sandi_login': sandiLogin})
        .eq('id', idPengguna);
  }

  Future<void> perbaruiIdAuth({
    required String idPengguna,
    required String idAuthBaru,
  }) async {
    await supabaseKlien
        .from('pengguna')
        .update({'id_auth': idAuthBaru})
        .eq('id', idPengguna);
  }
}
