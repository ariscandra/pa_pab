import 'produk_model.dart';

class ItemKeranjang {
  ItemKeranjang({required this.produk, required this.kuantitas});

  final ProdukModel produk;
  int kuantitas;

  int get subtotal => produk.harga * kuantitas;
}
