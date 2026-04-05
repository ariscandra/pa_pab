import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PilihanTemaSarypos { ikutiSistem, terang, gelap }

class PengaturTema extends ChangeNotifier {
  PengaturTema();

  static const _kunciPref = 'sarypos_pilihan_tema';

  PilihanTemaSarypos _pilihan = PilihanTemaSarypos.terang;

  PilihanTemaSarypos get pilihan => _pilihan;

  ThemeMode get modeMaterial {
    return switch (_pilihan) {
      PilihanTemaSarypos.ikutiSistem => ThemeMode.system,
      PilihanTemaSarypos.terang => ThemeMode.light,
      PilihanTemaSarypos.gelap => ThemeMode.dark,
    };
  }

  Future<void> muatAwal() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kunciPref);
    if (raw != null) {
      for (final e in PilihanTemaSarypos.values) {
        if (e.name == raw) {
          _pilihan = e;
          break;
        }
      }
    }
    notifyListeners();
  }

  Future<void> atur(PilihanTemaSarypos nilai) async {
    if (_pilihan == nilai) return;
    _pilihan = nilai;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kunciPref, nilai.name);
  }
}
