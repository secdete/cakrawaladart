# 🎓 SIAKAD Cakrawala Educentre (Portal Akademik & Pembelajaran Terpadu)

Aplikasi **SIAKAD (Sistem Informasi Akademik)** resmi untuk **Cakrawala Educentre**. Dibangun menggunakan **Flutter** dengan pendekatan arsitektur multiplatform agar dapat dijalankan sebagai **Website (Web App)** sekaligus siap di-deploy ke **Mobile (Android & iOS)** dan **Desktop (Windows/macOS)**.

---

## 🌟 Filosofi Desain: Anti "AI Slop"

Frontend ini dirancang secara khusus untuk merefleksikan identitas institusi pendidikan tinggi Indonesia yang kredibel, fungsional, dan berwibawa:

- **Palette Akademik Resmi**: Menggunakan kombinasi _Deep Academic Navy_ (`#0C2340`), _University Gold_ (`#D97706`), dan _Crisp Slate_ (`#F8FAFC`). Menghindari gradien neon ungu/merah muda generik ("AI slop") yang tidak lazim di sistem akademik.
- **Tipografi Bersih & Presisi**: Didukung oleh font `Plus Jakarta Sans` dari Google Fonts untuk kejelasan teks dokumen resmi.
- **Detail Institusional Realistis**:
  - Jam server kampus _real-time_ (WIB) dengan sinkronisasi detik (sangat krusial saat periode KRS/ujian).
  - Badge akreditasi institusi (_Terakreditasi UNGGUL BAN-PT_).
  - Selektor Periode/Tahun Akademik (_2025/2026 - Semester Ganjil_).
  - Papan pengumuman (_Academic Bulletin_) terverifikasi BAAK.
  - Verifikasi keamanan **CAPTCHA Aritmetika** dinamis dengan tombol acak ulang.
  - Dialog Pusat Bantuan (_IT Helpdesk & BAAK_) terintegrasi WhatsApp & surel resmi.
  - Formulir pemulihan kata sandi (_Lupa Password_) akun terdaftar PDDIKTI.
  - Tombol **Demo Login Otomatis** (_1-Click Autofill_) untuk Akun Mahasiswa dan Dosen.
  - Transisi mulus ke **Dashboard Akademik Lengkap** (IPK 3.82 Cumlaude, SKS, Jadwal Kuliah hari ini, status KRS disetujui Dosen PA, dan bukti lunas UKT).

---

## 📱 Arsitektur & Responsivitas (Web & Mobile Ready)

Sistem ini menggunakan layout adaptif:

- **Tampilan Desktop / Web**: Dua kolom elegan (_Left_: Pengumuman & Agenda Akademik, _Right_: Kartu Autentikasi SIAKAD).
- **Tampilan Mobile / Smartphone**: Kartu login diposisikan di atas untuk kemudahan akses jempol satu tangan, diikuti papan pengumuman dan footer di bagian bawah. Navigasi dashboard menggunakan `BottomNavigationBar` modern saat dibuka di smartphone.

---

## 🚀 Panduan Menjalankan Aplikasi

### 1. Menjalankan di Web Browser (Chrome / Edge)

```bash
# Masuk ke folder proyek
cd cakrawala_educentre

# Jalankan di Google Chrome
flutter run -d chrome

# Atau di Microsoft Edge
flutter run -d edge
```

### 2. Menjalankan di Windows Desktop

```bash
flutter run -d windows
```

### 3. Build & Deploy ke Android APK

```bash
# Build file APK Release
flutter build apk --release

# Lokasi hasil APK:
# build/app/outputs/flutter-apk/app-release.apk
```

### 4. Build untuk Hosting Website (Production Web)

```bash
flutter build web --release

# Folder output siap di-upload ke Vercel, Firebase Hosting, Netlify, atau cPanel/Nginx:
# build/web/
```

---

## 🔑 Kredensial Akun Uji Coba (Demo Credentials)

| Peran (Role)  | Nomor Induk (NIM / NIDN) | Kata Sandi      | Deskripsi                                            |
| :------------ | :----------------------- | :-------------- | :--------------------------------------------------- |
| **Mahasiswa** | `20230801244`            | `cakrawala2025` | Farhan Arya Nugraha (S1 Teknik Informatika - Sem. 5) |
| **Dosen**     | `0412088501`             | `cakrawala2025` | Dr. Ir. Hendra Saputra, M.T. (Dosen Homebase IF)     |
| **Staf BAAK** | `198804152014021003`     | `cakrawala2025` | Siti Rahmawati, S.Kom. (Biro Administrasi Akademik)  |

_(Di halaman login, Anda juga dapat langsung mengklik tombol **"Akun Mahasiswa"** atau **"Akun Dosen"** untuk autofill instan tanpa mengetik)._

---

## 📂 Struktur Direktori Proyek

```
cakrawala_educentre/
├── lib/
│   ├── main.dart                               # Entry point & tema global
│   ├── core/
│   │   ├── constants/
│   │   │   └── academic_constants.dart         # Informasi institusi, akreditasi & data demo
│   │   ├── models/
│   │   │   ├── announcement.dart               # Model pengumuman akademik
│   │   │   └── schedule_item.dart              # Model jadwal kuliah & mata kuliah
│   │   ├── theme/
│   │   │   ├── app_colors.dart                 # Palet warna navy-gold institusional
│   │   │   ├── app_typography.dart             # Konfigurasi Plus Jakarta Sans
│   │   │   └── app_theme.dart                  # Material 3 ThemeData
│   │   └── widgets/
│   │       └── campus_logo.dart                # Lambang & seal institusi Cakrawala
│   └── features/
│       ├── auth/
│       │   ├── screens/
│       │   │   └── siakad_login_screen.dart    # Halaman utama login SIAKAD
│       │   └── widgets/
│       │       ├── auth_card.dart              # Kartu form autentikasi & role tab
│       │       ├── campus_bulletin_panel.dart  # Papan pengumuman & agenda KRS
│       │       ├── campus_header.dart          # Header waktu server real-time (WIB)
│       │       ├── campus_footer.dart          # Footer kepatuhan PDDIKTI & kontak
│       │       ├── captcha_widget.dart         # Verifikasi keamanan aritmetika
│       │       ├── helpdesk_dialog.dart        # Modal WhatsApp & helpdesk IT
│       │       └── forgot_password_dialog.dart # Modal pemulihan kata sandi
│       └── dashboard/
│           └── screens/
│               └── siakad_dashboard_screen.dart# Portal akademik mahasiswa/dosen
└── web/
    └── index.html                              # Meta title & konfigurasi Web
```
