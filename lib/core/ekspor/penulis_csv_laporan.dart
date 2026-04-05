import 'package:csv/csv.dart';
import 'package:sarypos/core/ekspor/penulis_pdf_laporan.dart';
import 'package:sarypos/data/sources/laporan_sumber.dart';

String buatCsvRingkasanPenjualan({
  required RingkasanLaporanPenjualan data,
  required RentangLaporan rentang,
}) {
  final label = labelRentangLaporan(rentang);
  final baris = <List<dynamic>>[
    ['SaryPOS — Laporan Penjualan'],
    ['Periode', label],
    [],
    ['Ringkasan', 'jumlah_transaksi', data.jumlahTransaksi],
    ['Ringkasan', 'total_nilai_rupiah', data.totalNilaiPenjualan],
    [],
    [
      'id_transaksi',
      'waktu_iso',
      'subtotal_rupiah',
      'potongan_rupiah',
      'total_rupiah',
      'metode_pembayaran',
      'nama_pencatat',
    ],
    ...data.transaksiRingkas.map(
      (t) => [
        t.id,
        t.waktu.toUtc().toIso8601String(),
        t.subtotal,
        t.potongan,
        t.total,
        t.metodePembayaran,
        t.namaPencatat,
      ],
    ),
  ];
  return const ListToCsvConverter().convert(baris);
}
