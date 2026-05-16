import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// Hasil lokasi perkiraan. [lokasiRingkas] boleh null sesuai §5.4 Fase 6 —
/// geocode gagal / izin / jaringan: teks utama tidak diisi namun [lat]/[lng]
/// bisa tetap diisi untuk baris transaksi atau metadata lat/lng.
class HasilAmbilLokasi {
  HasilAmbilLokasi({required this.lat, required this.lng, this.lokasiRingkas});

  final double lat;
  final double lng;
  final String? lokasiRingkas;

  static const panjangTeksSingkatMax = 110;

  Map<String, dynamic> keMapMetadataJson() {
    return {
      if (lokasiRingkas != null && lokasiRingkas!.trim().isNotEmpty)
        'lokasi_ringkas': lokasiRingkas!.trim(),
      'lat': lat,
      'lng': lng,
    };
  }
}

class LayananLokasiSarypos {
  LayananLokasiSarypos._();

  static const userAgentOsmPatuh =
      'SaryPOS/1.0 (Proyek Akhir PAB; contact: tidak dipublikasikan)';

  static final Map<String, String?> _singkatUntukTitikBulat =
      <String, String?>{};

  static Future<void> _rantaiNom = Future.value();

  static Future<HasilAmbilLokasi?> jalankanAmbilSekali() async {
    try {
      final layananNyala = await Geolocator.isLocationServiceEnabled();
      if (!layananNyala) {
        return null;
      }

      var hak = await Geolocator.checkPermission();
      if (hak == LocationPermission.denied) {
        hak = await Geolocator.requestPermission();
        if (hak == LocationPermission.denied ||
            hak == LocationPermission.deniedForever) {
          return null;
        }
      } else if (hak == LocationPermission.deniedForever) {
        return null;
      }

      await Permission.locationWhenInUse.request();

      final posisi =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              throw TimeoutException('GPS');
            },
          );

      final lat = posisi.latitude;
      final lng = posisi.longitude;

      final kunciTitik = sambungKunciTitik(lat: lat, lng: lng);
      if (_singkatUntukTitikBulat.containsKey(kunciTitik)) {
        final teksSingkatTersembunyi = _singkatUntukTitikBulat[kunciTitik];
        return HasilAmbilLokasi(
          lat: lat,
          lng: lng,
          lokasiRingkas: teksSingkatTersembunyi?.isEmpty ?? true
              ? null
              : teksSingkatTersembunyi,
        );
      }

      Map<String, dynamic>? petaNom;
      try {
        final sebelum = _rantaiNom;
        final penyempurnaan = Completer<void>();
        _rantaiNom = penyempurnaan.future;
        try {
          await sebelum;
          await _jelangSebelumNom();
          final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
            'lat': lat.toString(),
            'lon': lng.toString(),
            'format': 'json',
          });
          final respons = await http.get(
            uri,
            headers: {
              'User-Agent': userAgentOsmPatuh,
              'Accept': 'application/json',
            },
          );
          if (respons.statusCode >= 200 && respons.statusCode < 300) {
            final obj = jsonDecode(respons.body);
            if (obj is Map<String, dynamic>) {
              petaNom = obj;
            }
          }
        } finally {
          penyempurnaan.complete();
        }
      } catch (_) {
        petaNom = null;
      }

      String? teksUntukRiwayat;
      if (petaNom != null) {
        final mentah = rangkaiAlamatTanpaTitikKoordinat(petaNom).trim();
        if (mentah.isNotEmpty) {
          teksUntukRiwayat =
              mentah.length > HasilAmbilLokasi.panjangTeksSingkatMax
              ? '${mentah.substring(0, HasilAmbilLokasi.panjangTeksSingkatMax - 1)}…'
              : mentah;
        }
      }

      _singkatUntukTitikBulat[kunciTitik] = teksUntukRiwayat ?? '';

      return HasilAmbilLokasi(
        lat: lat,
        lng: lng,
        lokasiRingkas: teksUntukRiwayat,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _jangkaTerakhirNominatim;

  static Future<void> _jelangSebelumNom() async {
    final sekarang = DateTime.now();
    final akhir = _jangkaTerakhirNominatim;
    if (akhir != null) {
      final usang = sekarang.difference(akhir);
      if (usang.inMilliseconds < 1000) {
        await Future<void>.delayed(
          Duration(milliseconds: 1000 - usang.inMilliseconds),
        );
      }
    }
    _jangkaTerakhirNominatim = DateTime.now();
  }

  static String sambungKunciTitik({required double lat, required double lng}) =>
      '${lat.toStringAsFixed(4)}:${lng.toStringAsFixed(4)}';

  /// Nama jalan + kota atau [display_name] yang dipangkas — tanpa menyamakan dengan koordinat mentah sebagai alamat §5.4.
  static String rangkaiAlamatTanpaTitikKoordinat(Map<String, dynamic> peta) {
    final alamat = peta['address'];
    if (alamat is Map<String, dynamic>) {
      final jalan =
          alamat['road'] ??
          alamat['pedestrian'] ??
          alamat['footway'] ??
          alamat['path'] ??
          alamat['residential'];

      final kota =
          alamat['city'] ??
          alamat['town'] ??
          alamat['municipality'] ??
          alamat['village'] ??
          alamat['suburb'] ??
          alamat['state_district'] ??
          alamat['county'];

      final namaJalan = jalan?.toString().trim() ?? '';
      final namaKota = kota?.toString().trim() ?? '';

      if (namaJalan.isNotEmpty && namaKota.isNotEmpty) {
        return '$namaJalan — $namaKota';
      }
      if (namaJalan.isNotEmpty) {
        return namaJalan;
      }
      if (namaKota.isNotEmpty) {
        return namaKota;
      }
    }

    final tampilan = peta['display_name']?.toString().trim() ?? '';
    if (tampilan.isNotEmpty) {
      return tampilan;
    }

    return '';
  }
}
