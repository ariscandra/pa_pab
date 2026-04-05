import 'package:flutter/material.dart';
import 'package:sarypos/features/pos/halaman_pos.dart';
import 'package:sarypos/widgets/appbar_sarypos.dart';

class HalamanPencatatanTransaksi extends StatelessWidget {
  const HalamanPencatatanTransaksi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarSarypos(judul: 'Pencatatan Transaksi'),
      body: const HalamanPos(),
    );
  }
}
