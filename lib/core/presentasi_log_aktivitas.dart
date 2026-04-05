import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      return 'Status Karyawan';
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
