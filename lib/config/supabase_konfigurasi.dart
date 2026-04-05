import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _supabaseUrlDartDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyDartDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);
const String _supabaseServiceRoleDartDefine = String.fromEnvironment(
  'SUPABASE_SERVICE_ROLE_KEY',
);

String _ambilKonfigurasiWajib({
  required String namaKunci,
  required String nilaiDartDefine,
}) {
  final nilaiDefine = nilaiDartDefine.trim();
  if (nilaiDefine.isNotEmpty) {
    return nilaiDefine;
  }

  final nilaiEnv = (dotenv.env[namaKunci] ?? '').trim();
  if (nilaiEnv.isNotEmpty) {
    return nilaiEnv;
  }

  throw StateError(
    'Konfigurasi `$namaKunci` belum tersedia. '
    'Isi di .env atau kirim lewat --dart-define.',
  );
}

String get supabaseUrl {
  return _ambilKonfigurasiWajib(
    namaKunci: 'SUPABASE_URL',
    nilaiDartDefine: _supabaseUrlDartDefine,
  );
}

String get supabaseAnonKey {
  return _ambilKonfigurasiWajib(
    namaKunci: 'SUPABASE_ANON_KEY',
    nilaiDartDefine: _supabaseAnonKeyDartDefine,
  );
}

String? get supabaseServiceRoleKey {
  final nilaiDefine = _supabaseServiceRoleDartDefine.trim();
  if (nilaiDefine.isNotEmpty) {
    return nilaiDefine;
  }
  final nilaiEnv = (dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim();
  if (nilaiEnv.isNotEmpty) {
    return nilaiEnv;
  }
  return null;
}
