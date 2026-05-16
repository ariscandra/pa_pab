import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/bantuan_tawarkan_biometrik_owner.dart';
import 'package:sarypos/core/pengatur_sesi.dart';
import 'package:sarypos/core/penyimpanan_biometrik_owner.dart';
import 'package:sarypos/core/formatter_tanpa_emoji.dart';
import 'package:sarypos/features/auth/halaman_daftar_owner.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({
    super.key,
    required this.pengatur,
    this.dariTabSaya = false,
  });

  final PengaturSesi pengatur;
  final bool dariTabSaya;

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  final _kunciForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _buahLokal = LocalAuthentication();

  bool _sedangMasuk = false;
  bool _punyaMasukBiometrik = false;
  bool _sembunyikanSandi = true;

  bool _validEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _perbaruiRiwayatBiometrik();
  }

  Future<void> _perbaruiRiwayatBiometrik() async {
    final penyimpanan = PenyimpananBiometrikOwner();
    final aktif = await penyimpanan.biometrikDiaktifkan();
    final kredensial = await penyimpanan.bacaKredensial();
    if (!mounted) {
      return;
    }
    setState(() {
      _punyaMasukBiometrik = aktif && kredensial != null;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masukBiometrik() async {
    setState(() => _sedangMasuk = true);
    try {
      final penyimpanan = PenyimpananBiometrikOwner();
      final kred = await penyimpanan.bacaKredensial();
      if (!mounted) {
        return;
      }
      if (kred == null) {
        setState(() {
          _sedangMasuk = false;
          _punyaMasukBiometrik = false;
        });
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Masuk cepat pemilik tidak tersimpan. Gunakan email dan sandi.',
        );
        return;
      }

      final sah = await _buahLokal.authenticate(
        localizedReason: 'Buka aplikasi pemilik menggunakan biometrik perangkat.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!mounted) {
        return;
      }
      if (!sah) {
        setState(() => _sedangMasuk = false);
        return;
      }

      final error = await widget.pengatur.masuk(
        email: kred.email,
        sandi: kred.sandi,
      );

      if (!mounted) {
        return;
      }
      setState(() => _sedangMasuk = false);

      if (error != null) {
        await penyimpanan.hapusSemua();
        if (!mounted) {
          return;
        }
        setState(() => _punyaMasukBiometrik = false);
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Sesudah kata sandi diubah, masuk lagi dengan sandi baru.',
        );
        return;
      }

      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Selamat datang.',
      );
      if (widget.dariTabSaya && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _sedangMasuk = false);
      }
    }
  }

  Future<void> _prosesMasuk() async {
    if (!_kunciForm.currentState!.validate()) {
      return;
    }
    setState(() => _sedangMasuk = true);
    final error = await widget.pengatur.masuk(
      email: _email.text.trim(),
      sandi: _sandi.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _sedangMasuk = false);
    if (error != null) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Login gagal. Periksa email dan kata sandi.',
      );
      return;
    }

    await tawarkanAktivasiBiometrikOwnerSesudahKredensialValid(
      konteks: context,
      pengatur: widget.pengatur,
      email: _email.text.trim(),
      sandi: _sandi.text,
    );
    if (!mounted) {
      return;
    }
    await _perbaruiRiwayatBiometrik();

    if (!mounted) {
      return;
    }
    tampilkanSnackbarSarypos(
      context,
      tipe: TipeSnackbarSarypos.sukses,
      pesan: 'Selamat datang.',
    );
    if (widget.dariTabSaya && context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaOwner = widget.pengatur.adaOwnerAktif != false;
    final isi = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!widget.dariTabSaya) const SizedBox(height: 32),
        Text(
          'Masuk',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: warnaAksenJudulBagian(context),
            fontWeight: FontWeight.bold,
          ),
          textAlign: widget.dariTabSaya ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Gunakan akun Anda untuk mengakses fitur sesuai peran.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_punyaMasukBiometrik) ...[
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _sedangMasuk ? null : _masukBiometrik,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Masuk pemilik cepat'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: warnaAksenJudulBagian(context),
            ),
          ),
        ],
        const SizedBox(height: 28),
        Form(
          key: _kunciForm,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                enabled: !_sedangMasuk,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                inputFormatters: [TanpaEmojiFormatter()],
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Email wajib diisi';
                  if (!_validEmail(t)) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sandi,
                enabled: !_sedangMasuk,
                autofillHints: const [AutofillHints.password],
                obscureText: _sembunyikanSandi,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _sedangMasuk ? null : (_) => _prosesMasuk(),
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  suffixIcon: IconButton(
                    tooltip: _sembunyikanSandi ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                    onPressed: () {
                      setState(() => _sembunyikanSandi = !_sembunyikanSandi);
                    },
                    icon: Icon(
                      _sembunyikanSandi
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                inputFormatters: [TanpaEmojiFormatter()],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                  if (v.trim().isEmpty) return 'Kata sandi tidak boleh kosong';
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
            onPressed: _sedangMasuk ? null : _prosesMasuk,
            style: ElevatedButton.styleFrom(
              backgroundColor: WarnaSarypos.saryRed,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _sedangMasuk
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Text('Masuk'),
          ),
        ),
        if (adaOwner == false) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              final sukses = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => HalamanDaftarOwner(pengatur: widget.pengatur),
                ),
              );
              if (!context.mounted) {
                return;
              }
              if (sukses == true &&
                  widget.dariTabSaya &&
                  Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Belum ada akun manajemen? Daftar sekali saja'),
          ),
        ],
      ],
    );

    if (widget.dariTabSaya) {
      return Scaffold(
        appBar: const AppBarSarypos(judul: 'Akun'),
        body: SafeArea(child: isi),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: isi,
          ),
        ),
      ),
    );
  }
}
