# Lost & Found App — Minggu 1: Setup & Autentikasi
## Panduan Lengkap 7 Hari Pertama

---

## Struktur Folder Keseluruhan

```
lostnfound_week1/
│
├── flutter_app/                    ← Aplikasi Mobile (Android & iOS)
│   ├── pubspec.yaml                ← Dependencies Flutter
│   └── lib/
│       ├── main.dart               ← Entry point, init Supabase & Riverpod
│       ├── core/
│       │   ├── constants/
│       │   │   └── app_constants.dart      ← Semua konstanta global
│       │   ├── theme/
│       │   │   └── app_theme.dart          ← Material 3 theme + warna status
│       │   └── router/
│       │       └── app_router.dart         ← GoRouter + auth guard
│       ├── features/
│       │   ├── auth/
│       │   │   ├── data/
│       │   │   │   └── auth_provider.dart  ← Riverpod provider + AuthService
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           ├── login_screen.dart
│       │   │           └── register_screen.dart
│       │   └── home/
│       │       └── presentation/
│       │           └── screens/
│       │               └── home_screen.dart  ← Beranda (statis, placeholder)
│       └── shared/
│           └── screens/
│               ├── splash_screen.dart       ← Cek session, redirect
│               └── main_shell.dart          ← Bottom nav + FAB
│
├── supabase/
│   └── migrations/
│       ├── 001_initial_schema.sql   ← Semua tabel + enum + trigger
│       ├── 002_rls_policies.sql     ← Row Level Security policies
│       ├── 003_storage_setup.sql    ← Bucket konfigurasi (Minggu 2, siap dari Minggu 1)
│       └── 004_rls_testing.sql      ← Query untuk verifikasi keamanan
│
└── admin_web/
    └── src/
        ├── App.tsx                  ← Root Refine + resource definitions
        ├── providers/
        │   ├── supabaseClient.ts    ← Supabase client instance
        │   └── authProvider.ts     ← Login admin + cek role
        └── pages/
            └── items/
                └── index.tsx       ← Tabel laporan + action approve/reject
```

---

## Hari 1 — Inisialisasi Proyek

### Apa yang dilakukan:
Membuat fondasi infrastruktur proyek dari nol.

### Langkah teknis:

**Flutter:**
```bash
# Buat project Flutter baru
flutter create lostnfound --org com.kampus --platforms=android,ios

# Masuk ke direktori
cd lostnfound

# Install dependencies (salin pubspec.yaml yang sudah dibuat, lalu:)
flutter pub get
```

**Supabase:**
1. Buka supabase.com → New Project
2. Catat: Project URL & anon/public API key
3. Paste ke `lib/core/constants/app_constants.dart`

**Verifikasi:**
```bash
flutter run  # Harus tampil Flutter counter app default
```

---

## Hari 2 — Desain Skema Database

### Apa yang dilakukan:
Membuat semua tabel di PostgreSQL Supabase beserta enum, index, trigger, dan dasar RLS.

### Urutan jalankan migration:
```sql
-- Di Supabase Dashboard > SQL Editor, jalankan berurutan:
-- 1. 001_initial_schema.sql
-- 2. 002_rls_policies.sql
```

### Mengapa satu tabel untuk lost & found?
PRD menggunakan satu tabel `items` dengan kolom `type` (lost/found).
Ini lebih sederhana untuk query gabungan (pencocokan, statistik) dibanding dua tabel terpisah.

### Mengapa jsonb untuk photo_urls?
Array URL foto lebih fleksibel disimpan sebagai `jsonb` daripada relasi tabel terpisah,
karena foto tidak butuh query individual — selalu diambil bersama item-nya.

---

## Hari 3 — Integrasi Auth Flutter

### Apa yang dilakukan:
Menghubungkan UI Flutter ke Supabase Auth. User bisa daftar, login, dan logout.

### Alur login email:
```
User isi form → AuthService.signInWithEmail()
→ Supabase Auth verify → return Session
→ authStateProvider emit AuthChangeEvent.signedIn
→ GoRouter redirect() deteksi session → push ke /home
```

### Alur Google Sign-In:
```
User tap Google → supabase.auth.signInWithOAuth(OAuthProvider.google)
→ Buka browser/Google sheet → user pilih akun
→ Redirect ke deep link (io.supabase.lostnfound://login-callback)
→ Flutter handle deep link → session terbentuk
→ authStateProvider emit → GoRouter redirect ke /home
```

### Setup deep link Android (tambahkan ke AndroidManifest.xml):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.lostnfound" android:host="login-callback" />
</intent-filter>
```

### Setup deep link iOS (tambahkan ke Info.plist):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.lostnfound</string>
    </array>
  </dict>
</array>
```

---

## Hari 4 — Setup Refine Admin Web

### Apa yang dilakukan:
Membuat dashboard admin berbasis React + Refine yang terhubung ke Supabase.

### Langkah setup:
```bash
# Buat project Refine
npx create-refine-app@latest admin-web -- --preset antd-supabase
cd admin-web

# Install tambahan
npm install @refinedev/supabase @supabase/supabase-js

# Buat file .env
echo "VITE_SUPABASE_URL=https://xxx.supabase.co" >> .env
echo "VITE_SUPABASE_ANON_KEY=eyJ..." >> .env

# Salin file dari folder admin_web/src/ ke project
# Lalu jalankan:
npm run dev
```

### Mengapa Refine?
Refine generate UI CRUD (tabel, form, detail) secara otomatis dari definisi resource.
Untuk 1 developer, ini menghemat 60-70% waktu dibanding buat dari scratch.

---

## Hari 5 — RLS Fine-tuning

### Apa yang dilakukan:
Memastikan kebijakan keamanan data berjalan benar. Ini hari yang KRITIS.

### Jalankan testing:
Buka `004_rls_testing.sql` → jalankan setiap test blok satu per satu.
Verifikasi hasilnya sesuai ekspektasi yang tercantum di komentar.

### Checklist keamanan:
- [ ] User A tidak bisa lihat item pending milik User B
- [ ] `distinctive_features` tidak muncul di items_public view
- [ ] User tidak bisa mengubah role sendiri menjadi admin
- [ ] Anonymous user hanya bisa SELECT dari items_public
- [ ] Admin bisa lihat semua data termasuk kolom sensitif

---

## Hari 6 — UI Flutter Halaman Utama

### Apa yang dilakukan:
Membuat struktur navigasi utama (bottom nav + shell) dan halaman Beranda statis.

### Struktur navigasi (sesuai PRD 8.1):
```
MainShell (ShellRoute)
├── /home → HomeScreen (Beranda)   [tab 0]
├── /track → TrackScreen (Lacak)   [tab 1] ← dibuat Minggu 2
└── /profile → ProfileScreen       [tab 2] ← dibuat Minggu 2
```

### Mengapa ShellRoute?
ShellRoute memastikan MainShell (yang berisi bottom nav) tidak di-rebuild
saat pindah antar tab. Tanpa ShellRoute, bottom nav akan flash/reset setiap navigasi.

---

## Hari 7 — Review & Debug

### Checklist akhir Minggu 1:
- [ ] `flutter run` berjalan di emulator Android & iOS
- [ ] Halaman login tampil dengan benar
- [ ] Daftar dengan email baru → profil terbuat di tabel profiles (cek Supabase Dashboard)
- [ ] Login dengan email → redirect ke /home
- [ ] Logout → redirect ke /login
- [ ] Google Sign-In berfungsi (pastikan setup di Supabase Auth > Providers > Google)
- [ ] Admin web berjalan di localhost:5173
- [ ] Login admin web dengan akun yang role-nya 'admin'
- [ ] Tabel items kosong tapi ter-render di Refine

### Setup Google OAuth di Supabase (wajib untuk Google Sign-In):
1. Buka: Google Cloud Console → APIs & Services → Credentials
2. Buat OAuth 2.0 Client ID (Web application)
3. Tambahkan redirect URI: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
4. Copy Client ID & Secret ke: Supabase Dashboard > Auth > Providers > Google

---

## Dependensi Antar Hari

```
Hari 1 (Infra) ──→ Hari 2 (DB Schema)
                        │
                        ├──→ Hari 3 (Auth Flutter) → Hari 6 (UI) → Hari 7 (Review)
                        │
                        └──→ Hari 4 (Admin Web) → Hari 5 (RLS tuning)
```

Hari 1 & 2 HARUS selesai sebelum hari lainnya bisa dimulai.
Hari 3 & 4 bisa dikerjakan paralel setelah Hari 2 selesai.