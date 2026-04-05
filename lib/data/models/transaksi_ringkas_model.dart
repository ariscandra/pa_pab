class TransaksiRingkasModel {
  const TransaksiRingkasModel({
    required this.id,
    required this.waktu,
    required this.total,
    required this.metodePembayaran,
    required this.subtotal,
    required this.potongan,
    required this.namaPencatat,
  });

  final String id;
  final DateTime waktu;
  final int total;
  final String metodePembayaran;
  final int subtotal;
  final int potongan;
  final String namaPencatat;

  factory TransaksiRingkasModel.dariBaris(Map<String, dynamic> row) {
    final waktuMentah = row['waktu'];
    final waktu = _parseWaktuDariKolom(waktuMentah);

    final idMentah = row['id'];
    final id = idMentah == null ? '' : idMentah.toString();

    final total = _parseIntTotal(row['total']);
    final subtotalMentah = row['subtotal'];
    final potonganMentah = row['potongan'];
    final subtotal = subtotalMentah != null
        ? _parseIntTotal(subtotalMentah)
        : total;
    final potongan = potonganMentah != null
        ? _parseIntTotal(potonganMentah)
        : 0;

    var namaPencatat = '—';
    final relPengguna = row['pengguna'];
    if (relPengguna is Map<String, dynamic>) {
      final n = relPengguna['nama_lengkap']?.toString().trim();
      if (n != null && n.isNotEmpty) {
        namaPencatat = n;
      }
    }

    return TransaksiRingkasModel(
      id: id,
      waktu: waktu,
      total: total,
      metodePembayaran: row['metode_pembayaran']?.toString() ?? 'tunai',
      subtotal: subtotal,
      potongan: potongan,
      namaPencatat: namaPencatat,
    );
  }

  static DateTime _parseWaktuDariKolom(dynamic mentah) {
    if (mentah == null) {
      return DateTime.now().toLocal();
    }
    if (mentah is DateTime) {
      return mentah.isUtc ? mentah.toLocal() : mentah;
    }
    if (mentah is String) {
      return _parseWaktuSupabaseKeLokal(mentah);
    }
    final s = mentah.toString();
    return s.isEmpty ? DateTime.now().toLocal() : _parseWaktuSupabaseKeLokal(s);
  }

  static DateTime _parseWaktuSupabaseKeLokal(String mentah) {
    final s = mentah.trim();
    if (s.isEmpty) {
      return DateTime.now();
    }
    final adaZona =
        s.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s) ||
        RegExp(r'[+-]\d{2}$').hasMatch(s);
    try {
      if (adaZona) {
        return DateTime.parse(s).toLocal();
      }
      final normal = s.contains('T') ? s : s.replaceFirst(' ', 'T');
      return DateTime.parse('${normal}Z').toLocal();
    } catch (_) {
      return DateTime.tryParse(s)?.toLocal() ?? DateTime.now();
    }
  }

  static int _parseIntTotal(dynamic v) {
    return switch (v) {
      int i => i,
      num n => n.round(),
      String s => int.tryParse(s.split('.').first) ?? 0,
      _ => 0,
    };
  }
}
