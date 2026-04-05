import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/data/models/pengguna_model.dart';
import 'package:sarypos/data/sources/pengguna_sumber.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';

class PengaturSesi extends ChangeNotifier {
  PengaturSesi() {
    _inisialisasi();
  }

  static const int _maksPercobaanMuatSesi = 3;
  static const Duration _timeoutPercobaanMuatSesi = Duration(seconds: 5);

  static const _kunciPrefLanjutKasir = 'sarypos_lanjut_tanpa_owner';

  final PenggunaSumber _penggunaSumber = PenggunaSumber();

  PenggunaModel? _pengguna;
  bool _sedangMemeriksaSesi = true;
  bool? _adaOwnerAktif;
  bool _lanjutKasirTanpaOwner = false;
  String? _pesanErrorSesi;

  int _versiTransaksiTerakhir = 0;

  PenggunaModel? get pengguna => _pengguna;
  bool get sedangMemeriksaSesi => _sedangMemeriksaSesi;
  bool? get adaOwnerAktif => _adaOwnerAktif;
  bool get sedangMengalamiError => _pesanErrorSesi != null;
  String? get pesanErrorSesi => _pesanErrorSesi;
  int get versiTransaksiTerakhir => _versiTransaksiTerakhir;

  bool get perluHalamanPembukaOwner =>
      _adaOwnerAktif == false && _pengguna == null && !_lanjutKasirTanpaOwner;

  Future<void> _inisialisasi() async {
    try {
      _pesanErrorSesi = null;

      _adaOwnerAktif = await _jalankanDenganTimeoutDanRetry(
        () => _penggunaSumber.apakahAdaOwnerAktif(),
        deskripsi: 'memeriksa pemilik aktif',
      );

      if (_adaOwnerAktif == false) {
        final p = await SharedPreferences.getInstance();
        _lanjutKasirTanpaOwner = p.getBool(_kunciPrefLanjutKasir) ?? false;
      }

      await perbaruiDariAuth();
    } catch (e) {
      _pengguna = null;
      _pesanErrorSesi = _formatPesanErrorKoneksi(e);
    } finally {
      _sedangMemeriksaSesi = false;
      notifyListeners();
    }
  }

  Future<T> _jalankanDenganTimeoutDanRetry<T>(
    Future<T> Function() operasi, {
    required String deskripsi,
  }) async {
    Object? kesalahanTerakhir;
    for (var percobaan = 1; percobaan <= _maksPercobaanMuatSesi; percobaan++) {
      try {
        return await operasi().timeout(
          _timeoutPercobaanMuatSesi,
          onTimeout: () {
            throw TimeoutException(
              'Timeout memuat sesi saat $deskripsi (percobaan $percobaan).',
            );
          },
        );
      } catch (e) {
        kesalahanTerakhir = e;
      }

      if (percobaan < _maksPercobaanMuatSesi) {
        await Future<void>.delayed(Duration(milliseconds: 350 * percobaan));
      }
    }

    throw kesalahanTerakhir ??
        Exception('Gagal memuat sesi karena koneksi bermasalah.');
  }

  String _formatPesanErrorKoneksi(Object e) {
    if (e is TimeoutException) {
      return 'Koneksi ke server memakan waktu terlalu lama. Periksa internet Anda, lalu coba lagi.';
    }

    final teks = e.toString().toLowerCase();
    final kemungkinanKoneksi =
        teks.contains('socket') ||
        teks.contains('http') ||
        teks.contains('failed') ||
        teks.contains('network') ||
        teks.contains('timeout') ||
        teks.contains('connection');

    if (kemungkinanKoneksi) {
      return 'Tidak dapat terhubung ke SaryPOS. Periksa koneksi internet Anda, lalu coba lagi.';
    }

    return 'Gagal menyiapkan SaryPOS. Periksa koneksi internet Anda, lalu coba lagi.';
  }

  Future<void> muatUlangSesi() async {
    if (_sedangMemeriksaSesi) return;
    _pesanErrorSesi = null;
    _sedangMemeriksaSesi = true;
    notifyListeners();
    await _inisialisasi();
  }

  Future<void> lanjutSebagaiKasirTanpaOwner() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kunciPrefLanjutKasir, true);
    _lanjutKasirTanpaOwner = true;
    notifyListeners();
  }

  Future<void> perbaruiDariAuth() async {
    final user = supabaseKlien.auth.currentUser;
    if (user == null) {
      _pengguna = null;
      return;
    }
    final profil = await _jalankanDenganTimeoutDanRetry(
      () => _penggunaSumber.ambilPenggunaDariIdAuth(user.id),
      deskripsi: 'memuat profil pengguna',
    );
    if (profil != null && !profil.aktif) {
      await supabaseKlien.auth.signOut();
      _pengguna = null;
      return;
    }
    _pengguna = profil;
  }

  Future<String?> masuk({required String email, required String sandi}) async {
    try {
      await supabaseKlien.auth.signInWithPassword(
        email: email.trim(),
        password: sandi,
      );
      await perbaruiDariAuth();
      if (_pengguna == null) {
        await supabaseKlien.auth.signOut();
        return 'Akun belum terdaftar di SaryPOS. Hubungi owner.';
      }
      catatLogAktivitas(
        idPengguna: _pengguna!.id,
        jenis: JenisLogAktivitas.login,
        deskripsi: '${_pengguna!.namaLengkap} masuk',
      );
      notifyListeners();
      return null;
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> keluar() async {
    try {
      final id = _pengguna?.id;
      final nama = _pengguna?.namaLengkap;
      await supabaseKlien.auth.signOut();
      if (id != null) {
        catatLogAktivitas(
          idPengguna: id,
          jenis: JenisLogAktivitas.logout,
          deskripsi: '${nama ?? 'Pengguna'} keluar',
        );
      }
      _pengguna = null;
      notifyListeners();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  void tandaiTransaksiTersimpan() {
    _versiTransaksiTerakhir++;
    notifyListeners();
  }

  Future<void> setelahProfilBerubah() async {
    await perbaruiDariAuth();
    notifyListeners();
  }

  Future<void> rangkumSesaiAutentikasi() async {
    _adaOwnerAktif = await _penggunaSumber.apakahAdaOwnerAktif();
    await perbaruiDariAuth();
    notifyListeners();
  }
}
