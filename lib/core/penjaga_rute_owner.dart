import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarypos/core/warisan_sesi.dart';

Future<T?> dorongJikaOwner<T extends Object?>(
  BuildContext context,
  WidgetBuilder builder, {
  String pesanDitolak =
      'Hanya pemilik toko (owner) yang dapat membuka halaman ini.',
}) async {
  final sesi = WarisanSesi.dari(context);
  final p = sesi.pengguna;
  if (p == null || !p.isOwner) {
    if (!context.mounted) {
      return null;
    }
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Akses Ditolak'),
        content: Text(pesanDitolak),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
    return null;
  }

  if (!context.mounted) {
    return null;
  }
  return Get.to<T>(() => builder(context));
}

bool penggunaAdalahOwner(BuildContext context) {
  return WarisanSesi.dari(context).pengguna?.isOwner ?? false;
}
