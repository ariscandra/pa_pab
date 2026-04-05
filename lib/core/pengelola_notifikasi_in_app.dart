import 'dart:async';

import 'package:flutter/foundation.dart';

enum TipeNotifikasiInApp { sukses, info, peringatan, error }

class ItemNotifikasiInApp {
  const ItemNotifikasiInApp({
    required this.id,
    required this.tipe,
    required this.pesan,
  });

  final String id;
  final TipeNotifikasiInApp tipe;
  final String pesan;
}

class PengelolaNotifikasiInApp extends ChangeNotifier {
  ItemNotifikasiInApp? _aktif;
  Timer? _timer;
  String? _pesanTerakhir;
  DateTime? _waktuPesanTerakhir;

  ItemNotifikasiInApp? get aktif => _aktif;

  void tampilkan({
    required TipeNotifikasiInApp tipe,
    required String pesan,
    Duration durasi = const Duration(seconds: 4),
  }) {
    final sekarang = DateTime.now();
    if (_pesanTerakhir == pesan &&
        _waktuPesanTerakhir != null &&
        sekarang.difference(_waktuPesanTerakhir!) <
            const Duration(seconds: 2)) {
      return;
    }
    _pesanTerakhir = pesan;
    _waktuPesanTerakhir = sekarang;

    _timer?.cancel();
    _aktif = ItemNotifikasiInApp(
      id: '${sekarang.microsecondsSinceEpoch}',
      tipe: tipe,
      pesan: pesan,
    );
    notifyListeners();

    _timer = Timer(durasi, () {
      _aktif = null;
      notifyListeners();
    });
  }

  void tutup() {
    _timer?.cancel();
    _aktif = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
