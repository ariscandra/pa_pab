class ProfilKaryawanModel {
  const ProfilKaryawanModel({
    required this.id,
    required this.penggunaId,
    this.gajiBulanan,
    this.tanggalMulaiKerja,
    this.hariGajian,
    this.fotoUrl,
    this.jabatan,
    this.ingatkanBonus = false,
    this.catatan,
  });

  final String id;
  final String penggunaId;
  final int? gajiBulanan;
  final DateTime? tanggalMulaiKerja;
  final int? hariGajian;
  final String? fotoUrl;
  final String? jabatan;
  final bool ingatkanBonus;
  final String? catatan;

  factory ProfilKaryawanModel.kosong(String penggunaId) {
    return ProfilKaryawanModel(id: '', penggunaId: penggunaId);
  }

  factory ProfilKaryawanModel.dariBaris(Map<String, dynamic> row) {
    DateTime? tmk;
    final rawTmk = row['tanggal_mulai_kerja'];
    if (rawTmk is String && rawTmk.isNotEmpty) {
      tmk = DateTime.tryParse(rawTmk);
    }

    int? gaji;
    final g = row['gaji_bulanan'];
    if (g != null) {
      gaji = switch (g) {
        int i => i,
        num n => n.round(),
        String s => int.tryParse(s.split('.').first),
        _ => null,
      };
    }

    int? hg = row['hari_gajian'] as int?;
    if (hg == null && row['hari_gajian'] != null) {
      hg = int.tryParse(row['hari_gajian'].toString());
    }

    return ProfilKaryawanModel(
      id: row['id'].toString(),
      penggunaId: row['pengguna_id'].toString(),
      gajiBulanan: gaji,
      tanggalMulaiKerja: tmk,
      hariGajian: hg,
      fotoUrl: row['foto_url']?.toString(),
      jabatan: row['jabatan']?.toString(),
      ingatkanBonus: row['ingatkan_bonus'] == true,
      catatan: row['catatan']?.toString(),
    );
  }

  Map<String, dynamic> keMapUpsert() {
    final j = jabatan?.trim();
    final c = catatan?.trim();
    return {
      'pengguna_id': penggunaId,
      'gaji_bulanan': gajiBulanan?.toDouble(),
      'tanggal_mulai_kerja': tanggalMulaiKerja
          ?.toIso8601String()
          .split('T')
          .first,
      'hari_gajian': hariGajian,
      'foto_url': fotoUrl,
      'jabatan': (j == null || j.isEmpty) ? null : j,
      'ingatkan_bonus': ingatkanBonus,
      'catatan': (c == null || c.isEmpty) ? null : c,
      'diperbarui_pada': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
