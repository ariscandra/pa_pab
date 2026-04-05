import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> bagikanStringCsv({
  required String isiCsv,
  required String namaFile,
  required String subjek,
}) async {
  if (kIsWeb) {
    await Clipboard.setData(ClipboardData(text: isiCsv));
    return;
  }

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$namaFile';
  final file = File(path);
  await file.writeAsString(isiCsv, encoding: utf8);
  await Share.shareXFiles([XFile(path, mimeType: 'text/csv')], subject: subjek);
}
