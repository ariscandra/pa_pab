import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/core/penyimpanan_biometrik_owner.dart';

/// Menawarkan penyimpanan sandi pemilik secara aman setelah otentikasi sukses.
Future<void> tawarkanAktivasiBiometrikOwnerSesudahKredensialValid({
  required BuildContext konteks,
  required PengaturSesi pengatur,
  required String email,
  required String sandi,
}) async {
  if (!konteks.mounted) {
    return;
  }

  final profil = pengatur.pengguna;
  if (profil == null || !profil.isOwner) {
    return;
  }

  final simpan = PenyimpananBiometrikOwner();
  if (await simpan.biometrikDiaktifkan()) {
    return;
  }

  final biometric = LocalAuthentication();
  final didukung = await biometric.isDeviceSupported() &&
      await biometric.canCheckBiometrics;
  if (!didukung) {
    return;
  }

  if (!konteks.mounted) {
    return;
  }

  final setuju = await showDialog<bool>(
    context: konteks,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Buka kunci biometrik?'),
        content: const Text(
          'Aktifkan masuk cepat pemilik menggunakan sidik atau wajah di perangkat ini. Anda tetap bisa memakai email dan kata sandi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Lain kali'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lanjut'),
          ),
        ],
      );
    },
  );

  if (setuju != true || !konteks.mounted) {
    return;
  }

  final sah = await biometric.authenticate(
    localizedReason:
        'Verifikasi diri Anda untuk menyimpan kredensial masuk secara aman di perangkat.',
    options: const AuthenticationOptions(
      biometricOnly: true,
      stickyAuth: true,
    ),
  );

  if (!sah || !konteks.mounted) {
    return;
  }

  await simpan.simpanKredensialSetelahVerifikasiBiometrik(
    email: email,
    sandi: sandi,
  );
}
