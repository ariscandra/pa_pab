import 'dart:typed_data';

import 'package:sarypos/core/logika_preview_produk_perhatian.dart';
import 'package:sarypos/data/models/produk_model.dart';
import 'package:sarypos/data/models/produk_inventaris_model.dart';
import 'package:sarypos/data/models/stok_model.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukDanStokSumber {
  static const String bucketGambarProduk = 'produk-gambar';

  static String _formatTanggalHariAman(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<String>> ambilDaftarKategoriUnik() async {
    final respons = await supabaseKlien.from('produk').select('kategori');
    final set = <String>{};
    for (final row in respons as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final k = map['kategori']?.toString().trim();
      if (k != null && k.isNotEmpty) {
        set.add(k);
      }
    }
    final daftar = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return daftar;
  }

  Future<List<ProdukModel>> ambilProdukAktif() async {
    final respons = await supabaseKlien
        .from('produk')
        .select()
        .eq('aktif', true)
        .order('nama');

    return (respons as List<dynamic>)
        .map((e) => ProdukModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StokModel>> ambilStokDenganProduk() async {
    final respons = await supabaseKlien
        .from('stok')
        .select('id, produk_id, jumlah, batas_kritis, produk (nama, aktif)')
        .order('id');

    return (respons as List<dynamic>)
        .map((row) {
          final data = row as Map<String, dynamic>;
          final produk = data['produk'] as Map<String, dynamic>?;

          if (!(produk?['aktif'] == true)) {
            return null;
          }

          return StokModel.fromJoinedMap({
            'id': data['id'],
            'produk_id': data['produk_id'],
            'jumlah': data['jumlah'],
            'batas_kritis': data['batas_kritis'],
            'produk_nama': produk?['nama'],
          });
        })
        .whereType<StokModel>()
        .toList();
  }

  Future<void> perbaruiJumlahStok({
    required String stokId,
    required int jumlahBaru,
  }) async {
    await supabaseKlien
        .from('stok')
        .update({'jumlah': jumlahBaru})
        .eq('id', stokId);
  }

  Future<List<ProdukInventarisModel>> ambilProdukInventaris({
    bool hanyaAktifProduk = true,
  }) async {
    final respons = await supabaseKlien
        .from('stok')
        .select(
          'id, produk_id, jumlah, batas_kritis, '
          'produk (id, nama, harga, aktif, kategori, tanggal_kadaluarsa, gambar_url)',
        )
        .order('produk_id');

    final list = (respons as List<dynamic>)
        .map((row) {
          final data = row as Map<String, dynamic>;
          final produkMap = data['produk'] as Map<String, dynamic>?;
          if (produkMap == null) return null;

          final produk = ProdukModel.fromMap(produkMap);
          if (hanyaAktifProduk && produk.aktif != true) {
            return null;
          }

          final stok = StokModel.fromJoinedMap({
            'id': data['id'],
            'produk_id': data['produk_id'],
            'jumlah': data['jumlah'],
            'batas_kritis': data['batas_kritis'],
            'produk_nama': produk.nama,
          });

          return ProdukInventarisModel(produk: produk, stok: stok);
        })
        .whereType<ProdukInventarisModel>()
        .toList();

    list.sort((a, b) => a.produk.nama.compareTo(b.produk.nama));
    return list;
  }

  Future<List<ProdukInventarisModel>> ambilPreviewProdukPerluPerhatian({
    int maks = 4,
  }) async {
    final semua = await ambilProdukInventaris(hanyaAktifProduk: true);
    return urutkanDanBatasiPreviewPerhatian(semua, maks: maks);
  }

  Future<ProdukInventarisModel?> ambilProdukInventarisByProdukId({
    required String produkId,
  }) async {
    final respons = await supabaseKlien
        .from('stok')
        .select(
          'id, produk_id, jumlah, batas_kritis, '
          'produk (id, nama, harga, aktif, kategori, tanggal_kadaluarsa, gambar_url)',
        )
        .eq('produk_id', produkId)
        .maybeSingle();

    if (respons == null) {
      return null;
    }

    final data = respons;
    final produkMap = data['produk'] as Map<String, dynamic>?;
    if (produkMap == null) {
      return null;
    }

    final produk = ProdukModel.fromMap(produkMap);
    final stok = StokModel.fromJoinedMap({
      'id': data['id'],
      'produk_id': data['produk_id'],
      'jumlah': data['jumlah'],
      'batas_kritis': data['batas_kritis'],
      'produk_nama': produk.nama,
    });

    return ProdukInventarisModel(produk: produk, stok: stok);
  }

  Future<String> _unggahGambarProduk({
    required String produkId,
    required Uint8List bytes,
    required String ekstensi,
  }) async {
    final path =
        '$produkId/foto_produk_${DateTime.now().millisecondsSinceEpoch}.$ekstensi';
    final mime = switch (ekstensi.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    await supabaseKlien.storage
        .from(bucketGambarProduk)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mime),
        );
    return supabaseKlien.storage.from(bucketGambarProduk).getPublicUrl(path);
  }

  Future<void> _hapusGambarProdukDariUrl(String? gambarUrl) async {
    if (gambarUrl == null || gambarUrl.isEmpty) return;

    final prefix = '/storage/v1/object/public/$bucketGambarProduk/';
    final i = gambarUrl.indexOf(prefix);
    if (i == -1) return;
    final path = gambarUrl.substring(i + prefix.length);
    try {
      await supabaseKlien.storage.from(bucketGambarProduk).remove([path]);
    } catch (_) {}
  }

  Future<String> buatProduk({
    required String nama,
    required int harga,
    required bool aktif,
    required String kategori,
    required DateTime tanggalKadaluarsa,
    required int stokJumlah,
    required int batasKritis,
    Uint8List? gambarBytes,
    String? gambarEkstensi,
  }) async {
    final barisProduk = await supabaseKlien
        .from('produk')
        .insert({
          'nama': nama.trim(),
          'harga': harga.toDouble(),
          'aktif': aktif,
          'kategori': kategori.trim().isEmpty ? null : kategori.trim(),
          'tanggal_kadaluarsa': _formatTanggalHariAman(tanggalKadaluarsa),
          'gambar_url': null,
        })
        .select()
        .single();

    final produkId = barisProduk['id']?.toString() ?? '';
    if (produkId.isEmpty) {
      throw Exception('Pembuatan produk gagal (id kosong).');
    }

    await supabaseKlien.from('stok').upsert({
      'produk_id': produkId,
      'jumlah': stokJumlah,
      'batas_kritis': batasKritis,
    }, onConflict: 'produk_id');

    if (gambarBytes != null && gambarEkstensi != null) {
      final url = await _unggahGambarProduk(
        produkId: produkId,
        bytes: gambarBytes,
        ekstensi: gambarEkstensi,
      );
      await supabaseKlien
          .from('produk')
          .update({'gambar_url': url})
          .eq('id', produkId);
    }

    return produkId;
  }

  Future<void> ubahProduk({
    required String produkId,
    required String nama,
    required int harga,
    required bool aktif,
    required String kategori,
    required DateTime tanggalKadaluarsa,
    required int stokJumlah,
    required int batasKritis,
    Uint8List? gambarBytes,
    String? gambarEkstensi,
    String? gambarUrlLama,
  }) async {
    String? gambarUrlBaru;
    if (gambarBytes != null && gambarEkstensi != null) {
      if (gambarUrlLama != null) {
        await _hapusGambarProdukDariUrl(gambarUrlLama);
      }
      gambarUrlBaru = await _unggahGambarProduk(
        produkId: produkId,
        bytes: gambarBytes,
        ekstensi: gambarEkstensi,
      );
    }

    final mapProduk = <String, dynamic>{
      'nama': nama.trim(),
      'harga': harga.toDouble(),
      'aktif': aktif,
      'kategori': kategori.trim().isEmpty ? null : kategori.trim(),
      'tanggal_kadaluarsa': _formatTanggalHariAman(tanggalKadaluarsa),
    };
    if (gambarUrlBaru != null) {
      mapProduk['gambar_url'] = gambarUrlBaru;
    }

    await supabaseKlien.from('produk').update(mapProduk).eq('id', produkId);

    await supabaseKlien.from('stok').upsert({
      'produk_id': produkId,
      'jumlah': stokJumlah,
      'batas_kritis': batasKritis,
    }, onConflict: 'produk_id');
  }

  Future<void> nonaktifkanProduk({required String produkId}) async {
    await supabaseKlien
        .from('produk')
        .update({'aktif': false})
        .eq('id', produkId);
  }

  Future<void> kurangiStokSetelahPenjualan({
    required String produkId,
    required int kuantitasTerjual,
  }) async {
    if (kuantitasTerjual <= 0) return;

    final baris = await supabaseKlien
        .from('stok')
        .select('id, jumlah')
        .eq('produk_id', produkId)
        .maybeSingle();

    if (baris == null) return;

    final jumlahSekarang = _parseIntAman(baris['jumlah']);
    final jumlahBaru = (jumlahSekarang - kuantitasTerjual).clamp(0, 1 << 30);

    await supabaseKlien
        .from('stok')
        .update({'jumlah': jumlahBaru})
        .eq('id', baris['id'].toString());
  }

  static int _parseIntAman(dynamic nilai) {
    return switch (nilai) {
      int i => i,
      num n => n.round(),
      String s => int.tryParse(s.split('.').first) ?? 0,
      _ => 0,
    };
  }
}
