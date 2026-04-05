import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/format_rupiah.dart';
import 'package:sarypos/core/label_metode_pembayaran.dart';
import 'package:sarypos/core/layanan_catat_log.dart';
import 'package:sarypos/core/pengelola_notifikasi_in_app.dart';
import 'package:sarypos/core/warisan_notifikasi_in_app.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/data/models/item_keranjang.dart';
import 'package:sarypos/data/models/produk_model.dart';
import 'package:sarypos/data/models/stok_model.dart';
import 'package:sarypos/data/sources/produk_dan_stok_sumber.dart';
import 'package:sarypos/data/sources/transaksi_sumber.dart';
import 'package:sarypos/widgets/card_sarypos.dart';
import 'package:sarypos/widgets/empty_state_generik.dart';
import 'package:sarypos/widgets/skeleton_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';
import 'package:sarypos/core/formatter_tanpa_emoji.dart';

class HalamanPos extends StatefulWidget {
  const HalamanPos({super.key});

  @override
  State<HalamanPos> createState() => _HalamanPosState();
}

class _HalamanPosState extends State<HalamanPos> {
  final _produkSumber = ProdukDanStokSumber();
  final _transaksiSumber = TransaksiSumber();
  final List<ItemKeranjang> _keranjang = [];
  final Map<String, StokModel> _stokPerProduk = {};
  final TextEditingController _pencarianProduk = TextEditingController();
  final TextEditingController _potongan = TextEditingController(text: '0');

  bool _sedangMemuatProduk = false;
  bool _sedangMenyimpan = false;
  String? _pesanError;
  List<ProdukModel> _produk = [];
  String _metodePembayaran = 'tunai';
  bool _sudahPeringatanStokKritis = false;

  static const _kodeMetode = ['tunai', 'transfer', 'e_wallet', 'debit_kredit'];

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  @override
  void dispose() {
    _pencarianProduk.dispose();
    _potongan.dispose();
    super.dispose();
  }

  int get _subtotalKeranjang =>
      _keranjang.fold(0, (total, item) => total + item.subtotal);

  int _bacaPotonganMentah() {
    final digits = _potongan.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _muatProduk() async {
    setState(() {
      _sedangMemuatProduk = true;
      _pesanError = null;
    });

    try {
      final hasilProduk = await _produkSumber.ambilProdukAktif();
      List<StokModel> hasilStok = [];
      try {
        hasilStok = await _produkSumber.ambilStokDenganProduk();
      } catch (_) {
        hasilStok = [];
      }

      setState(() {
        _produk = hasilProduk;
        _stokPerProduk
          ..clear()
          ..addEntries(hasilStok.map((s) => MapEntry(s.produkId, s)));
      });

      if (!mounted) {
        return;
      }
      final kritis = hasilStok
          .where((s) => s.jumlah > 0 && s.jumlah <= s.batasKritis)
          .length;
      if (kritis > 0 && !_sudahPeringatanStokKritis) {
        _sudahPeringatanStokKritis = true;
        WarisanNotifikasiInApp.mungkinDari(context)?.tampilkan(
          tipe: TipeNotifikasiInApp.peringatan,
          pesan:
              '$kritis produk mendekati stok kritis. Cek menu Stok dari beranda.',
        );
      }
    } catch (e) {
      setState(() {
        _pesanError = 'Gagal memuat produk. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        _sedangMemuatProduk = false;
      });
    }
  }

  Future<void> _sinkronkanStokDariServer() async {
    try {
      final hasilStok = await _produkSumber.ambilStokDenganProduk();
      if (!mounted) {
        return;
      }
      setState(() {
        _stokPerProduk
          ..clear()
          ..addEntries(hasilStok.map((s) => MapEntry(s.produkId, s)));
      });
    } catch (_) {}
  }

  void _tambahKeKeranjang(ProdukModel produk) {
    final indeks = _keranjang.indexWhere((item) => item.produk.id == produk.id);
    final stok = _stokPerProduk[produk.id];
    final kuantitasSaatIni = indeks == -1 ? 0 : _keranjang[indeks].kuantitas;
    final kuantitasBaru = kuantitasSaatIni + 1;

    if (stok != null && kuantitasBaru > stok.jumlah) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Stok ${produk.nama} tidak mencukupi.',
      );
      return;
    }

    setState(() {
      if (indeks == -1) {
        _keranjang.add(ItemKeranjang(produk: produk, kuantitas: 1));
      } else {
        _keranjang[indeks].kuantitas = kuantitasBaru;
      }
    });
  }

  void _ubahKuantitas(ItemKeranjang item, int delta) {
    final stok = _stokPerProduk[item.produk.id];
    final kuantitasBaru = item.kuantitas + delta;

    if (delta > 0 && stok != null && kuantitasBaru > stok.jumlah) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Stok ${item.produk.nama} tidak mencukupi.',
      );
      return;
    }

    setState(() {
      item.kuantitas = kuantitasBaru;
      if (item.kuantitas <= 0) {
        _keranjang.removeWhere((i) => i.produk.id == item.produk.id);
      }
      if (_keranjang.isEmpty) {
        _potongan.text = '0';
      }
    });
  }

  Future<void> _ubahKuantitasLewatDialog(ItemKeranjang item) async {
    final stok = _stokPerProduk[item.produk.id];

    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return _DialogKuantitasProduk(
          namaProduk: item.produk.nama,
          stokTersedia: stok?.jumlah,
          initialKuantitas: item.kuantitas,
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (qty == null) return;

    if (qty == 0) {
      setState(() {
        _keranjang.removeWhere((i) => i.produk.id == item.produk.id);
        if (_keranjang.isEmpty) {
          _potongan.text = '0';
        }
      });
      return;
    }
    final stok2 = _stokPerProduk[item.produk.id];
    if (stok2 != null && qty > stok2.jumlah) {
      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Melebihi stok yang ada.',
      );
      return;
    }
    setState(() {
      item.kuantitas = qty;
    });
  }

  int get _totalBayar {
    final sub = _subtotalKeranjang;
    final pot = _bacaPotonganMentah();
    if (pot <= 0) {
      return sub;
    }
    final diterapkan = pot > sub ? sub : pot;
    return sub - diterapkan;
  }

  Future<void> _simpanTransaksi() async {
    if (_keranjang.isEmpty) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Keranjang masih kosong.',
      );
      return;
    }

    setState(() {
      _sedangMenyimpan = true;
    });

    final idPengguna = WarisanSesi.dari(context).pengguna?.id;
    if (idPengguna == null) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Sesi tidak valid.',
      );
      setState(() => _sedangMenyimpan = false);
      return;
    }
    final metodeSimpan = _metodePembayaran;
    if (!_kodeMetode.contains(metodeSimpan)) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Metode pembayaran tidak valid.',
      );
      setState(() => _sedangMenyimpan = false);
      return;
    }
    final subtotal = _subtotalKeranjang;
    final potonganMentah = _bacaPotonganMentah();
    if (potonganMentah < 0) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Potongan tidak boleh negatif.',
      );
      setState(() => _sedangMenyimpan = false);
      return;
    }
    if (potonganMentah > subtotal) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan:
            'Potongan tidak boleh melebihi subtotal (${formatRupiah(subtotal)}).',
      );
      setState(() => _sedangMenyimpan = false);
      return;
    }
    final totalSimpan = subtotal - potonganMentah;
    final labelMetode = labelMetodePembayaran(metodeSimpan);

    try {
      final idTrx = await _transaksiSumber.simpanTransaksi(
        idPengguna: idPengguna,
        itemKeranjang: _keranjang,
        metodePembayaran: metodeSimpan,
        totalAkhir: totalSimpan,
      );

      setState(() {
        _keranjang.clear();
        _metodePembayaran = 'tunai';
        _potongan.text = '0';
      });

      if (!mounted) {
        return;
      }

      final metaLog = <String, dynamic>{
        'metode': metodeSimpan,
        if (potonganMentah > 0) 'potongan': potonganMentah,
        if (potonganMentah > 0) 'subtotal': subtotal,
      };
      if (idTrx != null) {
        metaLog['transaksi_id'] = idTrx;
      }
      catatLogAktivitas(
        idPengguna: idPengguna,
        jenis: JenisLogAktivitas.transaksi,
        deskripsi: potonganMentah > 0
            ? 'Transaksi tersimpan · $labelMetode · ${formatRupiah(totalSimpan)} (potongan ${formatRupiah(potonganMentah)})'
            : 'Transaksi tersimpan · $labelMetode · ${formatRupiah(totalSimpan)}',
        metadataJson: metaLog,
      );

      if (!mounted) {
        return;
      }

      WarisanSesi.dari(context).tandaiTransaksiTersimpan();

      WarisanNotifikasiInApp.mungkinDari(context)?.tampilkan(
        tipe: TipeNotifikasiInApp.sukses,
        pesan: 'Transaksi berhasil dicatat.',
      );

      if (!mounted) {
        return;
      }
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Transaksi berhasil disimpan.',
      );
      await _sinkronkanStokDariServer();
    } catch (e) {
      if (!mounted) {
        return;
      }
      catatLogAktivitas(
        idPengguna: idPengguna,
        jenis: JenisLogAktivitas.error,
        deskripsi: 'Gagal menyimpan transaksi',
        metadataJson: {'detail': e.toString()},
      );
      WarisanNotifikasiInApp.mungkinDari(context)?.tampilkan(
        tipe: TipeNotifikasiInApp.error,
        pesan: 'Gagal menyimpan transaksi. Periksa koneksi.',
      );
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Gagal menyimpan transaksi. Silakan coba lagi.',
      );
    } finally {
      setState(() {
        _sedangMenyimpan = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kueriPencarian = _pencarianProduk.text.trim().toLowerCase();
    final produkTersaring = kueriPencarian.isEmpty
        ? _produk
        : _produk.where((item) {
            return item.nama.toLowerCase().contains(kueriPencarian) ||
                (item.kategori?.toLowerCase().contains(kueriPencarian) ??
                    false);
          }).toList();

    if (_sedangMemuatProduk) {
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lebarCukupLuas = constraints.maxWidth > 700;

            final kiri = _BangunanDaftarProdukSkeleton();
            final kanan = _BangunanRingkasanTransaksiSkeleton();

            final konten = lebarCukupLuas
                ? Row(
                    children: [
                      Expanded(flex: 2, child: kiri),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: kanan),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 3, child: kiri),
                      const SizedBox(height: 16),
                      Expanded(flex: 4, child: kanan),
                    ],
                  );

            return Padding(padding: const EdgeInsets.all(16), child: konten);
          },
        ),
      );
    }

    if (_pesanError != null) {
      return SafeArea(
        child: EmptyStateGenerik(
          ikon: Icons.error_outline,
          judul: 'Gagal Memuat Data',
          pesan: _pesanError!,
          labelTombol: 'Coba lagi',
          onTekanTombol: _muatProduk,
        ),
      );
    }

    if (_produk.isEmpty) {
      return const SafeArea(
        child: EmptyStateGenerik(
          ikon: Icons.inventory_2_outlined,
          judul: 'Belum Ada Produk',
          pesan: 'Tambahkan produk terlebih dahulu sebelum menggunakan kasir.',
        ),
      );
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lebarCukupLuas = constraints.maxWidth > 700;

          final konten = lebarCukupLuas
              ? Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _BangunanDaftarProduk(
                        produk: produkTersaring,
                        onPilihProduk: _tambahKeKeranjang,
                        controllerPencarian: _pencarianProduk,
                        onCariChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _BangunanRingkasanTransaksi(
                        keranjang: _keranjang,
                        subtotal: _subtotalKeranjang,
                        totalBayar: _totalBayar,
                        metodePembayaran: _metodePembayaran,
                        sedangMenyimpan: _sedangMenyimpan,
                        kodeMetode: _kodeMetode,
                        controllerPotongan: _potongan,
                        onPotonganChanged: () => setState(() {}),
                        onUbahKuantitas: _ubahKuantitas,
                        onKetukKuantitas: _ubahKuantitasLewatDialog,
                        onUbahMetodePembayaran: (nilaiBaru) {
                          setState(() {
                            _metodePembayaran = nilaiBaru;
                          });
                        },
                        onSimpan: _simpanTransaksi,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _BangunanDaftarProduk(
                        produk: produkTersaring,
                        onPilihProduk: _tambahKeKeranjang,
                        controllerPencarian: _pencarianProduk,
                        onCariChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 4,
                      child: _BangunanRingkasanTransaksi(
                        keranjang: _keranjang,
                        subtotal: _subtotalKeranjang,
                        totalBayar: _totalBayar,
                        metodePembayaran: _metodePembayaran,
                        sedangMenyimpan: _sedangMenyimpan,
                        kodeMetode: _kodeMetode,
                        controllerPotongan: _potongan,
                        onPotonganChanged: () => setState(() {}),
                        onUbahKuantitas: _ubahKuantitas,
                        onKetukKuantitas: _ubahKuantitasLewatDialog,
                        onUbahMetodePembayaran: (nilaiBaru) {
                          setState(() {
                            _metodePembayaran = nilaiBaru;
                          });
                        },
                        onSimpan: _simpanTransaksi,
                      ),
                    ),
                  ],
                );

          return Padding(padding: const EdgeInsets.all(16), child: konten);
        },
      ),
    );
  }
}

class _DialogKuantitasProduk extends StatefulWidget {
  const _DialogKuantitasProduk({
    required this.namaProduk,
    required this.stokTersedia,
    required this.initialKuantitas,
  });

  final String namaProduk;
  final int? stokTersedia;
  final int initialKuantitas;

  @override
  State<_DialogKuantitasProduk> createState() => _DialogKuantitasProdukState();
}

class _DialogKuantitasProdukState extends State<_DialogKuantitasProduk> {
  late final TextEditingController _kontrol;
  final _kunciForm = GlobalKey<FormState>();
  bool _sudahDiterapkan = false;

  @override
  void initState() {
    super.initState();
    _kontrol = TextEditingController(text: '${widget.initialKuantitas}');
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stok = widget.stokTersedia;

    return AlertDialog(
      title: Text('Jumlah: ${widget.namaProduk}'),
      content: Form(
        key: _kunciForm,
        child: TextFormField(
          controller: _kontrol,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Kuantitas',
            helperText: stok != null ? 'Stok tersedia: $stok' : null,
          ),
          inputFormatters: [TanpaEmojiFormatter()],
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return 'Kuantitas wajib diisi';
            if (t.contains('-')) return 'Kuantitas tidak boleh negatif';
            if (!RegExp(r'^[0-9]+$').hasMatch(t)) {
              return 'Kuantitas harus angka bulat';
            }
            final p = int.tryParse(t);
            if (p == null) return 'Kuantitas tidak valid';
            if (p < 0) return 'Kuantitas tidak boleh negatif';
            if (stok != null && p > stok) {
              return 'Melebihi stok yang ada.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sudahDiterapkan
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _sudahDiterapkan
              ? null
              : () {
                  final st = _kunciForm.currentState;
                  if (st == null || !st.validate()) {
                    return;
                  }

                  _sudahDiterapkan = true;
                  final teks = _kontrol.text.trim();
                  final p = int.parse(teks);
                  Navigator.of(context).pop(p);
                },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}

class _BangunanDaftarProduk extends StatelessWidget {
  const _BangunanDaftarProduk({
    required this.produk,
    required this.onPilihProduk,
    required this.controllerPencarian,
    required this.onCariChanged,
  });

  final List<ProdukModel> produk;
  final void Function(ProdukModel) onPilihProduk;
  final TextEditingController controllerPencarian;
  final ValueChanged<String> onCariChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Produk', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'SaryPOS adalah pendamping pencatatan di kasir, bukan pengganti mesin kasir utama.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllerPencarian,
          onChanged: onCariChanged,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Cari nama atau kategori',
            hintStyle: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
            prefixIcon: const Icon(Icons.search, size: 20),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 36,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: produk.isEmpty
              ? const EmptyStateGenerik(
                  ikon: Icons.search_off_outlined,
                  pesan: 'Produk tidak ditemukan untuk pencarian ini.',
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3,
                  ),
                  itemCount: produk.length,
                  itemBuilder: (context, indeks) {
                    final item = produk[indeks];
                    return CardSarypos(
                      elevation: 0,
                      tampilkanKonturTipis: true,
                      onTap: () => onPilihProduk(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.nama,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(height: 1.05),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatRupiah(item.harga),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BangunanRingkasanTransaksi extends StatelessWidget {
  const _BangunanRingkasanTransaksi({
    required this.keranjang,
    required this.subtotal,
    required this.totalBayar,
    required this.metodePembayaran,
    required this.sedangMenyimpan,
    required this.kodeMetode,
    required this.controllerPotongan,
    required this.onPotonganChanged,
    required this.onUbahKuantitas,
    required this.onKetukKuantitas,
    required this.onUbahMetodePembayaran,
    required this.onSimpan,
  });

  final List<ItemKeranjang> keranjang;
  final int subtotal;
  final int totalBayar;
  final String metodePembayaran;
  final bool sedangMenyimpan;
  final List<String> kodeMetode;
  final TextEditingController controllerPotongan;
  final VoidCallback onPotonganChanged;
  final void Function(ItemKeranjang item, int delta) onUbahKuantitas;
  final Future<void> Function(ItemKeranjang item) onKetukKuantitas;
  final void Function(String nilaiBaru) onUbahMetodePembayaran;
  final VoidCallback onSimpan;

  @override
  Widget build(BuildContext context) {
    final teksTema = Theme.of(context).textTheme;
    final adaItem = keranjang.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Transaksi', style: teksTema.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: keranjang.isEmpty
              ? const EmptyStateGenerik(
                  ikon: Icons.shopping_cart_outlined,
                  pesan: 'Belum ada item di keranjang.',
                )
              : ListView.separated(
                  itemBuilder: (context, indeks) {
                    final item = keranjang[indeks];
                    return ListTile(
                      title: Text(item.produk.nama),
                      subtitle: Text(
                        '${formatRupiah(item.produk.harga)} × ${item.kuantitas}',
                      ),
                      trailing: SizedBox(
                        width: 148,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: sedangMenyimpan
                                  ? null
                                  : () => onUbahKuantitas(item, -1),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            InkWell(
                              onTap: sedangMenyimpan
                                  ? null
                                  : () => onKetukKuantitas(item),
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.kuantitas}',
                                      style: teksTema.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: sedangMenyimpan
                                  ? null
                                  : () => onUbahKuantitas(item, 1),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const Divider(),
                  itemCount: keranjang.length,
                ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: metodePembayaran,
          decoration: const InputDecoration(labelText: 'Metode pembayaran'),
          items: kodeMetode
              .map(
                (k) => DropdownMenuItem(
                  value: k,
                  child: Text(labelMetodePembayaran(k)),
                ),
              )
              .toList(),
          onChanged: sedangMenyimpan
              ? null
              : (nilai) {
                  if (nilai != null) {
                    onUbahMetodePembayaran(nilai);
                  }
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controllerPotongan,
          enabled: !sedangMenyimpan && adaItem,
          keyboardType: TextInputType.number,
          onChanged: (_) => onPotonganChanged(),
          inputFormatters: [TanpaEmojiFormatter()],
          decoration: InputDecoration(
            labelText: 'Potongan (diskon/promo)',
            hintText: '0',
            helperText: adaItem
                ? 'Maks. ${formatRupiah(subtotal)} · mengurangi total yang dibayar'
                : 'Isi keranjang dulu untuk memakai potongan',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: teksTema.bodyMedium),
            Text(
              formatRupiah(subtotal),
              style: teksTema.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total dibayar', style: teksTema.titleMedium),
            Text(
              formatRupiah(totalBayar),
              style: teksTema.titleMedium?.copyWith(
                color: WarnaSarypos.saryRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: sedangMenyimpan || !adaItem ? null : onSimpan,
            style: ElevatedButton.styleFrom(
              backgroundColor: WarnaSarypos.saryRed,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: sedangMenyimpan
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Text('Simpan transaksi'),
          ),
        ),
      ],
    );
  }
}

class _BangunanDaftarProdukSkeleton extends StatelessWidget {
  const _BangunanDaftarProdukSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Produk', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'SaryPOS adalah pendamping pencatatan di kasir, bukan pengganti mesin kasir utama.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
            ),
            itemCount: 6,
            itemBuilder: (context, indeks) {
              return CardSarypos(
                elevation: 0,
                tampilkanKonturTipis: true,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            return SkeletonLine(
                              width: w,
                              height: 14,
                              borderRadius: 10,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SkeletonLine(
                        width: 54,
                        height: 14,
                        borderRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BangunanRingkasanTransaksiSkeleton extends StatelessWidget {
  const _BangunanRingkasanTransaksiSkeleton();

  @override
  Widget build(BuildContext context) {
    final teksTema = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Transaksi', style: teksTema.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, indeks) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: LayoutBuilder(
                  builder: (context, c) {
                    return SkeletonLine(
                      width: c.maxWidth * 0.7,
                      height: 14,
                      borderRadius: 10,
                    );
                  },
                ),
                subtitle: LayoutBuilder(
                  builder: (context, c) {
                    return SkeletonLine(
                      width: c.maxWidth * 0.55,
                      height: 12,
                      borderRadius: 10,
                    );
                  },
                ),
                trailing: SizedBox(
                  width: 148,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      SkeletonCircle(diameter: 20),
                      SizedBox(width: 8),
                      SkeletonBox(width: 52, height: 20, borderRadius: 10),
                      SizedBox(width: 8),
                      SkeletonCircle(diameter: 20),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const Divider(height: 4),
            itemCount: 3,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            return SkeletonBox(width: c.maxWidth, height: 56);
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLine(width: w * 0.25, height: 14, borderRadius: 10),
                const SkeletonLine(width: 140, height: 18, borderRadius: 10),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            return SkeletonBox(width: c.maxWidth, height: 52, borderRadius: 12);
          },
        ),
      ],
    );
  }
}
