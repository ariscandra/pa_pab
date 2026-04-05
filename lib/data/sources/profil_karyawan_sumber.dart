import 'dart:typed_data';

import 'package:sarypos/data/models/profil_karyawan_model.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilKaryawanSumber {
  static const String bucketFoto = 'karyawan-foto';

  Future<ProfilKaryawanModel?> ambilUntukPengguna(String penggunaId) async {
    final row = await supabaseKlien
        .from('profil_karyawan')
        .select()
        .eq('pengguna_id', penggunaId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return ProfilKaryawanModel.dariBaris(Map<String, dynamic>.from(row));
  }

  Future<void> pastikanBarisKosong(String penggunaId) async {
    final ada = await ambilUntukPengguna(penggunaId);
    if (ada != null) {
      return;
    }
    await supabaseKlien.from('profil_karyawan').insert({
      'pengguna_id': penggunaId,
    });
  }

  Future<void> simpanProfil(ProfilKaryawanModel model) async {
    await supabaseKlien
        .from('profil_karyawan')
        .upsert(model.keMapUpsert(), onConflict: 'pengguna_id');
  }

  Future<String> unggahFoto({
    required String penggunaId,
    required List<int> bytes,
    required String ekstensi,
  }) async {
    final path =
        '$penggunaId/foto_${DateTime.now().millisecondsSinceEpoch}.$ekstensi';
    final mime = switch (ekstensi.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    await supabaseKlien.storage
        .from(bucketFoto)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(upsert: true, contentType: mime),
        );
    return supabaseKlien.storage.from(bucketFoto).getPublicUrl(path);
  }

  Future<void> hapusFotoDariUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    final prefix = '/storage/v1/object/public/$bucketFoto/';
    final i = url.indexOf(prefix);
    if (i == -1) {
      return;
    }
    final path = url.substring(i + prefix.length);
    try {
      await supabaseKlien.storage.from(bucketFoto).remove([path]);
    } catch (_) {}
  }
}
