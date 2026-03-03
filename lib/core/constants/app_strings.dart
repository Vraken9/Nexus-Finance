/// Central registry of every hard-coded string in Indonesian localization.
abstract final class AppStrings {
  // ── App ────────────────────────────────────────────────────────────────────
  static const String appName = 'Nexus Finance';

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const String navDashboard = 'Dasbor';
  static const String navTransactions = 'Transaksi';
  static const String navSettings = 'Pengaturan';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  static const String totalBalance = 'Total Saldo';
  static const String monthlyIncome = 'Pemasukan Bulanan';
  static const String monthlyExpenses = 'Pengeluaran Bulanan';
  static const String spendingTrend = 'Tren Pengeluaran';
  static const String thisMonth = 'Bulan Ini';
  static const String noDataYet = 'Tidak ada data untuk periode ini.';

  // ── Transactions ───────────────────────────────────────────────────────────
  static const String addTransaction = 'Tambah Transaksi';
  static const String editTransaction = 'Edit Transaksi';
  static const String deleteTransaction = 'Hapus Transaksi';
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  static const String typeTransfer = 'transfer';
  static const String transferLabel = 'Transfer';

  // ── Form fields ────────────────────────────────────────────────────────────
  static const String fieldAmount = 'Jumlah';
  static const String fieldDate = 'Tanggal & Waktu';
  static const String fieldCategory = 'Kategori';
  static const String fieldAsset = 'Aset / Metode Bayar';
  static const String fieldAccount = 'Akun';
  static const String fieldNote = 'Catatan (opsional)';
  static const String fieldFromAccount = 'Dari Akun';
  static const String fieldToAccount = 'Ke Akun';
  static const String fieldTransferFee = 'Biaya Transfer (opsional)';
  static const String fieldAttachment = 'Catatan Lampiran (opsional)';

  // ── Image ──────────────────────────────────────────────────────────────────
  static const String addPhoto = 'Tambah Foto';
  static const String camera = 'Kamera';
  static const String gallery = 'Galeri';
  static const String changePhoto = 'Ganti Foto';

  // ── Account types ──────────────────────────────────────────────────────────
  static const String accountCash = 'cash';
  static const String accountBank = 'bank';
  static const String accountCard = 'card';
  static const String accountEwallet = 'ewallet';

  // ── Transfer Validation ───────────────────────────────────────────────────
  static const String validationSameAccount = 'Akun asal dan tujuan tidak boleh sama.';

  // ── Settings ───────────────────────────────────────────────────────────────
  static const String exportCSV = 'Ekspor CSV';
  static const String exportPDF = 'Ekspor PDF';
  static const String exportSuccess = 'Laporan disimpan ke /Documents';
  static const String exportFailed = 'Gagal ekspor. Periksa izin.';

  // ── Validation ─────────────────────────────────────────────────────────────
  static const String validationRequired = 'Bidang ini harus diisi.';
  static const String validationAmountPositive = 'Jumlah harus lebih besar dari nol.';
  static const String validationAmountNaN = 'Masukkan angka yang valid.';

  // ── Custom Categories ─────────────────────────────────────────────────────
  static const String addCustomCategory = 'Tambah Kategori Baru';
  static const String categoryName = 'Nama Kategori';
  static const String selectColor = 'Pilih Warna';
  static const String selectIcon = 'Pilih Ikon';
  static const String create = 'Buat';
  static const String cancel = 'Batal';
  static const String categoryAdded = 'Kategori berhasil ditambahkan.';
  static const String categoryError = 'Gagal menambahkan kategori.';

  // ── Toggle Labels ─────────────────────────────────────────────────────────
  static const String expenseLabel = 'Pengeluaran';
  static const String incomeLabel = 'Pemasukan';
  static const String transferLabel2 = 'Transfer';

  // ── Button Labels ─────────────────────────────────────────────────────────
  static const String save = 'Simpan';
  static const String saveChanges = 'Simpan Perubahan';
  static const String addTransaction2 = 'Tambah Transaksi';
  static const String selectCategory = 'Pilih kategori';
  static const String selectAccount = 'Pilih akun';
}
