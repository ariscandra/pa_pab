import 'dart:typed_data';

import 'package:barcode/barcode.dart' as bc;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sarypos/data/models/pengguna_model.dart';
import 'package:sarypos/data/models/profil_karyawan_model.dart';

double _mm(double v) => v * 72 / 25.4;

Future<Uint8List?> _muatFotoBytes(String? url) async {
  if (url == null || url.isEmpty) {
    return null;
  }
  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
  } catch (_) {}
  return null;
}

Future<Uint8List> buatIdCardPdfBytes({
  required PenggunaModel pengguna,
  required ProfilKaryawanModel profil,
}) async {
  pw.Document doc;
  try {
    final fontBiasa = await PdfGoogleFonts.openSansRegular();
    final fontTebal = await PdfGoogleFonts.openSansBold();
    doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontBiasa, bold: fontTebal),
    );
  } catch (_) {
    doc = pw.Document();
  }

  final lebar = _mm(85.6);
  final tinggi = _mm(53.98);
  final format = PdfPageFormat(lebar, tinggi, marginAll: 0);

  final fotoBytes = await _muatFotoBytes(profil.fotoUrl);
  final qr = bc.Barcode.qrCode();
  final belakangData = 'SARYPOS|${pengguna.id}|${pengguna.email}';

  final teal = PdfColor.fromInt(0xFF1C4546);
  final gold = PdfColor.fromInt(0xFFE4AF1A);
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (ctx) => pw.Container(
        color: teal,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: _mm(22),
                height: _mm(28),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: fotoBytes != null
                    ? pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Image(
                          pw.MemoryImage(fotoBytes),
                          fit: pw.BoxFit.cover,
                        ),
                      )
                    : pw.Center(
                        child: pw.Text(
                          'Foto',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(width: _mm(4)),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'SARY MART',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      pengguna.namaLengkap,
                      maxLines: 2,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      (profil.jabatan?.isNotEmpty ?? false)
                          ? profil.jabatan!
                          : 'Karyawan',
                      style: pw.TextStyle(
                        color: PdfColors.amber100,
                        fontSize: 9,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: gold,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        'STAF',
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (ctx) => pw.Container(
        color: PdfColors.white,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Kartu Identitas Karyawan',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: teal,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.BarcodeWidget(
                barcode: qr,
                data: belakangData,
                width: _mm(22),
                height: _mm(22),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Scan untuk verifikasi data',
                style: const pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Text(
                'Hubungi pemilik toko jika kartu hilang.\nDilarang meminjamkan kartu ini kepada pihak lain.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 5.5,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return doc.save();
}

Future<void> bagikanIdCardPdf({
  required PenggunaModel pengguna,
  required ProfilKaryawanModel profil,
}) async {
  final bytes = await buatIdCardPdfBytes(pengguna: pengguna, profil: profil);
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'id_card_${pengguna.id.substring(0, 8)}.pdf',
    subject: 'ID Card — ${pengguna.namaLengkap}',
  );
}

Future<void> pratinjauCetakIdCard({
  required PenggunaModel pengguna,
  required ProfilKaryawanModel profil,
}) async {
  final bytes = await buatIdCardPdfBytes(pengguna: pengguna, profil: profil);
  final amanNama = pengguna.namaLengkap.replaceAll(RegExp(r'[^\w\s-]'), '_');
  await Printing.layoutPdf(
    onLayout: (_) async => bytes,
    name: 'id_card_$amanNama.pdf',
  );
}
