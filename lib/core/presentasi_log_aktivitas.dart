import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/layanan_catat_log.dart';

IconData ikonLogAktivitas(String jenis) {
  switch (jenis) {
    case 'login':
      return Icons.login;
    case 'logout':
      return Icons.logout;
    case 'transaksi':
      return Icons.point_of_sale;
    case 'ubah_stok':
      return Icons.inventory_2_outlined;
    case 'ekspor_pdf':
    case 'ekspor_csv':
      return Icons.file_download_outlined;
    case 'karyawan_tambah':
    case 'karyawan_ubah':
    case 'karyawan_status':
      return Icons.badge_outlined;
    case 'registrasi_owner':
      return Icons.storefront;
    case 'error':
      return Icons.error_outline;
    default:
      return Icons.notifications_none_outlined;
  }
}

String judulRingkasLog(String jenis) {
  switch (jenis) {
    case 'login':
      return 'Masuk';
    case 'logout':
      return 'Keluar';
    case 'transaksi':
      return 'Transaksi';
    case 'ubah_stok':
      return 'Stok';
    case 'ekspor_pdf':
      return 'Ekspor PDF';
    case 'ekspor_csv':
      return 'Ekspor CSV';
    case 'karyawan_tambah':
      return 'Karyawan Baru';
    case 'karyawan_ubah':
      return 'Ubah Karyawan';
    case 'karyawan_status':
      return 'Karyawan';
    case 'registrasi_owner':
      return 'Pemilik Toko';
    case 'error':
      return 'Gangguan';
    default:
      return 'Aktivitas';
  }
}

String waktuLogRelatif(DateTime w) {
  final sekarang = DateTime.now();
  final d = sekarang.difference(w);
  if (d.inSeconds < 60) {
    return 'Baru saja';
  }
  if (d.inMinutes < 60) {
    return '${d.inMinutes} menit lalu';
  }
  if (d.inHours < 24) {
    return '${d.inHours} jam lalu';
  }
  if (d.inDays < 7) {
    return '${d.inDays} hari lalu';
  }
  return DateFormat('dd MMM yyyy, HH:mm').format(w);
}

String? teksLokasiDariMetadataJson(Map<String, dynamic>? metadata) {
  if (metadata == null) {
    return null;
  }
  final raw = metadata['lokasi_ringkas']?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }
  return raw;
}

/// Subtitle utama + baris lokasi (metadata) untuk daftar aktivitas ringkas / log.
String susunDeskripsiTampilanLog({
  required String deskripsi,
  Map<String, dynamic>? metadata,
}) {
  final loc = teksLokasiDariMetadataJson(metadata);
  if (loc == null) {
    return deskripsi;
  }
  return '$deskripsi\nLokasi: $loc';
}

String labelKategoriFilterLog(String kunci) {
  switch (kunci) {
    case 'transaksi':
      return 'Transaksi';
    case 'stok':
      return 'Stok';
    case 'karyawan':
      return 'Karyawan';
    case 'akun':
      return 'Akun';
    case 'laporan':
      return 'Laporan';
    case 'gangguan':
      return 'Gangguan';
    default:
      return 'Semua';
  }
}

bool logMasukKategoriFilter(String jenis, String kunciFilter) {
  if (kunciFilter == 'semua') {
    return true;
  }
  switch (kunciFilter) {
    case 'transaksi':
      return jenis == JenisLogAktivitas.transaksi;
    case 'stok':
      return jenis == JenisLogAktivitas.ubahStok;
    case 'karyawan':
      return jenis == JenisLogAktivitas.karyawanTambah ||
          jenis == JenisLogAktivitas.karyawanUbah ||
          jenis == JenisLogAktivitas.karyawanStatus;
    case 'akun':
      return jenis == JenisLogAktivitas.login ||
          jenis == JenisLogAktivitas.logout ||
          jenis == JenisLogAktivitas.registrasiOwner;
    case 'laporan':
      return jenis == JenisLogAktivitas.eksporPdf ||
          jenis == JenisLogAktivitas.eksporCsv;
    case 'gangguan':
      return jenis == JenisLogAktivitas.error;
    default:
      return true;
  }
}

Color warnaAksenJenisLog(BuildContext context, String jenis) {
  final skema = Theme.of(context).colorScheme;
  switch (jenis) {
    case JenisLogAktivitas.transaksi:
      return WarnaSarypos.deepTeal;
    case JenisLogAktivitas.ubahStok:
      return WarnaSarypos.saryGold;
    case JenisLogAktivitas.error:
      return WarnaSarypos.saryRed;
    case JenisLogAktivitas.karyawanTambah:
    case JenisLogAktivitas.karyawanUbah:
    case JenisLogAktivitas.karyawanStatus:
      return skema.secondary;
    case JenisLogAktivitas.eksporPdf:
    case JenisLogAktivitas.eksporCsv:
      return skema.tertiary;
    default:
      return warnaAksenJudulBagian(context);
  }
}

String formatWaktuLogLengkap(DateTime waktu) {
  return DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id_ID').format(waktu);
}

String teksPencarianLog({
  required String jenis,
  required String deskripsi,
  Map<String, dynamic>? metadata,
}) {
  final lokasi = teksLokasiDariMetadataJson(metadata);
  return '${judulRingkasLog(jenis)} $deskripsi $jenis ${lokasi ?? ''}'
      .toLowerCase();
}
