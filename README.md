# Nexus Finance

A personal finance tracker built with Flutter and Riverpod. Menyajikan pencatatan income, expense, dan transfer, lengkap dengan tema terang/gelap, grafik kategori, serta penyimpanan lokal Isar.

## Fitur Utama
- Dashboard ringkas: total saldo (income − expense), tren pengeluaran bulanan, transaksi terbaru.
- Manajemen transaksi: tambah/edit/hapus income, expense, transfer; lampiran teks dan foto; swipe-to-delete.
- Analitik kategori: diagram lingkaran pengeluaran/pemasukan per kategori (fl_chart) untuk bulan berjalan.
- Tema: mode terang/gelap dengan toggle di Settings.
- Ekspor CSV: ekspor transaksi bulan berjalan ke berkas lokal.
- Offline-first: Isar untuk data utama; preferensi tema disimpan via file lokal (path_provider).

## Teknologi
- Flutter
- Riverpod 2
- Isar 3
- fl_chart
- path_provider, image_picker

## Prasyarat
- Flutter SDK terpasang
- Emulator atau perangkat fisik Android/iOS

## Menjalankan Proyek
1) Install dependensi
```pwsh
flutter pub get
```
2) Jalankan aplikasi
```pwsh
flutter run
```

## Struktur Direktori Singkat
- `lib/app.dart` — shell aplikasi, bottom nav, theme wiring.
- `lib/core/` — tema, utilitas, konstanta.
- `lib/data/` — model Isar, repository akun/kategori/transaksi.
- `lib/features/` — layar Dashboard, Transactions, Settings, widget terkait.
- `lib/shared/` — provider global, layanan pendukung (dummy seeding, dsb.).
- `test/` — placeholder pengujian widget.

## Data Dummy
- Saat DB siap, `DummySeedService` memanggil `seedFebruary2026Demo()` untuk mengisi contoh transaksi Februari 2026:
  - Pendapatan: gaji + proyek freelance.
  - Pengeluaran: satu transaksi stabil per hari (±420k–720k) agar grafik halus.
  - Transfer: contoh perpindahan antar akun default.
- Idempoten: jika Februari 2026 sudah berisi transaksi, seed dilewati. Untuk mencoba ulang, hapus data Isar/clear data aplikasi.

## Tema
- Pengaturan di Settings → "Mode Tampilan" (Terang, Gelap, Ikuti Sistem).
- Skema warna ada di `lib/core/theme/` dengan `AppTheme.light` dan `AppTheme.dark`.

## Ekspor CSV
- Settings → Export menyimpan transaksi bulan berjalan ke direktori dokumen lokal (izin bergantung platform).

## Catatan Pengembangan
- Peringatan `experimental_member_use` di berkas Isar *.g.dart adalah output generator dan aman diabaikan.
- Pastikan seed akun/kategori default dijalankan otomatis oleh repository sebelum menambah transaksi nyata.

## Lisensi
Proyek ini bersifat pribadi/internal. Sesuaikan lisensi sebelum dipublikasikan.
