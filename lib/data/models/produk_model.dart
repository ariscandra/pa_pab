class ProdukModel {
  const ProdukModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.aktif,
    this.kategori,
    this.tanggalKadaluarsa,
    this.gambarUrl,
  });

  final String id;
  final String nama;
  final int harga;
  final bool aktif;

  final String? kategori;
  final DateTime? tanggalKadaluarsa;
  final String? gambarUrl;

  factory ProdukModel.fromMap(Map<String, dynamic> data) {
    final dynamic hargaMentah = data['harga'];
    final intHarga = switch (hargaMentah) {
      num n => n.round(),
      String s => int.tryParse(s.split('.').first) ?? 0,
      _ => 0,
    };

    String? kategori = data['kategori']?.toString();
    if (kategori != null && kategori.trim().isEmpty) {
      kategori = null;
    }

    DateTime? tanggalKadaluarsa;
    final rawTgl = data['tanggal_kadaluarsa'];
    if (rawTgl is String && rawTgl.isNotEmpty) {
      final parts = rawTgl.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          tanggalKadaluarsa = DateTime(y, m, d);
        } else {
          tanggalKadaluarsa = DateTime.tryParse(rawTgl);
        }
      } else {
        tanggalKadaluarsa = DateTime.tryParse(rawTgl);
      }
    } else if (rawTgl is DateTime) {
      tanggalKadaluarsa = rawTgl;
    }

    return ProdukModel(
      id: data['id']?.toString() ?? '',
      nama: data['nama'] as String? ?? '',
      harga: intHarga,
      aktif: data['aktif'] as bool? ?? true,
      kategori: kategori,
      tanggalKadaluarsa: tanggalKadaluarsa,
      gambarUrl: data['gambar_url']?.toString(),
    );
  }
}
