class StokModel {
  const StokModel({
    required this.id,
    required this.produkId,
    required this.namaProduk,
    required this.jumlah,
    required this.batasKritis,
  });

  final String id;
  final String produkId;
  final String namaProduk;
  final int jumlah;
  final int batasKritis;

  factory StokModel.fromJoinedMap(Map<String, dynamic> data) {
    return StokModel(
      id: data['id']?.toString() ?? '',
      produkId: data['produk_id']?.toString() ?? '',
      namaProduk: data['produk_nama'] as String? ?? '',
      jumlah: _parseInt(data['jumlah']),
      batasKritis: _parseInt(data['batas_kritis']),
    );
  }

  static int _parseInt(dynamic nilai) {
    return switch (nilai) {
      int i => i,
      num n => n.round(),
      String s => int.tryParse(s.split('.').first) ?? 0,
      _ => 0,
    };
  }
}
