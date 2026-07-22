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

lib/services/supabase_config.dart

// Copy this file to supabase_config.dart and fill in your values.
// supabase_config.dart is gitignored — do not commit secrets.

class SupabaseConfig {
static const String url = 'YOUR_SUPABASE_URL';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}

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

### 4. Setup Notifikasi WhatsApp (Opsional)

Aplikasi ini menggunakan Supabase Edge Functions untuk mengirim notifikasi WhatsApp otomatis ke admin saat ada transaksi baru via Gowa API.

1. Atur *secrets* (environment variables) di Supabase Anda:
```bash
supabase secrets set GOWA_BASE_URL="https://api-gowa-anda.com"
supabase secrets set GOWA_TOKEN="username:password"
supabase secrets set GOWA_DEVICE_ID="device-id-anda"
```

2. *Deploy* Edge Function `wa` (jika nama folder di project Anda `notify-wa`, rename terlebih dahulu menjadi `wa` saat *deploy* atau sesuaikan `invoke('wa')` di kode Flutter):
```bash
supabase functions deploy wa
```

### 5. Run

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
- Integrasi notifikasi WhatsApp ke admin saat ada transaksi baru.

### [1.0.1] — Banner & Voucher (Terbaru)

- Tambahan fitur Banner/Promosi (Admin bisa unggah banner, pelanggan melihat carousel banner di beranda).
- Banner mendukung aspect ratio dinamis, kompresi otomatis (max 1200px, 70% quality), dan fitur *preview* *zoom-able* di pelanggan.
- Tambahan fitur Voucher & Diskon (Admin bisa membuat kode unik, mengatur potongan harga tetap, dan kuota pemakaian).
- Pelanggan bisa melakukan klaim voucher pada form transaksi dan mendapatkan potongan harga langsung.
- Desain *card* transaksi Admin diselaraskan dengan pelanggan (*flat design*, tanpa *shadow*).
## Catatan

- `lib/services/supabase_config.dart` **tidak** di-commit (lihat `.gitignore`).
- Saldo hanya dari refund batal transaksi.
- Metode bayar: `QRIS`, `Saldo`.
