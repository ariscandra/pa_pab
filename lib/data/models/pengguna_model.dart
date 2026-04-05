class PenggunaModel {
  const PenggunaModel({
    required this.id,
    required this.idAuth,
    required this.namaLengkap,
    required this.email,
    required this.peran,
    required this.aktif,
    this.sandiLogin,
  });

  final String id;
  final String idAuth;
  final String namaLengkap;
  final String email;
  final String peran;
  final bool aktif;
  final String? sandiLogin;

  bool get isOwner => peran == 'owner';

  factory PenggunaModel.dariBaris(Map<String, dynamic> row) {
    return PenggunaModel(
      id: row['id'].toString(),
      idAuth: row['id_auth'].toString(),
      namaLengkap: row['nama_lengkap']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      peran: row['peran']?.toString() ?? 'karyawan',
      aktif: row['aktif'] == true,
      sandiLogin: row['sandi_login']?.toString(),
    );
  }
}
