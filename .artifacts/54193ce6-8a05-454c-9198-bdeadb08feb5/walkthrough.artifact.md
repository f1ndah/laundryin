# Walkthrough - Perbaikan Navigasi dan Reset Halaman

Saya telah memperbaiki masalah di mana aplikasi selalu melakukan refresh dan kembali ke dashboard utama saat menekan tombol back dari halaman lain.

## Perubahan Utama

### [AuthCheck](file:///C:/Users/ariha/Documents/Flutter/laundryin/lib/pages/auth_check.dart)

Masalah utama terletak pada `AuthCheck` yang mengambil data profil pengguna di dalam method `build`. Setiap kali navigasi berubah (seperti saat pop/back), widget ini melakukan rebuild dan memicu pengambilan data ulang.

**Perbaikan yang dilakukan:**
- Menyimpan `_profileFuture` di dalam state `AuthCheck`.
- Hanya melakukan pengambilan data ulang jika user ID berubah (misalnya setelah logout dan login user lain).
- Memastikan `FutureBuilder` menggunakan future yang sama agar tidak menampilkan loading spinner (refresh) saat rebuild rutin.

```diff
 class _AuthCheckState extends State<AuthCheck> {
+  Future<Map<String, dynamic>?>? _profileFuture;
+  String? _lastUserId;
+
   @override
   Widget build(BuildContext context) {
     return StreamBuilder<AuthState>(
       stream: AuthService.authStateChanges,
       builder: (context, snapshot) {
-        if (snapshot.connectionState == ConnectionState.waiting) {
+        if (snapshot.connectionState == ConnectionState.waiting && _profileFuture == null) {
           return const Scaffold(
             body: Center(child: CircularProgressIndicator()),
           );
         }

         final session = snapshot.data?.session;
-        if (session == null) {
+        final user = session?.user ?? AuthService.currentUser;
+
+        if (user == null) {
+          _profileFuture = null;
+          _lastUserId = null;
           return const LoginPage();
         }

-        return FutureBuilder<Map<String, dynamic>?>(
-          future: AuthService.getProfile(),
+        // Hanya ambil profil jika user berubah
+        if (_profileFuture == null || _lastUserId != user.id) {
+          _lastUserId = user.id;
+          _profileFuture = AuthService.getProfile();
+        }
+
+        return FutureBuilder<Map<String, dynamic>?>(
+          future: _profileFuture,
```

## Hasil yang Diharapkan

1. **State Terjaga**: Saat Anda berada di tab "Transaksi" atau "Profil" dan membuka halaman baru (seperti "Lokasi"), menekan tombol back akan mengembalikan Anda ke tab yang sama tanpa reset ke "Home".
2. **Tanpa Loading Berulang**: Tidak ada lagi animasi loading (spinner) yang muncul secara tiba-tiba saat Anda kembali dari halaman lain.
3. **Efisiensi Data**: Aplikasi tidak lagi melakukan request ke server Supabase setiap kali user menekan tombol back, sehingga menghemat kuota data dan beban server.

## Verifikasi

- [x] Kode telah diperiksa untuk memastikan tidak ada kebocoran state.
- [x] Logika sinkronisasi `FutureBuilder` telah disesuaikan dengan pola best practice Flutter.
