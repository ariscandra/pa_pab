import 'package:flutter/material.dart';

Future<bool> tampilkanDialogKonfirmasiSarypos(
  BuildContext context, {
  required String judul,
  required String pesan,
  String labelBatal = 'Batal',
  String labelLanjut = 'Lanjut',
  bool destruktif = false,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final skema = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(judul),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(labelBatal),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: destruktif
                ? FilledButton.styleFrom(backgroundColor: skema.error)
                : null,
            child: Text(labelLanjut),
          ),
        ],
      );
    },
  );
  return hasil == true;
}
