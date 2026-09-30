# Setup Cakrawala untuk Tim

## A. Teman hanya ingin membuka website yang sedang Anda jalankan

Cara ini membuat kalian melihat build dan data yang sama. Komputer host dan teman harus terhubung ke Wi-Fi yang sama.

1. Pastikan perubahan yang ingin dibagikan sudah ada di folder proyek. Jika server API sedang berjalan di terminal, tekan `Ctrl+C` untuk menghentikannya. Port `8000` harus kosong sebelum skrip LAN dijalankan.
2. Buka terminal di root proyek `cakrawala_educentre` (folder yang berisi `lib`, `backend`, dan `scripts`). Jalankan:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/start-lan.ps1
   ```

   Jika terminal sedang berada di folder `backend`, jalankan:

   ```powershell
   powershell -ExecutionPolicy Bypass -File ..\scripts\start-lan.ps1
   ```

3. Skrip akan memasang dependency backend bila perlu, membangun Flutter Web, menjalankan API, lalu menampilkan URL LAN. Kirim URL yang tercetak, misalnya `http://192.168.1.20:8080`, kepada teman.
4. Teman membuka URL tersebut di browser. Izinkan Node.js melewati Windows Firewall untuk jaringan **Private** jika diminta.
5. Biarkan terminal host tetap terbuka dan komputer tetap menyala. Untuk menghentikan server, gunakan PID API dan web yang dicetak skrip:

   ```powershell
   Stop-Process -Id <PID_API>,<PID_WEB> -Force
   ```

Jangan jalankan `npm run dev` bersamaan dengan skrip LAN di komputer host. Keduanya memakai port API `8000`. Jika port `8000` atau `8080` dipakai aplikasi lain, hentikan aplikasi itu atau pilih port lain:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-lan.ps1 -ApiPort 8001 -WebPort 8081
```

## B. Teman ingin menjalankan salinan proyek sendiri dengan data Supabase yang sama

Ada dua hal yang berbeda: `git push` mengirim **kode** ke GitHub, sedangkan data masuk ke Supabase saat aplikasi mengirim perubahan lewat API yang backend-nya sudah terhubung ke Supabase. File `backend/.env` berisi alamat/kredensial database dan sengaja tidak ikut Git, jadi teman tidak otomatis terhubung hanya dengan `git pull`.

### Di komputer pemilik proyek

1. Pastikan backend lokal sudah terhubung ke Supabase: di `backend/.env`, `DATABASE_URL` harus berisi connection string project Supabase. Saat backend menyala, terminal menampilkan `Database: PostgreSQL terpusat`.
2. Data SQLite lokal yang lama sudah disalin ke Supabase menurut output migrasi sebelumnya. Jangan jalankan migrasi SQLite lagi dari komputer teman; itu bukan langkah setup teman.
3. Commit dan push kode terbaru ke GitHub. Push kode tidak mengirim `.env` maupun data database.

### Di komputer teman

1. Clone pertama kali, atau tarik kode terbaru jika repo sudah ada:

Clone pertama kali:

```powershell
git clone https://github.com/secdete/cakrawaladart.git
cd cakrawaladart
```

Untuk mengambil perubahan terbaru setelah proyek pernah di-clone:

```powershell
git switch main
git pull origin main
```

2. Minta pemilik project memberikan connection string Supabase melalui cara privat yang aman. Di Supabase, buka **Connect** lalu ambil URI **Session pooler** (umumnya cocok untuk komputer/jaringan IPv4). Gunakan string yang ditampilkan dashboard; ganti placeholder password database dengan password project yang benar. Jangan taruh string ini di GitHub, Flutter, atau chat publik. Lihat [panduan koneksi database Supabase](https://supabase.com/docs/guides/database/connecting-to-postgres) bila perlu.

3. Dari folder root repository, buat file `.env` lokal teman dari template, lalu edit file itu:

   ```powershell
   Copy-Item backend/.env.example backend/.env
   notepad backend/.env
   ```

   Isi `DATABASE_URL` dengan connection string Supabase yang diberikan pemilik. Jangan mengganti atau membagikan file `.env.example`; yang diisi rahasia adalah `backend/.env`.

4. Pasang dependency dan jalankan backend:

```powershell
cd backend
npm install
npm run typecheck
npm run dev
```

Pastikan terminal menampilkan `Database: PostgreSQL terpusat`, lalu buka `http://127.0.0.1:8000/api/health`. Jika masih tertulis SQLite, backend teman belum memakai konfigurasi Supabase.

5. Di terminal kedua, dari root proyek, jalankan Flutter Web:

```powershell
cd ..
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
```

Sekarang backend lokal teman dan backend pemilik dapat membaca/menulis database Supabase yang sama. Perubahan data muncul saat layar/data dimuat ulang; aplikasi saat ini belum berlangganan notifikasi Supabase Realtime.

Kalau teman hanya ingin membuka website yang sedang dijalankan pemilik, pakai **cara A** saja. Teman tidak perlu meng-clone repo atau membuat `.env`; kedua perangkat harus di Wi-Fi yang sama dan komputer pemilik tetap menyala.
