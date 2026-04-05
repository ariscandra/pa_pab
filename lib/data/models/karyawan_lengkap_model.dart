import 'package:sarypos/data/models/pengguna_model.dart';
import 'package:sarypos/data/models/profil_karyawan_model.dart';

class KaryawanLengkapModel {
  const KaryawanLengkapModel({required this.pengguna, this.profil});

  final PenggunaModel pengguna;
  final ProfilKaryawanModel? profil;
}
