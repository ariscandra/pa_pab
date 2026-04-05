class LogAktivitasModel {
  const LogAktivitasModel({
    required this.id,
    required this.waktu,
    this.idPengguna,
    required this.jenis,
    required this.deskripsi,
    this.metadataJson,
  });

  final String id;
  final DateTime waktu;
  final String? idPengguna;
  final String jenis;
  final String deskripsi;
  final Map<String, dynamic>? metadataJson;

  factory LogAktivitasModel.dariBaris(Map<String, dynamic> row) {
    final wMentah = row['waktu'];
    DateTime waktu;
    if (wMentah is DateTime) {
      waktu = wMentah.isUtc ? wMentah.toLocal() : wMentah;
    } else if (wMentah is String) {
      waktu = DateTime.tryParse(wMentah)?.toLocal() ?? DateTime.now();
    } else {
      waktu = DateTime.now();
    }

    Map<String, dynamic>? meta;
    final m = row['metadata_json'];
    if (m is Map<String, dynamic>) {
      meta = m;
    } else if (m is Map) {
      meta = Map<String, dynamic>.from(m);
    }

    return LogAktivitasModel(
      id: row['id'].toString(),
      waktu: waktu,
      idPengguna: row['id_pengguna']?.toString(),
      jenis: row['jenis']?.toString() ?? 'lainnya',
      deskripsi: row['deskripsi']?.toString() ?? '',
      metadataJson: meta,
    );
  }
}
