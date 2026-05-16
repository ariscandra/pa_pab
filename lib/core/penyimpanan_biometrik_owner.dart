import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PenyimpananBiometrikOwner {
  PenyimpananBiometrikOwner();

  static const _kunciPrefAktif = 'sarypos_owner_bio_diaktifkan';
  static const _kunciEmail = 'sarypos_owner_bio_email';
  static const _kunciSandi = 'sarypos_owner_bio_sandi';

  final FlutterSecureStorage _aman = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> biometrikDiaktifkan() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kunciPrefAktif) ?? false;
  }

  Future<void> simpanKredensialSetelahVerifikasiBiometrik({
    required String email,
    required String sandi,
  }) async {
    await _aman.write(key: _kunciEmail, value: email.trim());
    await _aman.write(key: _kunciSandi, value: sandi);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kunciPrefAktif, true);
  }

  Future<({String email, String sandi})?> bacaKredensial() async {
    final email = await _aman.read(key: _kunciEmail);
    final sandi = await _aman.read(key: _kunciSandi);
    if (email == null || email.isEmpty || sandi == null || sandi.isEmpty) {
      return null;
    }
    return (email: email, sandi: sandi);
  }

  Future<void> hapusSemua() async {
    await _aman.delete(key: _kunciEmail);
    await _aman.delete(key: _kunciSandi);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kunciPrefAktif);
  }
}
