import 'dart:async';

import 'package:sarypos/data/sources/log_aktivitas_sumber.dart';

abstract class JenisLogAktivitas {
  static const login = 'login';
  static const logout = 'logout';
  static const registrasiOwner = 'registrasi_owner';
  static const transaksi = 'transaksi';
  static const ubahStok = 'ubah_stok';
  static const eksporPdf = 'ekspor_pdf';
  static const eksporCsv = 'ekspor_csv';
  static const karyawanTambah = 'karyawan_tambah';
  static const karyawanUbah = 'karyawan_ubah';
  static const karyawanStatus = 'karyawan_status';
  static const error = 'error';
}

final LogAktivitasSumber _sumberLog = LogAktivitasSumber();

void catatLogAktivitas({
  String? idPengguna,
  required String jenis,
  required String deskripsi,
  Map<String, dynamic>? metadataJson,
}) {
  unawaited(
    _sumberLog
        .sisipkan(
          idPengguna: idPengguna,
          jenis: jenis,
          deskripsi: deskripsi,
          metadataJson: metadataJson,
        )
        .catchError((Object _) {}),
  );
}
