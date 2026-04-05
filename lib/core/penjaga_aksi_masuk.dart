import 'package:flutter/widgets.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

bool cegahJikaBelumLogin(
  BuildContext context, {
  String? pesan,
}) {
  final s = WarisanSesi.dari(context);
  if (s.sedangMemeriksaSesi) {
    return true;
  }
  if (s.pengguna != null) {
    return false;
  }
  tampilkanSnackbarSarypos(
    context,
    tipe: TipeSnackbarSarypos.info,
    pesan:
        pesan ??
        'Masuk ke akun terlebih dahulu untuk mengakses fitur ini.',
  );
  return true;
}
