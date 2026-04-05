import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sarypos/config/supabase_konfigurasi.dart';

Future<void> inisialisasiSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

SupabaseClient get supabaseKlien => Supabase.instance.client;

Future<bool> tesKoneksiSupabase() async {
  try {
    final respons = await supabaseKlien.from('pengguna').select().limit(1);
    return respons.isNotEmpty;
  } on Exception {
    return false;
  }
}
