import 'package:flutter/material.dart';
import 'package:sarypos/config/theme/sarypos_theme.dart';
import 'package:sarypos/core/pengatur_tema.dart';
import 'package:sarypos/core/warisan_tema.dart';

class AppBarSarypos extends StatelessWidget implements PreferredSizeWidget {
  const AppBarSarypos({super.key, required this.judul, this.aksi});

  final String judul;
  final List<Widget>? aksi;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fg = tema.appBarTheme.foregroundColor ?? tema.colorScheme.onTertiary;
    final pengaturTema = WarisanTema.dari(context);
    final pilihan = pengaturTema.pilihan;
    final warnaIkonAksi = fg.withValues(alpha: 0.78);
    final ikonTema = switch (pilihan) {
      PilihanTemaSarypos.ikutiSistem => Icons.brightness_auto_outlined,
      PilihanTemaSarypos.terang => Icons.light_mode_outlined,
      PilihanTemaSarypos.gelap => Icons.dark_mode_outlined,
    };
    final pilihanSelanjutnya = switch (pilihan) {
      PilihanTemaSarypos.ikutiSistem => PilihanTemaSarypos.terang,
      PilihanTemaSarypos.terang => PilihanTemaSarypos.gelap,
      PilihanTemaSarypos.gelap => PilihanTemaSarypos.ikutiSistem,
    };
    final tooltipTema = switch (pilihanSelanjutnya) {
      PilihanTemaSarypos.ikutiSistem => 'Ubah tema: ikuti sistem',
      PilihanTemaSarypos.terang => 'Ubah tema: terang',
      PilihanTemaSarypos.gelap => 'Ubah tema: gelap',
    };

    final aksiTema = [
      IconButton(
        tooltip: tooltipTema,
        onPressed: () => pengaturTema.atur(pilihanSelanjutnya),
        icon: Icon(ikonTema, color: warnaIkonAksi, size: 20),
      ),
    ];
    final gabunganAksi = [
      ...?aksi?.map(
        (item) => IconTheme.merge(
          data: IconThemeData(size: 20, color: warnaIkonAksi),
          child: Opacity(opacity: 0.9, child: item),
        ),
      ),
      ...aksiTema,
    ];

    return AppBar(
      backgroundColor: WarnaSarypos.deepTeal,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WarnaSarypos.deepTeal,
                    WarnaSarypos.deepTeal.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -44,
            top: -52,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WarnaSarypos.saryGold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -64,
            bottom: -88,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WarnaSarypos.saryRed.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: WarnaSarypos.saryGold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/sarymart_logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.storefront_outlined, size: 22, color: fg),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  judul,
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'SaryPOS · Sary Mart',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: fg.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: gabunganAksi,
    );
  }
}
