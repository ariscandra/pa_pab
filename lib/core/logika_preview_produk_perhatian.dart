import 'package:sarypos/data/models/produk_inventaris_model.dart';

bool kadaluarsaDalam7HariInventaris(ProdukInventarisModel m) {
  final tgl = m.produk.tanggalKadaluarsa;
  if (tgl == null) return false;
  final now = DateTime.now();
  final awal = DateTime(now.year, now.month, now.day);
  final akhir = awal.add(const Duration(days: 7));
  return (tgl.isAtSameMomentAs(awal) || tgl.isAfter(awal)) &&
      (tgl.isAtSameMomentAs(akhir) || tgl.isBefore(akhir));
}

bool produkPerluPerhatianInventaris(ProdukInventarisModel m) {
  if (m.produk.aktif != true) return false;
  if (m.stok.jumlah <= 0) return true;
  if (m.stok.jumlah <= m.stok.batasKritis) return true;
  return kadaluarsaDalam7HariInventaris(m);
}

int _skorPrioritasPerhatian(ProdukInventarisModel m) {
  var s = 0;
  if (m.stok.jumlah <= 0) {
    s += 10000;
  } else if (m.stok.jumlah <= m.stok.batasKritis) {
    s += 1000;
  }
  final t = m.produk.tanggalKadaluarsa;
  if (t != null) {
    final now = DateTime.now();
    final awal = DateTime(now.year, now.month, now.day);
    final akhir = awal.add(const Duration(days: 7));
    final dalam7 =
        (t.isAtSameMomentAs(awal) || t.isAfter(awal)) &&
        (t.isAtSameMomentAs(akhir) || t.isBefore(akhir));
    if (dalam7) {
      s += 500;
      s -= t.difference(awal).inDays.clamp(0, 7);
    }
  }
  return s;
}

List<ProdukInventarisModel> urutkanDanBatasiPreviewPerhatian(
  List<ProdukInventarisModel> semua, {
  int maks = 4,
}) {
  final l = semua.where(produkPerluPerhatianInventaris).toList();
  l.sort(
    (a, b) => _skorPrioritasPerhatian(b).compareTo(_skorPrioritasPerhatian(a)),
  );
  if (l.length > maks) {
    return l.sublist(0, maks);
  }
  return l;
}
