import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sarypos/core/ekspor/bagikan_pdf.dart' as bagikan_pdf;
import 'package:sarypos/core/format_rupiah.dart';
import 'package:sarypos/core/label_metode_pembayaran.dart';
import 'package:sarypos/data/sources/laporan_sumber.dart';

String labelRentangLaporan(RentangLaporan r) {
  return switch (r) {
    RentangLaporan.hariIni => 'Hari Ini',
    RentangLaporan.mingguIni => 'Minggu Ini',
    RentangLaporan.bulanIni => 'Bulan Ini',
  };
}

Future<Uint8List> buatBytesLaporanPdf({
  required RingkasanLaporanPenjualan data,
  required RentangLaporan rentang,
}) async {
  final fTanggal = DateFormat('dd/MM/yyyy HH:mm');
  final label = labelRentangLaporan(rentang);
  final dibuat = fTanggal.format(DateTime.now().toLocal());

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(40)),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            'SaryPOS',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
        ),
        pw.Text(
          'Laporan Penjualan',
          style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 6),
        pw.Text('Periode: $label', style: const pw.TextStyle(fontSize: 11)),
        pw.Text(
          'Dicetak: $dibuat',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Jumlah Transaksi',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '${data.jumlahTransaksi}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Penjualan',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    formatRupiahAscii(data.totalNilaiPenjualan),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Rincian Transaksi',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (data.transaksiRingkas.isEmpty)
          pw.Text(
            'Tidak ada transaksi pada periode ini.',
            style: const pw.TextStyle(fontSize: 10),
          )
        else
          pw.TableHelper.fromTextArray(
            border: null,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            headerHeight: 28,
            cellHeight: 22,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
            },
            headerStyle: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: const [
              'Waktu',
              'Subtotal',
              'Potongan',
              'Total',
              'Pembayaran',
              'Pencatat',
            ],
            data: data.transaksiRingkas
                .map(
                  (t) => [
                    fTanggal.format(t.waktu.toLocal()),
                    formatRupiahAscii(t.subtotal),
                    t.potongan > 0 ? formatRupiahAscii(t.potongan) : '—',
                    formatRupiahAscii(t.total),
                    labelMetodePembayaran(t.metodePembayaran),
                    t.namaPencatat,
                  ],
                )
                .toList(),
          ),
      ],
    ),
  );

  return doc.save();
}

Future<void> bagikanLaporanPdf({
  required RingkasanLaporanPenjualan data,
  required RentangLaporan rentang,
}) async {
  final bytes = await buatBytesLaporanPdf(data: data, rentang: rentang);
  final label = labelRentangLaporan(rentang);
  final nama = 'laporan_sarypos_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await bagikan_pdf.bagikanFilePdf(
    bytes: bytes,
    namaFile: nama,
    subject: 'Laporan SaryPOS — $label',
  );
}
