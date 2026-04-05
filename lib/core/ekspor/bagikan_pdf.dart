import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> bagikanFilePdf({
  required Uint8List bytes,
  required String namaFile,
  required String subject,
}) async {
  await Printing.sharePdf(bytes: bytes, filename: namaFile, subject: subject);
}
