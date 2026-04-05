import 'package:sarypos/data/models/produk_model.dart';
import 'package:sarypos/data/models/stok_model.dart';

class ProdukInventarisModel {
  const ProdukInventarisModel({required this.produk, required this.stok});

  final ProdukModel produk;
  final StokModel stok;
}
