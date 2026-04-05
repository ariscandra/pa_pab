import 'dart:math';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/config/supabase_konfigurasi.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/core/formatter_tanpa_emoji.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/core/ekspor/penulis_pdf_id_card.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/data/models/pengguna_model.dart';
import 'package:sarypos/data/models/profil_karyawan_model.dart';
import 'package:sarypos/data/sources/pengguna_sumber.dart';
import 'package:sarypos/data/sources/profil_karyawan_sumber.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:http/http.dart' as http;

String _namaPendekUntukEmail(String namaLengkap) {
  final bagian = namaLengkap
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  final potong = bagian.isEmpty ? '' : bagian.first;
  var s = potong.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (s.isEmpty) {
    s = 'staf';
  }
  if (s.length > 10) {
    s = s.substring(0, 10);
  }
  return s;
}

String _emailOtomatisKaryawan(String namaLengkap) {
  final pendek = _namaPendekUntukEmail(namaLengkap);
  final r = Random.secure();
  final pin = 1000 + r.nextInt(9000);
  return 'staf.$pendek.$pin@sarypos.app';
}

Future<String> _buatAkunAuthKaryawanAdmin({
  required String email,
  required String sandi,
}) async {
  final serviceRoleKey = supabaseServiceRoleKey;
  if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
    throw Exception(
      'SUPABASE_SERVICE_ROLE_KEY belum diisi (.env atau --dart-define). '
      'Kunci ini diperlukan agar akun staf bisa dibuat tanpa memutus sesi Anda.',
    );
  }

  final baseUrl = supabaseUrl;
  final url = Uri.parse('$baseUrl/auth/v1/admin/users');
  final respons = await http.post(
    url,
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': sandi,
      'email_confirm': true,
    }),
  );

  if (respons.statusCode < 200 || respons.statusCode >= 300) {
    final body = respons.body.isNotEmpty ? respons.body : 'Respon kosong';
    throw Exception('Gagal membuat akun Auth staf: $body');
  }

  final map = jsonDecode(respons.body) as Map<String, dynamic>;
  final id = map['id']?.toString();
  if (id == null || id.isEmpty) {
    throw Exception('Gagal membaca id akun Auth staf baru.');
  }
  return id;
}

String _sandiMudahDiingat() {
  const kata = ['kasir', 'staf', 'toko', 'sary', 'mart', 'jaga', 'senja'];
  final r = Random.secure();
  final k = kata[r.nextInt(kata.length)];
  final pin = 1000 + r.nextInt(9000);
  return '$k$pin';
}

String _ringkasErrorUntukSnackbar(Object e) {
  final t = e.toString().trim();
  if (t.length <= 280) {
    return t;
  }
  return '${t.substring(0, 280)}…';
}

int? _parseBilanganNonNegatifOpsional(String? teks) {
  final t = teks?.trim() ?? '';
  if (t.isEmpty) {
    return null;
  }
  if (t.contains('-')) {
    return null;
  }
  if (RegExp(r'[A-Za-z]').hasMatch(t)) {
    return null;
  }
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return null;
  }
  return int.tryParse(digits);
}

String? _validasiBilanganNonNegatifOpsional(String? v, String label) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) {
    return null;
  }
  if (t.contains('-')) {
    return '$label tidak boleh negatif';
  }
  if (RegExp(r'[A-Za-z]').hasMatch(t)) {
    return '$label harus angka';
  }
  if (!RegExp(r'^[0-9.,\\s]+$').hasMatch(t)) {
    return '$label tidak valid';
  }
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  final n = int.tryParse(digits);
  if (n == null) {
    return '$label tidak valid';
  }
  if (n < 0) {
    return '$label tidak boleh negatif';
  }
  return null;
}

Future<void> _pilihFotoKaryawan({
  required ImagePicker picker,
  required void Function(VoidCallback fn) setStateFn,
  required void Function(Uint8List bytes, String ekstensi) onBerhasil,
}) async {
  if (kIsWeb) {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (res == null || res.files.isEmpty) {
      return;
    }
    final f = res.files.single;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    final name = f.name.toLowerCase();
    final ext = name.endsWith('.png')
        ? 'png'
        : name.endsWith('.webp')
        ? 'webp'
        : 'jpg';
    setStateFn(() => onBerhasil(bytes, ext));
    return;
  }
  final x = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    imageQuality: 85,
  );
  if (x == null) {
    return;
  }
  final bytes = await x.readAsBytes();
  final name = x.name.toLowerCase();
  final ext = name.endsWith('.png') ? 'png' : 'jpg';
  setStateFn(() => onBerhasil(bytes, ext));
}

class HalamanFormKaryawanTambah extends StatefulWidget {
  const HalamanFormKaryawanTambah({super.key, required this.pengatur});

  final PengaturSesi pengatur;

  @override
  State<HalamanFormKaryawanTambah> createState() =>
      _HalamanFormKaryawanTambahState();
}

class _HalamanFormKaryawanTambahState extends State<HalamanFormKaryawanTambah> {
  final _kunciForm = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _jabatan = TextEditingController();
  final _gaji = TextEditingController();
  final _catatan = TextEditingController();
  final _picker = ImagePicker();
  final _penggunaSumber = PenggunaSumber();
  final _profilSumber = ProfilKaryawanSumber();
  bool _sedangMenyimpan = false;
  DateTime? _mulaiKerja;
  int? _hariGajian;
  Uint8List? _fotoBaruBytes;
  String? _fotoBaruEkstensi;

  @override
  void dispose() {
    _nama.dispose();
    _jabatan.dispose();
    _gaji.dispose();
    _catatan.dispose();
    super.dispose();
  }

  ProfilKaryawanModel _modelProfil(String penggunaId, {String? fotoUrl}) {
    final gajiBulanan = _parseBilanganNonNegatifOpsional(_gaji.text);
    return ProfilKaryawanModel(
      id: '',
      penggunaId: penggunaId,
      gajiBulanan: gajiBulanan,
      tanggalMulaiKerja: _mulaiKerja,
      hariGajian: _hariGajian,
      fotoUrl: fotoUrl,
      jabatan: _jabatan.text.trim().isEmpty ? null : _jabatan.text.trim(),
      ingatkanBonus: false,
      catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
    );
  }

  Future<void> _pilihFoto() async {
    await _pilihFotoKaryawan(
      picker: _picker,
      setStateFn: setState,
      onBerhasil: (b, e) {
        _fotoBaruBytes = b;
        _fotoBaruEkstensi = e;
      },
    );
  }

  Future<void> _simpan() async {
    if (!_kunciForm.currentState!.validate()) {
      return;
    }

    final owner = widget.pengatur.pengguna;
    if (owner == null || !owner.isOwner) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan:
            'Akses ditolak. Hanya pemilik toko yang dapat menambah karyawan.',
      );
      return;
    }

    setState(() => _sedangMenyimpan = true);

    final emailBaru = _emailOtomatisKaryawan(_nama.text);
    final sandiBaru = _sandiMudahDiingat();

    try {
      final idAuthBaru = await _buatAkunAuthKaryawanAdmin(
        email: emailBaru,
        sandi: sandiBaru,
      );

      final pg = await _penggunaSumber.sisipkanPengguna(
        idAuth: idAuthBaru,
        namaLengkap: _nama.text.trim(),
        email: emailBaru,
        peran: 'karyawan',
        sandiLogin: sandiBaru,
      );

      String? fotoUrl;
      if (_fotoBaruBytes != null && _fotoBaruEkstensi != null) {
        fotoUrl = await _profilSumber.unggahFoto(
          penggunaId: pg.id,
          bytes: _fotoBaruBytes!,
          ekstensi: _fotoBaruEkstensi!,
        );
      }
      await _profilSumber.simpanProfil(_modelProfil(pg.id, fotoUrl: fotoUrl));

      await widget.pengatur.rangkumSesaiAutentikasi();

      if (!mounted) {
        return;
      }
      catatLogAktivitas(
        idPengguna: owner.id,
        jenis: JenisLogAktivitas.karyawanTambah,
        deskripsi: 'Menambah karyawan: ${_nama.text.trim()}',
        metadataJson: {'pengguna_id_baru': pg.id},
      );
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Karyawan dan profil HR tersimpan.',
      );
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Kredensial staf baru'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Email dan sandi dibuat otomatis. Salin lalu berikan ke karyawan (tidak diubah dari manajemen karyawan).',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'Email:\n$emailBaru\n\nSandi:\n$sandiBaru',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: 'Email: $emailBaru\nSandi: $sandiBaru'),
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Salin ke papan klip'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      assert(() {
        debugPrint('SaryPOS tambah karyawan gagal: $e\n$st');
        return true;
      }());
      try {
        await widget.pengatur.rangkumSesaiAutentikasi();
      } catch (_) {}

      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan:
            'Gagal menambah karyawan.\n${_ringkasErrorUntukSnackbar(e)}\n\n'
            'Pastikan SUPABASE_SERVICE_ROLE_KEY terset di .env (jangan dipublikasikan). '
            'Jika ada teks RLS: jalankan migrasi SQL yang disarankan di dokumentasi proyek.',
      );
    } finally {
      if (mounted) {
        setState(() => _sedangMenyimpan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fTanggal = DateFormat('d MMMM yyyy');
    return Scaffold(
      appBar: const AppBarSarypos(judul: 'Tambah Karyawan'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Email dan kata sandi staf dibuat otomatis dengan pola yang mudah diingat (ditampilkan setelah simpan). Anda tetap masuk sebagai pemilik. Data HR bersifat opsional.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Form(
              key: _kunciForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nama,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                    ),
                    enabled: !_sedangMenyimpan,
                    inputFormatters: [TanpaEmojiFormatter()],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Profil HR (Opsional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: warnaAksenJudulBagian(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jabatan,
                    decoration: const InputDecoration(
                      labelText: 'Jabatan',
                      hintText: 'Mis. Kasir',
                    ),
                    enabled: !_sedangMenyimpan,
                    inputFormatters: [TanpaEmojiFormatter()],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gaji,
                    decoration: const InputDecoration(
                      labelText: 'Gaji bulanan (Rp)',
                    ),
                    enabled: !_sedangMenyimpan,
                    keyboardType: TextInputType.number,
                    inputFormatters: [TanpaEmojiFormatter()],
                    validator: (v) =>
                        _validasiBilanganNonNegatifOpsional(v, 'Gaji bulanan'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mulai Bekerja'),
                    subtitle: Text(
                      _mulaiKerja == null
                          ? 'Belum diatur'
                          : fTanggal.format(_mulaiKerja!),
                    ),
                    trailing: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: _sedangMenyimpan
                          ? null
                          : () async {
                              final t = await showDatePicker(
                                context: context,
                                initialDate: _mulaiKerja ?? DateTime.now(),
                                firstDate: DateTime(1990),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 2),
                                ),
                              );
                              if (t != null) {
                                setState(() => _mulaiKerja = t);
                              }
                            },
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_hariGajian),
                    decoration: const InputDecoration(
                      labelText: 'Tanggal gajian (hari dalam bulan)',
                    ),
                    initialValue: _hariGajian,
                    items: List.generate(
                      31,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    validator: (v) {
                      if (v == null) return null;
                      if (v < 1 || v > 31) return 'Tanggal gajian tidak valid';
                      return null;
                    },
                    onChanged: _sedangMenyimpan
                        ? null
                        : (v) => setState(() => _hariGajian = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _catatan,
                    decoration: const InputDecoration(
                      labelText: 'Catatan internal',
                    ),
                    enabled: !_sedangMenyimpan,
                    inputFormatters: [TanpaEmojiFormatter()],
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _sedangMenyimpan ? null : _pilihFoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      _fotoBaruBytes != null
                          ? 'Foto dipilih (ketuk untuk ganti)'
                          : 'Pilih foto karyawan',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sedangMenyimpan ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarnaSarypos.saryRed,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _sedangMenyimpan
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HalamanFormKaryawanEdit extends StatefulWidget {
  const HalamanFormKaryawanEdit({super.key, required this.karyawanAwal});

  final PenggunaModel karyawanAwal;

  @override
  State<HalamanFormKaryawanEdit> createState() =>
      _HalamanFormKaryawanEditState();
}

class _HalamanFormKaryawanEditState extends State<HalamanFormKaryawanEdit> {
  final _kunciForm = GlobalKey<FormState>();
  final _penggunaSumber = PenggunaSumber();
  final _profilSumber = ProfilKaryawanSumber();
  final _nama = TextEditingController();
  final _emailLogin = TextEditingController();
  final _sandiLogin = TextEditingController();
  final _jabatan = TextEditingController();
  final _gaji = TextEditingController();
  final _catatan = TextEditingController();
  final _picker = ImagePicker();

  bool _kredensialSunting = false;
  bool _sudahSinkronKredensialKeAuth = false;
  String _idAuthTarget = '';

  ProfilKaryawanModel? _profil;
  DateTime? _mulaiKerja;
  int? _hariGajian;
  bool _tampilkanSandiLogin = false;
  bool _sedangMuat = true;
  bool _sedangMenyimpan = false;
  Uint8List? _fotoBaruBytes;
  String? _fotoBaruEkstensi;

  @override
  void initState() {
    super.initState();
    _idAuthTarget = widget.karyawanAwal.idAuth;
    _nama.text = widget.karyawanAwal.namaLengkap;
    _emailLogin.text = widget.karyawanAwal.email;
    _sandiLogin.text = widget.karyawanAwal.sandiLogin ?? '123456';
    _muatProfil();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_sudahSinkronKredensialKeAuth) return;

      final sesi = WarisanSesi.mungkinDari(context);
      final isOwner = sesi?.pengguna?.isOwner ?? false;
      final sandiDB = widget.karyawanAwal.sandiLogin?.trim();

      if (!isOwner || sandiDB == null || sandiDB.isEmpty) return;

      _sudahSinkronKredensialKeAuth = true;
      try {
        await _sinkronkanKredensialKeSupabaseAuth(
          email: widget.karyawanAwal.email,
          sandi: sandiDB,
        );
        if (!mounted) return;
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.info,
          pesan: 'Kredensial login telah disinkronkan.',
        );
      } catch (e) {
        if (!mounted) return;
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan:
              'Gagal menyinkronkan kredensial ke Supabase Auth.\n${_ringkasErrorUntukSnackbar(e)}',
        );
      }
    });
  }

  Future<void> _muatProfil() async {
    setState(() => _sedangMuat = true);
    final profil =
        (await _profilSumber.ambilUntukPengguna(widget.karyawanAwal.id)) ??
        ProfilKaryawanModel.kosong(widget.karyawanAwal.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _profil = profil;
      _jabatan.text = profil.jabatan ?? '';
      _gaji.text = profil.gajiBulanan != null ? '${profil.gajiBulanan}' : '';
      _catatan.text = profil.catatan ?? '';
      _mulaiKerja = profil.tanggalMulaiKerja;
      _hariGajian = profil.hariGajian;
      _sedangMuat = false;
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _emailLogin.dispose();
    _sandiLogin.dispose();
    _jabatan.dispose();
    _gaji.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    await _pilihFotoKaryawan(
      picker: _picker,
      setStateFn: setState,
      onBerhasil: (b, e) {
        _fotoBaruBytes = b;
        _fotoBaruEkstensi = e;
      },
    );
  }

  ProfilKaryawanModel _modelDariForm({required String? fotoUrl}) {
    final gajiBulanan = _parseBilanganNonNegatifOpsional(_gaji.text);
    return ProfilKaryawanModel(
      id: _profil?.id ?? '',
      penggunaId: widget.karyawanAwal.id,
      gajiBulanan: gajiBulanan,
      tanggalMulaiKerja: _mulaiKerja,
      hariGajian: _hariGajian,
      fotoUrl: fotoUrl ?? _profil?.fotoUrl,
      jabatan: _jabatan.text.trim().isEmpty ? null : _jabatan.text.trim(),
      ingatkanBonus: false,
      catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
    );
  }

  bool _validEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
  }

  void _ketukSuntingKredensial() {
    if (_sedangMenyimpan) return;

    final p = WarisanSesi.dari(context).pengguna;
    if (p == null || !p.isOwner) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan:
            'Akses ditolak. Hanya pemilik toko yang dapat mengubah kredensial.',
      );
      return;
    }

    setState(() {
      _kredensialSunting = !_kredensialSunting;
      if (!_kredensialSunting) {
        _emailLogin.text = widget.karyawanAwal.email;
        _sandiLogin.text = widget.karyawanAwal.sandiLogin ?? '123456';
        _tampilkanSandiLogin = false;
      }
    });
  }

  Future<void> _salinEmailDanSandiGabungan() async {
    final email = _emailLogin.text.trim();
    final sandi = _sandiLogin.text.trim();
    if (email.isEmpty) {
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Email login kosong.',
      );
      return;
    }
    if (sandi.isEmpty) {
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Kata sandi login kosong.',
      );
      return;
    }
    try {
      await Clipboard.setData(
        ClipboardData(text: 'Email: $email\nKata sandi: $sandi'),
      );
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Email dan kata sandi disalin ke papan klip.',
      );
    } catch (_) {
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Gagal menyalin ke papan klip.',
      );
    }
  }

  Future<void> _sinkronkanKredensialKeSupabaseAuth({
    required String email,
    required String sandi,
  }) async {
    final serviceRoleKey = supabaseServiceRoleKey;
    if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
      throw Exception(
        'Konfigurasi SUPABASE_SERVICE_ROLE_KEY belum tersedia. '
        'Untuk sinkron kredensial ke Supabase Auth diperlukan service role key.',
      );
    }

    final baseUrl = supabaseUrl;
    final url = Uri.parse('$baseUrl/auth/v1/admin/users/$_idAuthTarget');

    final payload = jsonEncode({'email': email, 'password': sandi});

    final respons = await http.put(
      url,
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
      body: payload,
    );

    if (respons.statusCode >= 200 && respons.statusCode < 300) {
      return;
    }

    final teks = respons.body.isNotEmpty ? respons.body : 'Respon kosong';
    final rendah = teks.toLowerCase();

    if (rendah.contains('user not found') || rendah.contains('not found')) {
      final buatUrl = Uri.parse('$baseUrl/auth/v1/admin/users');
      final buatRespons = await http.post(
        buatUrl,
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': sandi,
          'email_confirm': true,
        }),
      );

      if (buatRespons.statusCode < 200 || buatRespons.statusCode >= 300) {
        final bodyBuat = buatRespons.body.isNotEmpty
            ? buatRespons.body
            : 'Respon kosong';
        throw Exception('Gagal membuat akun Auth baru: $bodyBuat');
      }

      final map = jsonDecode(buatRespons.body) as Map<String, dynamic>;
      final idBaru = map['id']?.toString();
      if (idBaru == null || idBaru.isEmpty) {
        throw Exception('Gagal membaca id user Auth baru.');
      }

      await _penggunaSumber.perbaruiIdAuth(
        idPengguna: widget.karyawanAwal.id,
        idAuthBaru: idBaru,
      );
      _idAuthTarget = idBaru;
      return;
    }

    throw Exception('Sinkron Supabase Auth gagal: $teks');
  }

  Future<void> _simpan() async {
    if (!_kunciForm.currentState!.validate() || _profil == null) {
      return;
    }

    final sesi = WarisanSesi.dari(context);
    final p = sesi.pengguna;
    if (p == null || !p.isOwner) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan:
            'Akses ditolak. Hanya pemilik toko yang dapat mengubah data karyawan.',
      );
      return;
    }

    setState(() => _sedangMenyimpan = true);
    try {
      String? fotoUrl = _profil!.fotoUrl;
      if (_fotoBaruBytes != null && _fotoBaruEkstensi != null) {
        fotoUrl = await _profilSumber.unggahFoto(
          penggunaId: widget.karyawanAwal.id,
          bytes: _fotoBaruBytes!,
          ekstensi: _fotoBaruEkstensi!,
        );
      }

      await _profilSumber.simpanProfil(_modelDariForm(fotoUrl: fotoUrl));

      await _penggunaSumber.perbaruiNama(
        idPengguna: widget.karyawanAwal.id,
        namaLengkap: _nama.text.trim(),
      );

      if (_kredensialSunting) {
        final emailBaru = _emailLogin.text.trim();
        final sandiBaru = _sandiLogin.text.trim();

        if (emailBaru.isEmpty || !_validEmail(emailBaru)) {
          if (!mounted) return;
          tampilkanSnackbarSarypos(
            context,
            tipe: TipeSnackbarSarypos.error,
            pesan: 'Email login tidak valid.',
          );
          return;
        }

        if (sandiBaru.length < 6) {
          if (!mounted) return;
          tampilkanSnackbarSarypos(
            context,
            tipe: TipeSnackbarSarypos.error,
            pesan: 'Kata sandi login minimal 6 karakter.',
          );
          return;
        }

        await _sinkronkanKredensialKeSupabaseAuth(
          email: emailBaru,
          sandi: sandiBaru,
        );

        await _penggunaSumber.perbaruiEmailDanSandiLogin(
          idPengguna: widget.karyawanAwal.id,
          email: emailBaru,
          sandiLogin: sandiBaru,
        );
      }

      if (!mounted) {
        return;
      }
      final oid = WarisanSesi.dari(context).pengguna?.id;
      if (oid != null) {
        catatLogAktivitas(
          idPengguna: oid,
          jenis: JenisLogAktivitas.karyawanUbah,
          deskripsi: 'Memperbarui karyawan: ${_nama.text.trim()}',
          metadataJson: {'pengguna_id': widget.karyawanAwal.id},
        );
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Data tersimpan.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan:
            'Gagal menyimpan.\n${_ringkasErrorUntukSnackbar(e)}\n\n'
            'Jika RLS / Storage: jalankan 20260326130200_app_kuliah_longgar_rls.sql di Supabase.',
      );
    } finally {
      if (mounted) {
        setState(() => _sedangMenyimpan = false);
      }
    }
  }

  Future<void> _idCardBagikan() async {
    final p = _profil ?? ProfilKaryawanModel.kosong(widget.karyawanAwal.id);
    final pg = PenggunaModel(
      id: widget.karyawanAwal.id,
      idAuth: widget.karyawanAwal.idAuth,
      namaLengkap: _nama.text.trim(),
      email: widget.karyawanAwal.email,
      peran: widget.karyawanAwal.peran,
      aktif: widget.karyawanAwal.aktif,
    );
    try {
      await bagikanIdCardPdf(pengguna: pg, profil: p);
    } catch (_) {
      if (mounted) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Gagal membuat PDF.',
        );
      }
    }
  }

  Future<void> _idCardCetak() async {
    final p = _profil ?? ProfilKaryawanModel.kosong(widget.karyawanAwal.id);
    final pg = PenggunaModel(
      id: widget.karyawanAwal.id,
      idAuth: widget.karyawanAwal.idAuth,
      namaLengkap: _nama.text.trim(),
      email: widget.karyawanAwal.email,
      peran: widget.karyawanAwal.peran,
      aktif: widget.karyawanAwal.aktif,
    );
    try {
      await pratinjauCetakIdCard(pengguna: pg, profil: p);
    } catch (_) {
      if (mounted) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Gagal membuka dialog cetak.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fTanggal = DateFormat('d MMMM yyyy');

    return Scaffold(
      appBar: AppBarSarypos(
        judul: 'Profil Karyawan',
        aksi: [
          IconButton(
            tooltip: 'Bagikan PDF ID card',
            icon: const Icon(Icons.share_outlined),
            onPressed: (_sedangMuat || _sedangMenyimpan)
                ? null
                : _idCardBagikan,
          ),
          IconButton(
            tooltip: 'Cetak ID card',
            icon: const Icon(Icons.print_outlined),
            onPressed: (_sedangMuat || _sedangMenyimpan) ? null : _idCardCetak,
          ),
        ],
      ),
      body: _sedangMuat
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _kunciForm,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Manajemen HR: ubah nama tampilan dan data di bawah. Email dan sandi login dapat disunting oleh pemilik.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kredensial login',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: warnaAksenJudulBagian(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Salin email dan kata sandi',
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: _sedangMenyimpan
                              ? null
                              : _salinEmailDanSandiGabungan,
                        ),
                        IconButton(
                          tooltip: 'Sunting kredensial',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: _sedangMenyimpan
                              ? null
                              : _ketukSuntingKredensial,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailLogin,
                      decoration: const InputDecoration(
                        labelText: 'Email login',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [TanpaEmojiFormatter()],
                      enabled: !_sedangMenyimpan && _kredensialSunting,
                      validator: (v) {
                        if (!_kredensialSunting) return null;
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Email wajib diisi';
                        if (!_validEmail(t)) return 'Email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sandiLogin,
                      obscureText: !_tampilkanSandiLogin,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi login',
                        suffixIcon: IconButton(
                          tooltip: _tampilkanSandiLogin
                              ? 'Sembunyikan kata sandi'
                              : 'Tampilkan kata sandi',
                          icon: Icon(
                            _tampilkanSandiLogin
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() {
                            _tampilkanSandiLogin = !_tampilkanSandiLogin;
                          }),
                        ),
                      ),
                      inputFormatters: [TanpaEmojiFormatter()],
                      enabled: !_sedangMenyimpan && _kredensialSunting,
                      validator: (v) {
                        if (!_kredensialSunting) return null;
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Kata sandi wajib diisi';
                        if (t.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const Divider(height: 24, thickness: 1),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nama,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                      ),
                      enabled: !_sedangMenyimpan,
                      inputFormatters: [TanpaEmojiFormatter()],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jabatan,
                      decoration: const InputDecoration(
                        labelText: 'Jabatan',
                        hintText: 'Mis. Kasir',
                      ),
                      enabled: !_sedangMenyimpan,
                      inputFormatters: [TanpaEmojiFormatter()],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gaji,
                      decoration: const InputDecoration(
                        labelText: 'Gaji bulanan (Rp)',
                      ),
                      enabled: !_sedangMenyimpan,
                      keyboardType: TextInputType.number,
                      inputFormatters: [TanpaEmojiFormatter()],
                      validator: (v) => _validasiBilanganNonNegatifOpsional(
                        v,
                        'Gaji bulanan',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mulai Bekerja'),
                      subtitle: Text(
                        _mulaiKerja == null
                            ? 'Belum diatur'
                            : fTanggal.format(_mulaiKerja!),
                      ),
                      trailing: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _sedangMenyimpan
                            ? null
                            : () async {
                                final t = await showDatePicker(
                                  context: context,
                                  initialDate: _mulaiKerja ?? DateTime.now(),
                                  firstDate: DateTime(1990),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365 * 2),
                                  ),
                                );
                                if (t != null) {
                                  setState(() => _mulaiKerja = t);
                                }
                              },
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      key: ValueKey(_hariGajian),
                      decoration: const InputDecoration(
                        labelText: 'Tanggal gajian (hari dalam bulan)',
                      ),
                      initialValue: _hariGajian,
                      items: List.generate(
                        31,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      validator: (v) {
                        if (v == null) return null;
                        if (v < 1 || v > 31) {
                          return 'Tanggal gajian tidak valid';
                        }
                        return null;
                      },
                      onChanged: _sedangMenyimpan
                          ? null
                          : (v) => setState(() => _hariGajian = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _catatan,
                      decoration: const InputDecoration(
                        labelText: 'Catatan internal',
                      ),
                      enabled: !_sedangMenyimpan,
                      inputFormatters: [TanpaEmojiFormatter()],
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_profil?.fotoUrl != null && _fotoBaruBytes == null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _profil!.fotoUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(
                                width: 72,
                                height: 72,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        if (_fotoBaruBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _fotoBaruBytes!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _sedangMenyimpan ? null : _pilihFoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Pilih foto'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sedangMenyimpan ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WarnaSarypos.saryRed,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _sedangMenyimpan
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Simpan perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
