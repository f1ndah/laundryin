# LaundryIN - Digital Laundry Management System

## 1. Project Overview

**LaundryIN** adalah aplikasi manajemen layanan laundry berbasis mobile yang dibangun menggunakan framework **Flutter**. Aplikasi ini dirancang untuk mendigitalkan proses pemesanan laundry bagi pelanggan dan memudahkan manajemen operasional bagi pemilik laundry (admin).

## 2. Technical Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
  - **Authentication**: Email & Password based login.
  - **Database**: PostgreSQL (Real-time data handling).
  - **Storage**: Penimpanan gambar banner.
  - **Edge Functions**: Integrasi notifikasi WhatsApp.
- **UI Design**: Material 3 dengan custom design system (Popppins Font, custom widgets).

## 3. Core Features - Pelanggan

- **Smart Dashboard**: Ringkasan saldo, banner promo, dan aksi cepat (Lokasi & Pricelist).
- **Pemesanan Mudah**:
  - Pilih jenis layanan (Kiloan, Satuan, dll).
  - Pilih cabang terdekat.
  - Input berat dan alamat jemput.
- **Metode Pembayaran**: Mendukung **Saldo Refund** dan **QRIS (DANA)**.
- **Sistem Voucher**: Klaim kode promo untuk potongan harga otomatis.
- **Digital Ticket/Nota**: Bukti transaksi digital dengan QR-like code untuk klaim cucian.
- **Tracking Status**: Lacak cucian secara real-time (Menunggu, Proses, Selesai).

## 4. Core Features - Admin

- **Dashboard Monitoring**: Pantau total pendapatan dan jumlah pesanan berdasarkan status.
- **Manajemen Transaksi**: Update status pesanan secara efisien.
- **Manajemen Data Master**:
  - Kelola Layanan & Harga (Pricelist).
  - Kelola Cabang Toko (Lokasi & Kontak).
  - Kelola Voucher Promo.
- **Engagement Tools**: Upload banner promosi untuk ditampilkan di aplikasi pelanggan.

## 5. Architecture & Implementation

- **Modular Widgets**: Komponen UI yang dapat digunakan kembali (Reusable Widgets) seperti `AppButton`, `AppInput`, dan lainnya.
- **Role-Based Access**: Sistem secara otomatis mengarahkan user ke dashboard yang sesuai (Admin vs Pelanggan) melalui `AuthCheck`.
- **Performance Optimization**: Penggunaan `IndexedStack` untuk navigasi tab yang mulus dan _lazy loading_ data.

## 6. Business Value

- **Efisiensi**: Mengurangi pencatatan manual dan risiko kesalahan input data.
- **Loyalitas**: Fitur saldo refund dan voucher mendorong pelanggan untuk kembali bertransaksi.
- **Transparansi**: Pelanggan mendapatkan update status cucian tanpa harus bertanya ke admin secara manual.
