import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/core/penjaga_rute_owner.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/data/models/stok_model.dart';
import 'package:sarypos/data/sources/produk_dan_stok_sumber.dart';
import 'package:sarypos/core/formatter_tanpa_emoji.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanStok extends StatefulWidget {
  const HalamanStok({super.key});

  @override
  State<HalamanStok> createState() => _HalamanStokState();
}

class _HalamanStokState extends State<HalamanStok> {
  final _sumber = ProdukDanStokSumber();
  bool _sedangMemuat = false;
  String? _pesanError;
  List<StokModel> _stok = [];

  @override
  void initState() {
    super.initState();
    _muatStok();
  }

  Future<void> _muatStok() async {
    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    try {
      final hasil = await _sumber.ambilStokDenganProduk();
      setState(() {
        _stok = hasil;
      });
    } catch (e) {
      setState(() {
        _pesanError = 'Gagal memuat data stok. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        _sedangMemuat = false;
      });
    }
  }

  String _statusUntuk(StokModel stok) {
    if (stok.jumlah <= 0) {
      return 'Habis';
    }
    if (stok.jumlah <= stok.batasKritis) {
      return 'Kritis';
    }
    return 'Normal';
  }

  Color _warnaStatusUntuk(StokModel stok) {
    if (stok.jumlah <= 0) {
      return WarnaSarypos.saryRed;
    }
    if (stok.jumlah <= stok.batasKritis) {
      return WarnaSarypos.saryGold;
    }
    return WarnaSarypos.deepTeal;
  }

  Future<void> _tampilkanDialogSesuaikan(StokModel stok) async {
    final kontrol = TextEditingController(text: stok.jumlah.toString());
    final kunciForm = GlobalKey<FormState>();
    final nilaiBaru = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sesuaikan Stok ${stok.namaProduk}'),
          content: Form(
            key: kunciForm,
            child: TextFormField(
              controller: kontrol,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah stok baru'),
              inputFormatters: [TanpaEmojiFormatter()],
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Jumlah stok wajib diisi';
                if (t.contains('-')) return 'Jumlah stok tidak boleh negatif';
                if (!RegExp(r'^[0-9]+$').hasMatch(t)) {
                  return 'Jumlah stok harus angka bulat';
                }
                final p = int.tryParse(t);
                if (p == null) return 'Jumlah stok tidak valid';
                if (p < 0) return 'Jumlah stok tidak boleh negatif';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final st = kunciForm.currentState;
                if (st == null || !st.validate()) {
                  return;
                }
                final p = int.parse(kontrol.text.trim());
                Navigator.of(context).pop<int>(p);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (nilaiBaru == null) {
      return;
    }

    final lama = stok.jumlah;
    try {
      await _sumber.perbaruiJumlahStok(stokId: stok.id, jumlahBaru: nilaiBaru);
      if (mounted && penggunaAdalahOwner(context)) {
        catatLogAktivitas(
          idPengguna: WarisanSesi.dari(context).pengguna?.id,
          jenis: JenisLogAktivitas.ubahStok,
          deskripsi: '${stok.namaProduk}: $lama → $nilaiBaru',
          metadataJson: {'produk_id': stok.produkId},
        );
      }
      if (mounted) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.sukses,
          pesan: 'Stok ${stok.namaProduk} diperbarui.',
        );
      }
    } catch (_) {
      if (mounted) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Gagal menyimpan perubahan stok.',
        );
      }
    } finally {
      await _muatStok();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget isi;
    if (_sedangMemuat) {
      isi = const Center(child: CircularProgressIndicator());
    } else if (_pesanError != null) {
      isi = EmptyStateGenerik(
        ikon: Icons.error_outline,
        judul: 'Gagal Memuat Stok',
        pesan: _pesanError!,
        labelTombol: 'Coba lagi',
        onTekanTombol: _muatStok,
      );
    } else if (_stok.isEmpty) {
      isi = const EmptyStateGenerik(
        ikon: Icons.inventory_2_outlined,
        judul: 'Belum Ada Data Stok',
        pesan: 'Tambahkan produk dan stok terlebih dahulu.',
      );
    } else {
      isi = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stok Produk', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, indeks) {
                  final stok = _stok[indeks];
                  final status = _statusUntuk(stok);
                  final warnaStatus = _warnaStatusUntuk(stok);

                  final owner = penggunaAdalahOwner(context);
                  return CardSarypos(
                    child: ListTile(
                      title: Text(stok.namaProduk),
                      subtitle: Text(
                        owner
                            ? 'Jumlah: ${stok.jumlah}'
                            : 'Jumlah: ${stok.jumlah} · hanya pemilik yang dapat menyesuaikan stok',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: warnaStatus.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: warnaStatus,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (owner)
                            TextButton(
                              onPressed: () => _tampilkanDialogSesuaikan(stok),
                              child: const Text('Sesuaikan'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemCount: _stok.length,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarSarypos(judul: 'Stok'),
      body: SafeArea(child: isi),
    );
  }
}
