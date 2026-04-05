import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/core/formatter_tanpa_emoji.dart';
import 'package:sarypos/data/sources/pengguna_sumber.dart';
import 'package:sarypos/data/sources/supabase_klien.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanDaftarOwner extends StatefulWidget {
  const HalamanDaftarOwner({super.key, required this.pengatur});

  final PengaturSesi pengatur;

  @override
  State<HalamanDaftarOwner> createState() => _HalamanDaftarOwnerState();
}

class _HalamanDaftarOwnerState extends State<HalamanDaftarOwner> {
  final _kunciForm = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _penggunaSumber = PenggunaSumber();
  bool _sedangKirim = false;

  bool _validEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_kunciForm.currentState!.validate()) {
      return;
    }

    final sudahAdaOwner = await _penggunaSumber.apakahAdaOwnerAktif();
    if (sudahAdaOwner) {
      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Owner sudah terdaftar. Gunakan halaman masuk.',
      );
      return;
    }

    setState(() => _sedangKirim = true);
    try {
      final respons = await supabaseKlien.auth.signUp(
        email: _email.text.trim(),
        password: _sandi.text,
      );
      final user = respons.user;
      if (user == null) {
        throw Exception(
          'Registrasi ditolak. Aktifkan konfirmasi email di Supabase jika perlu.',
        );
      }

      final pg = await _penggunaSumber.sisipkanPengguna(
        idAuth: user.id,
        namaLengkap: _nama.text.trim(),
        email: _email.text.trim(),
        peran: 'owner',
      );

      catatLogAktivitas(
        idPengguna: pg.id,
        jenis: JenisLogAktivitas.registrasiOwner,
        deskripsi: 'Pemilik toko terdaftar: ${pg.namaLengkap}',
      );

      await widget.pengatur.rangkumSesaiAutentikasi();

      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Pemilik toko terdaftar. Selamat datang.',
      );
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      final t = e.toString();
      final bentrokOwner =
          t.contains('sarypos_satu_owner_aktif') ||
          t.contains('23505') ||
          t.toLowerCase().contains('unique') ||
          t.contains('Sudah ada pemilik aktif');
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: bentrokOwner
            ? 'Sudah ada pemilik aktif. Gunakan masuk pemilik atau nonaktifkan duplikat di database.'
            : 'Gagal mendaftar. Coba lagi atau periksa pengaturan Supabase Auth.',
      );
    } finally {
      if (mounted) {
        setState(() => _sedangKirim = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarSarypos(judul: 'Daftar Pemilik Toko'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Buat akun pemilik toko. Pastikan belum ada owner aktif di basis data.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Form(
              key: _kunciForm,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nama,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                    ),
                    inputFormatters: [TanpaEmojiFormatter()],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [TanpaEmojiFormatter()],
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Wajib diisi';
                      if (!_validEmail(t)) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sandi,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Kata sandi'),
                    inputFormatters: [TanpaEmojiFormatter()],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (v.trim().isEmpty)
                        return 'Kata sandi tidak boleh kosong';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sedangKirim ? null : _daftar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarnaSarypos.saryRed,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _sedangKirim
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Daftar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
