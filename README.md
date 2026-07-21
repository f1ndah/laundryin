# LaundryIN

Aplikasi laundry (Flutter + Supabase) — pelanggan order & bayar, admin kelola transaksi/layanan/toko.

## Fitur

**Pelanggan**

- Login / daftar
- Buat transaksi, bayar QRIS atau saldo
- Tiket klaim (kode acak 5 karakter)
- Batalkan pesanan → refund ke saldo (tidak bisa ditarik tunai)
- Pricelist & lokasi toko
- Profil + statistik

**Admin**

- Dashboard transaksi (status Menunggu → Proses → Selesai; Batal/Selesai terkunci)
- CRUD layanan (harga /kg)
- Info toko
- Daftar pelanggan

## Stack

- Flutter
- Supabase (Auth, Postgres, Storage)

## Setup

### 1. Clone & dependencies

```bash
git clone https://github.com/f1ndah/laundryin.git
cd laundryin
flutter pub get
```

### 2. Supabase config

```bash
cp lib/services/supabase_config.example.dart lib/services/supabase_config.dart
```

Isi URL & anon key dari Supabase Dashboard → Project Settings → API.

### 3. Database

Jalankan SQL di Supabase SQL Editor:

- File: [`supabase/schema.sql`](supabase/schema.sql)

Jika tabel sudah ada, ikuti komentar `ALTER` di file tersebut (kolom `kode`, `saldo`, constraint metode, dll).

Opsional — set admin:

```sql
update profiles set role = 'admin' where email = 'email@kamu.com';
```

Disarankan: matikan email confirmation di Authentication → Providers → Email (untuk dev).

### 4. Run

```bash
flutter run
```

## Struktur singkat

```
lib/
  pages/          # UI pelanggan & admin
  services/       # auth, db, storage, config
  widgets/        # komponen UI reusable
supabase/
  schema.sql      # skema database
assets/images/    # logo, QRIS, dll
```

## Changelog

### [1.0.0] — Initial release

- Auth login / daftar (pelanggan & admin)
- Transaksi pelanggan: order, bayar QRIS / saldo, tiket klaim 5 karakter
- Batalkan transaksi → refund ke saldo (tidak bisa ditarik tunai)
- Dashboard admin: status Menunggu → Proses → Selesai (Batal/Selesai terkunci)
- CRUD layanan (harga /kg), info toko, daftar pelanggan
- Profil, pricelist, lokasi toko
- Dialog tentang aplikasi + cek versi vs GitHub release/tag

## Catatan

- `lib/services/supabase_config.dart` **tidak** di-commit (lihat `.gitignore`).
- Saldo hanya dari refund batal transaksi.
- Metode bayar: `QRIS`, `Saldo`.
