# Landing page API

API ringan berbasis Python standard library dan SQLite. Tidak perlu package tambahan.

## Menjalankan lokal

```powershell
python backend/server.py
```

Server berjalan di `http://127.0.0.1:8000/api`. SQLite dibuat otomatis di `backend/data/cakrawala.sqlite3`; katalog awal dibaca dari `catalog.json`.

Jalankan Flutter Web di terminal lain:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
```

Jika memakai Android emulator, gunakan host emulator:

```powershell
$env:HOST = '0.0.0.0'
python backend/server.py
# Di terminal lain:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/
```

Untuk HP fisik, gunakan IP LAN komputer sebagai `API_BASE_URL` (contoh `http://192.168.1.20:8000/api/`) dan jalankan backend dengan `HOST=0.0.0.0`. Izin HTTP tanpa TLS hanya aktif untuk Android debug; rilis produksi harus menggunakan HTTPS.

## Endpoint

- `GET /api/health` — status API.
- `GET /api/programs` — katalog paket.
- `GET /api/programs?grade=SMA%20-%20Kelas%2012` — filter paket sesuai jenjang.
- `POST /api/leads` — simpan permintaan konsultasi/minat paket. Wajib mengirim nama, nomor WhatsApp, jenjang, sumber, dan `consent: true`.
- `GET /api/admin/leads` — daftar permintaan; wajib header `Authorization: Bearer <ADMIN_API_TOKEN>`.

Sumber lead yang diterima: `landing_consultation`, `hero_consultation`, dan `package_interest`. Permintaan publik divalidasi, ukuran body dibatasi, dan dibatasi enam pengiriman per alamat IP per sepuluh menit.

Contoh mengatur token admin di PowerShell:

```powershell
$env:ADMIN_API_TOKEN = 'ganti-dengan-token-rahasia'
python backend/server.py
```

Untuk deployment, set `PORT`, `DATABASE_PATH`, `ADMIN_API_TOKEN`, dan `CORS_ORIGINS` pada host backend. Atur `API_BASE_URL` saat build web ke URL backend HTTPS yang dipublikasikan. SQLite cocok untuk satu instance dengan persistent disk; gunakan PostgreSQL sebelum menjalankan beberapa instance.

## Tes API

```powershell
python -m unittest discover -s backend -p 'test_*.py'
```
