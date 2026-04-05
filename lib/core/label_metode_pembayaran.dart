String labelMetodePembayaran(String kode) {
  final k = kode.trim();
  return switch (k) {
    'tunai' => 'Tunai',
    'transfer' => 'Transfer',
    'e_wallet' => 'E-wallet',
    'debit_kredit' => 'Kartu debit/kredit',
    'non_tunai' => 'Non-tunai',
    'qris' || 'qr' => 'QRIS',
    _ => k.isEmpty ? '—' : k,
  };
}
