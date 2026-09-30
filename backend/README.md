# Cakrawala API

Backend memakai Node.js dan TypeScript. Database lokal menggunakan SQLite; saat `DATABASE_URL` diisi, backend memakai PostgreSQL Supabase. API mempertahankan path dan format respons yang dipakai Flutter.

## Menjalankan lokal

```powershell
cd backend
npm install
npm run dev
```

API aktif di `http://127.0.0.1:8000/api`. Database dibuat otomatis di `backend/data/cakrawala.sqlite3`, memakai skema yang sama dengan backend sebelumnya. Katalog program dibaca dari `backend/catalog.json`.

Jalankan Flutter Web di terminal terpisah:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
```

Untuk Android emulator, jalankan backend dengan `HOST=0.0.0.0` dan gunakan `http://10.0.2.2:8000/api/` sebagai `API_BASE_URL`. Untuk HP fisik, gunakan IP LAN komputer, misalnya `http://192.168.1.20:8000/api/`.

## Berbagi di satu Wi-Fi

Dari root proyek:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-lan.ps1
```

Script membangun Flutter Web, menjalankan API Node, dan menayangkan web dari satu alamat LAN. Semua perangkat harus memakai URL yang sama.

## Database bersama online dengan Supabase

1. Buat project PostgreSQL di Supabase, lalu buka **Connect** dan salin URI **Session pooler** (berguna untuk lingkungan IPv4 seperti banyak jaringan lokal). Pakai URI yang diberikan dashboard, bukan menebak host atau port.
2. Salin `backend/.env.example` menjadi `backend/.env`, lalu isi `DATABASE_URL` dengan URI tersebut. Pastikan placeholder password diganti dengan password database project. Jangan commit atau kirim file `.env` ke chat publik. Untuk detail pilihan koneksi, lihat [dokumentasi koneksi database Supabase](https://supabase.com/docs/guides/database/connecting-to-postgres).
3. Jalankan backend. Tabel dan akun demo akan dibuat otomatis pada database Supabase tersebut:

   ```powershell
   cd backend
   npm install
   npm run dev
   ```

4. Untuk teman yang menjalankan backend sendiri, `git pull` hanya mengambil kode. Setiap komputer perlu file `backend/.env` lokal dengan `DATABASE_URL` project yang sama, lalu jalankan `npm install` dan `npm run dev`. File `.env` tidak ikut Git. Kedua backend kemudian membaca/menulis database yang sama. Untuk deployment, masukkan variabel sebagai environment secret pada host API.
5. Jika perlu menyalin data SQLite lama, jalankan `npm run migrate:sqlite` satu kali oleh pemilik data setelah `DATABASE_URL` diatur. Jangan jalankan migrasi itu sebagai bagian setup teman; gunakan database Supabase yang sudah terisi agar data lokal teman tidak ikut disalin.

`git push` menyimpan source code di GitHub, bukan data aplikasi. Data tersimpan di Supabase ketika aplikasi mengirim perubahan ke API dan API berjalan dengan `DATABASE_URL` yang mengarah ke project tersebut. Saat backend aktif, log `Database: PostgreSQL terpusat` menandakan konfigurasi PostgreSQL dipakai; jika tertulis SQLite, backend memakai file lokal.

Tanpa `DATABASE_URL`, backend tetap memakai SQLite lokal. Dua salinan lokal tanpa URL database bersama akan memiliki data masing-masing. Frontend mengambil data melalui API yang sudah ada; perubahan terlihat saat halaman atau datanya dimuat ulang, belum melalui notifikasi realtime.

## Akun demo

Semua password demo: `cakrawala2026`.

| Peran | Email |
| --- | --- |
| Siswa | `farhan.arya@gmail.com` |
| Orang tua | `rina.kusuma@gmail.com` |
| Tutor | `dimas.prasetyo@cakrawalaeducentre.com` |
| Admin | `admin@cakrawalaeducentre.com` |

Untuk database baru, kredensial admin bisa diatur melalui `ADMIN_LOGIN_EMAIL` dan `ADMIN_LOGIN_PASSWORD`. Akun demo hanya untuk pengembangan; ganti sebelum deployment publik.

## Endpoint

- `GET /api/health` — status API.
- `GET /api/programs` — katalog paket; mendukung query `grade`.
- `POST /api/leads` — simpan permintaan konsultasi.
- `GET /api/admin/leads` — akses token lama melalui `ADMIN_API_TOKEN`.
- `POST /api/auth/register` — pendaftaran akun siswa; role selain siswa hanya bisa dibuat admin.
- `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/me`, `PATCH /api/me` — autentikasi bearer, sesi, dan baca/perbarui nama serta nomor telepon profil.
- `POST /api/admin/users` — admin membuat akun siswa, orang tua, tutor, atau admin dengan body `email`, `password`, `role`, dan `name`.
- `POST /api/admin/classes` — admin membuat kelas, memilih tutor aktif, jadwal, durasi, dan tautan kelas.
- `GET /api/classes` — daftar kelas sesuai role: kelas aktif, kelas tutor yang ditugaskan, atau kelas yang diikuti anak.
- `POST /api/classes/{id}/enroll` — siswa bergabung ke kelas; pendaftaran disimpan di database bersama.
- `GET /api/student/dashboard`, `/api/parent/dashboard`, `/api/tutor/dashboard`, `/api/admin/dashboard` — dashboard berdasarkan role, termasuk kelas yang relevan.
- `POST /api/student/questions`; `POST /api/tutor/questions/{id}/reply` — pertanyaan siswa dan balasan tutor.
- `GET /api/tryouts/sample/question`, `POST /api/tryouts/sample/answer` — tryout contoh.
- `POST /api/tutor/notes` — tutor menyimpan catatan belajar yang dapat dilihat siswa/orang tua.
- `PATCH /api/tutor/sessions/{id}` — tutor menandai sesi selesai atau membatalkannya.
- Dashboard admin menyajikan ringkasan leads dan pengguna; pembuatan akun dibatasi untuk admin.
- Dashboard tutor menyajikan sesi yang ditugaskan, pertanyaan siswa, dan catatan pembelajaran.
- Tabel kelas dan keikutsertaan siswa dibuat otomatis saat backend pertama kali dijalankan. Akses Supabase Data API ke tabel tersebut dicabut; perubahan kelas hanya lewat API Node yang memeriksa sesi dan role.

## Konfigurasi deployment

Atur `HOST=0.0.0.0`, `PORT`, `DATABASE_PATH`, `CORS_ORIGINS`, `ADMIN_LOGIN_EMAIL`, `ADMIN_LOGIN_PASSWORD`, dan bila masih menggunakan endpoint token lama, `ADMIN_API_TOKEN`. Jalankan `npm start`. SQLite membutuhkan disk persisten dan hanya cocok untuk satu instance API; gunakan PostgreSQL sebelum menjalankan beberapa instance.

## Pemeriksaan tipe dan tes API

```powershell
npm run typecheck
npm test
```
