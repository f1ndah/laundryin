-- ============================================
-- LaundryIN Database Schema
-- ============================================
-- Run this in Supabase SQL Editor to set up the database

-- ============================================
-- 1. TABLES
-- ============================================

-- Profiles table (linked to Supabase Auth)
create table if not exists profiles (
  id uuid references auth.users primary key,
  nama text not null,
  email text not null,
  role text default 'pelanggan' check (role in ('pelanggan', 'admin')),
  saldo integer not null default 0 check (saldo >= 0),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Jika tabel sudah ada:
-- alter table profiles add column if not exists saldo integer not null default 0 check (saldo >= 0);

-- Transactions table
create table if not exists transactions (
  id bigint generated always as identity primary key,
  kode text unique not null,
  user_id uuid references profiles(id) on delete cascade not null,
  nama_pelanggan text not null,
  alamat text not null,
  berat numeric not null,
  jenis text not null,
  harga integer not null,
  status text default 'Menunggu' check (status in ('Menunggu', 'Proses', 'Selesai', 'Batal')),
  metode text default 'QRIS' check (metode in ('QRIS', 'Saldo')),
  bukti_url text,
  tanggal timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Jika tabel sudah ada, jalankan:
-- alter table transactions add column if not exists kode text unique;
-- alter table transactions drop constraint if exists transactions_metode_check;
-- alter table transactions add constraint transactions_metode_check check (metode in ('QRIS', 'Saldo'));
-- ============================================
-- 2. ADDITIONAL TABLES (Layanan, Toko)
-- ============================================

-- Layanan table (jenis cucian + harga, editable by admin)
create table if not exists layanan (
  id serial primary key,
  jenis text not null,
  harga integer not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Toko table (multiple rows, cabang toko)
create table if not exists toko (
  id serial primary key,
  nama text not null default 'LaundryIN',
  alamat text not null default 'Jl. Raya Munjul No2, rt6 rw1 Munjul, Kecamatan Cipayung, Jakarta Timur',
  jam_buka text default '08:00',
  jam_tutup text default '20:00',
  nomor_admin text,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Jika tabel toko sudah ada (migrasi dari single-row):
-- alter table toko alter column id drop default;
-- alter table toko alter column id add generated always as identity;
-- alter table toko add column if not exists nomor_admin text;

-- ============================================
-- 3. INDEXES
-- ============================================

create index if not exists idx_transactions_user_id on transactions(user_id);
create index if not exists idx_transactions_status on transactions(status);
create index if not exists idx_transactions_created_at on transactions(created_at desc);

-- ============================================
-- 4. ROW LEVEL SECURITY
-- ============================================
-- Enable RLS
alter table transactions enable row level security;
alter table profiles enable row level security;
alter table layanan enable row level security;
alter table toko enable row level security;

-- Profiles: user can read/update own profile, admin can read all
create policy "Users can read own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);
create policy "Admins can read all profiles" on profiles for select using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- Transactions: authenticated users can insert, read own
create policy "Users can insert transactions" on transactions for insert with check (auth.uid() = user_id);
create policy "Users can read own transactions" on transactions for select using (auth.uid() = user_id or exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Admins can update transactions" on transactions for update using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- Layanan & Toko: admin-only write, all authenticated can read
create policy "Anyone can read layanan" on layanan for select using (auth.role() = 'authenticated');
create policy "Admins can insert layanan" on layanan for insert with check (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Admins can update layanan" on layanan for update using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Admins can delete layanan" on layanan for delete using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

create policy "Anyone can read toko" on toko for select using (auth.role() = 'authenticated');
create policy "Admins can insert toko" on toko for insert with check (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Admins can update toko" on toko for update using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Admins can delete toko" on toko for delete using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- Untuk tabel sudah ada, jalankan:
--   alter table transactions enable row level security;
--   alter table profiles enable row level security;
--   alter table layanan enable row level security;
--   alter table toko enable row level security;
--   (lalu copy-paste policy satu per satu)

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Don't forget to:
-- 1. Disable email confirmation in Supabase Dashboard (Authentication > Settings)
-- 2. Add your Supabase URL and anon key to lib/services/supabase_config.dart
--
-- To set a user as admin, run:
-- update profiles set role = 'admin' where email = 'admin@example.com';
