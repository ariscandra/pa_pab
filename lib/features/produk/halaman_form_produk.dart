import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/formatter_tanpa_emoji.dart';
import 'package:sarypos/core/warisan_sesi.dart';
import 'package:sarypos/data/models/produk_inventaris_model.dart';
import 'package:sarypos/data/sources/produk_dan_stok_sumber.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';
import 'package:sarypos/widgets/snackbar_sarypos.dart';

class HalamanFormProduk extends StatefulWidget {
  const HalamanFormProduk({super.key, this.produkAwal});

  final ProdukInventarisModel? produkAwal;

  @override
  State<HalamanFormProduk> createState() => _HalamanFormProdukState();
}

class _HalamanFormProdukState extends State<HalamanFormProduk> {
  final _kunciForm = GlobalKey<FormState>();
  final _sumber = ProdukDanStokSumber();
  final _picker = ImagePicker();

  final _nama = TextEditingController();
  final _harga = TextEditingController();
  final _kategori = TextEditingController();

  final _stok = TextEditingController();
  final _batasKritis = TextEditingController();

  bool _sedangMenyimpan = false;
  DateTime? _tanggalKadaluarsa;
  bool _aktif = true;

  List<String> _saranKategori = [];

  Uint8List? _fotoBaruBytes;
  String? _fotoBaruEkstensi;

  String? get _gambarUrlLama => widget.produkAwal?.produk.gambarUrl;

  bool _pastikanSesiValid() {
    final pengaturSesi = WarisanSesi.dari(context);
    if (pengaturSesi.sedangMemeriksaSesi) return false;
    final sesi = pengaturSesi.pengguna;
    if (sesi == null) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Sesi tidak valid.',
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.produkAwal?.produk;
    final s = widget.produkAwal?.stok;
    if (p != null) {
      _nama.text = p.nama;
      _harga.text = '${p.harga}';
      _kategori.text = p.kategori ?? '';
      _tanggalKadaluarsa = p.tanggalKadaluarsa;
      _aktif = p.aktif;
    }
    if (s != null) {
      _stok.text = '${s.jumlah}';
      _batasKritis.text = '${s.batasKritis}';
    }
    _muatSaranKategori();
  }

  Future<void> _muatSaranKategori() async {
    try {
      final d = await _sumber.ambilDaftarKategoriUnik();
      if (mounted) {
        setState(() => _saranKategori = d);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saranKategori = []);
      }
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _kategori.dispose();
    _stok.dispose();
    _batasKritis.dispose();
    super.dispose();
  }

  static int? _parseIntNonNegatif(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.contains('-')) return null;
    if (RegExp(r'[A-Za-z]').hasMatch(t)) return null;
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _pilihGambar() async {
    if (kIsWeb) {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.single;
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) return;

      final name = f.name.toLowerCase();
      final ext = name.endsWith('.png')
          ? 'png'
          : name.endsWith('.webp')
          ? 'webp'
          : name.endsWith('.gif')
          ? 'gif'
          : 'jpg';
      setState(() {
        _fotoBaruBytes = Uint8List.fromList(bytes);
        _fotoBaruEkstensi = ext;
      });
      return;
    }

    final pilih = await showModalBottomSheet<_SumberFoto>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(ctx).pop(_SumberFoto.kamera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeri'),
                onTap: () => Navigator.of(ctx).pop(_SumberFoto.galeri),
              ),
            ],
          ),
        );
      },
    );
    if (pilih == null) return;

    final source = pilih == _SumberFoto.kamera
        ? ImageSource.camera
        : ImageSource.gallery;

    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (x == null) return;

    final bytes = await x.readAsBytes();
    final name = x.name.toLowerCase();
    final ext = name.endsWith('.png')
        ? 'png'
        : name.endsWith('.webp')
        ? 'webp'
        : name.endsWith('.gif')
        ? 'gif'
        : 'jpg';

    setState(() {
      _fotoBaruBytes = bytes;
      _fotoBaruEkstensi = ext;
    });
  }

  Future<void> _pilihTanggalKadaluarsa() async {
    final initial = _tanggalKadaluarsa ?? DateTime.now();
    final t = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (t == null) return;
    setState(() => _tanggalKadaluarsa = t);
  }

  Future<void> _simpan() async {
    if (!_pastikanSesiValid()) return;
    final valid = _kunciForm.currentState?.validate() ?? false;
    if (!valid) return;
    if (_tanggalKadaluarsa == null) {
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Tanggal kadaluarsa wajib diisi.',
      );
      return;
    }

    setState(() => _sedangMenyimpan = true);
    try {
      final nama = _nama.text.trim();
      final harga = _parseIntNonNegatif(_harga.text) ?? 0;
      final kategori = _kategori.text.trim();
      if (kategori.isEmpty) {
        tampilkanSnackbarSarypos(
          context,
          tipe: TipeSnackbarSarypos.error,
          pesan: 'Kategori wajib diisi.',
        );
        return;
      }
      final stokJumlah = _parseIntNonNegatif(_stok.text) ?? 0;
      final batasKritis = _parseIntNonNegatif(_batasKritis.text) ?? 0;

      if (widget.produkAwal == null) {
        await _sumber.buatProduk(
          nama: nama,
          harga: harga,
          aktif: _aktif,
          kategori: kategori,
          tanggalKadaluarsa: _tanggalKadaluarsa!,
          stokJumlah: stokJumlah,
          batasKritis: batasKritis,
          gambarBytes: _fotoBaruBytes,
          gambarEkstensi: _fotoBaruEkstensi,
        );
      } else {
        await _sumber.ubahProduk(
          produkId: widget.produkAwal!.produk.id,
          nama: nama,
          harga: harga,
          aktif: _aktif,
          kategori: kategori,
          tanggalKadaluarsa: _tanggalKadaluarsa!,
          stokJumlah: stokJumlah,
          batasKritis: batasKritis,
          gambarBytes: _fotoBaruBytes,
          gambarEkstensi: _fotoBaruEkstensi,
          gambarUrlLama: _gambarUrlLama,
        );
      }

      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.sukses,
        pesan: 'Produk tersimpan.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      tampilkanSnackbarSarypos(
        context,
        tipe: TipeSnackbarSarypos.error,
        pesan: 'Gagal menyimpan produk. Periksa koneksi.',
      );
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('d MMM yyyy');
    final mode = widget.produkAwal == null ? 'Tambah Produk' : 'Edit Produk';

    return Scaffold(
      appBar: AppBarSarypos(judul: mode),
      body: SafeArea(
        child: Form(
          key: _kunciForm,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Isi data produk. Unggah gambar dari kamera atau galeri (di web memakai pemilih file).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nama,
                enabled: !_sedangMenyimpan,
                decoration: const InputDecoration(labelText: 'Nama produk'),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Nama produk wajib diisi';
                  if (t.length < 2) return 'Nama terlalu pendek';
                  return null;
                },
                inputFormatters: [TanpaEmojiFormatter()],
              ),
              const SizedBox(height: 16),

              TypeAheadField<String>(
                controller: _kategori,
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_sedangMenyimpan,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Cari yang ada atau ketik baru',
                      suffixIcon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) {
                        return 'Kategori wajib diisi';
                      }
                      return null;
                    },
                    inputFormatters: [TanpaEmojiFormatter()],
                  );
                },
                suggestionsCallback: (search) async {
                  final q = search.trim().toLowerCase();
                  if (q.isEmpty) {
                    return _saranKategori.take(14).toList();
                  }
                  return _saranKategori
                      .where((k) => k.toLowerCase().contains(q))
                      .take(20)
                      .toList();
                },
                itemBuilder: (context, kategori) {
                  return ListTile(dense: true, title: Text(kategori));
                },
                onSelected: (kategori) {
                  _kategori.text = kategori;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _harga,
                enabled: !_sedangMenyimpan,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
                inputFormatters: [TanpaEmojiFormatter()],
                validator: (v) {
                  final n = _parseIntNonNegatif(v);
                  if (n == null) return 'Harga wajib angka bulat (>= 0)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal Kadaluarsa'),
                subtitle: Text(
                  _tanggalKadaluarsa == null
                      ? 'Belum dipilih'
                      : f.format(_tanggalKadaluarsa!),
                ),
                trailing: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _sedangMenyimpan ? null : _pilihTanggalKadaluarsa,
                ),
              ),
              const SizedBox(height: 6),
              if (_tanggalKadaluarsa == null)
                Text(
                  'Wajib diisi agar beranda bisa menampilkan produk yang mendekati kadaluarsa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _stok,
                enabled: !_sedangMenyimpan,
                decoration: const InputDecoration(labelText: 'Stok saat ini'),
                keyboardType: TextInputType.number,
                inputFormatters: [TanpaEmojiFormatter()],
                validator: (v) {
                  final n = _parseIntNonNegatif(v);
                  if (n == null) return 'Stok wajib angka bulat (>= 0)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _batasKritis,
                enabled: !_sedangMenyimpan,
                decoration: const InputDecoration(
                  labelText: 'Batas kritis stok',
                  hintText: 'Stok ≤ nilai ini dianggap menipis',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [TanpaEmojiFormatter()],
                validator: (v) {
                  final n = _parseIntNonNegatif(v);
                  if (n == null) return 'Batas kritis wajib angka bulat (>= 0)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Produk Aktif'),
                subtitle: Text(
                  _aktif
                      ? 'Ditampilkan di POS dan beranda'
                      : 'Tidak ditampilkan di POS dan beranda',
                ),
                value: _aktif,
                onChanged: _sedangMenyimpan
                    ? null
                    : (v) => setState(() => _aktif = v),
              ),

              const SizedBox(height: 16),
              Text(
                'Gambar Produk',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  if (_fotoBaruBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _fotoBaruBytes!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (_gambarUrlLama != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _gambarUrlLama!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 72,
                            height: 72,
                            child: Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
                    ),
                  if (_fotoBaruBytes != null || _gambarUrlLama != null)
                    const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sedangMenyimpan ? null : _pilihGambar,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Pilih gambar'),
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SumberFoto { kamera, galeri }
