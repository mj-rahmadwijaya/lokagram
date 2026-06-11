# Task — Attendance App (branch: attendance-3)

> Alur baru berdasarkan wireframe 2026-06-11.
> API masih dummy, akan diganti real endpoint nanti.
> Kerjakan satu per satu sesuai urutan.

---

## Summary

Redesign total alur app mengikuti wireframe baru dari tim produk (2026-06-11).

**Perubahan besar dari versi sebelumnya:**

| Aspek | Sebelumnya (attendance-3) | Baru |
|---|---|---|
| Login | Email / password dummy | **PIN** + unique_id_device + timestamp |
| Struktur UI | 4 tab (Beranda, Absensi, Riwayat, Profil) | Single screen check-in + History + Profile sheet |
| GPS | Blokir fake GPS, wajib dalam radius | Tampilkan jarak saja, tidak blokir |
| Alur barcode | Scan langsung simpan | Scan → validasi data device → konfirmasi |
| Auth token | Tidak ada | Token dari API, dipakai semua request |
| Data karyawan/outlet | Manual input di Store Settings | Dari response API login, disimpan lokal |
| Backend | Semua lokal (SharedPreferences) | **Hit API** untuk semua operasi (dummy dulu) |

**Alur baru ringkas:**
```
Login (PIN) → validasi data device → MainScreen
  → Checkin → Scan Barcode → validasi → Konfirmasi → check-in tersimpan
  → History (list absensi dari API) → Checkout
  → Profile sheet (info karyawan + outlet)
  → Logout (hit API → clear session → Login)
```

**9 task** yang harus dikerjakan secara berurutan (lihat detail di bawah).
API semua dummy dulu — real endpoint menyusul setelah alur & UI selesai.

---

## Urutan Pengerjaan

```
#1 DummyApiService        ← fondasi
#2 Model Session          ← fondasi (paralel dengan #1)
#3 Refactor LoginScreen   ← butuh #1 + #2
#4 MainScreen baru        ← butuh #2
#5 Alur barcode check-in  ← butuh #2 + #4
#6 CheckinConfirmScreen   ← butuh #5
#7 HistoryScreen          ← butuh #1 + #2
#8 ProfileSheet           ← butuh #1 + #2
#9 Hapus kode lama        ← terakhir
```

---

## Task #1 — Buat DummyApiService
**Status:** pending

Buat `lib/services/api_service.dart` dengan semua endpoint sebagai dummy.
Semua method return hardcoded data + delay 500–800ms simulasi network.

**Endpoints:**
- `login(pin, uniqueIdDevice, timestamp)` → `{success, token, logo, infoOutlet, infoKaryawan(staffId, outletId, uniqueId), message}`
- `logout(token)` → `{success}`
- `getProfile(token)` → `{nama, phone, outletId, outletName, alamat, photoUrl}`
- `getAbsensiList(token)` → `[{tanggal, jam, status}]`
- `checkout(token)` → `{success, message}`

---

## Task #2 — Buat Model Session & SessionService
**Status:** pending

**`lib/models/session.dart`:**
```
Session {
  token, staffId, outletId, uniqueId,
  employeeName, phone, outletName, outletAddress, logoUrl
}
```

**`lib/services/session_service.dart`:**
- `saveSession(Session)` — simpan ke SharedPreferences
- `loadSession()` → `Session?`
- `clearSession()` — hapus semua data session

---

## Task #3 — Refactor LoginScreen (PIN + API login)
**Status:** pending  
**Butuh:** #1, #2

Ubah `lib/screens/login_screen.dart`:
- Hapus input email/password, ganti dengan **input PIN** (numeric, obscure)
- Ambil `unique_id_device` dari SessionService (atau generate UUID sekali simpan)
- Hit `ApiService.login(pin, uniqueIdDevice, timestamp)`

**Logic setelah response:**
- Response `false` → toast error dengan `message` dari API
- Response `true`:
  - **Belum ada session di device** → alert "Simpan data ke device?" Ya/Tidak
    - Ya → save session → navigasi ke MainScreen
    - Tidak → stay di login
  - **Ada session di device** → cocokkan `staffId`, `outletId`, `uniqueId`
    - Cocok → alert "Data cocok, lanjutkan?" Ya/Tidak
      - Ya → update session → navigasi ke MainScreen
      - Tidak → stay di login
    - Tidak cocok → alert "Data tidak cocok dengan device ini" → stay di login

---

## Task #4 — Buat MainScreen Baru
**Status:** pending  
**Butuh:** #2

Buat ulang `lib/screens/main_screen.dart` sesuai wireframe:
- **Logo** app di tengah
- **Info jarak** ke outlet: "Aksesi jarak X meter" (hitung GPS vs koordinat outlet dari session)
- **Jam real-time** (HH:mm:ss)
- **Tanggal** (Senin, 10 Juli 2026)
- **Tombol Checkin** besar di bawah
- **Tombol Logout** kanan atas → hit `ApiService.logout(token)` → clearSession → balik LoginScreen

GPS hanya untuk tampilkan jarak, tidak blokir check-in.
Tidak ada 4-tab lagi.

---

## Task #5 — Refactor Alur Barcode Check-in
**Status:** pending  
**Butuh:** #2, #4

Alur setelah tombol Checkin ditekan:
1. Buka `BarcodeScanScreen` (sudah ada)
2. Parse data barcode (staff_id, outlet_id, unique_id dari QR)
3. Cek session di device:
   - **Belum ada session** → alert "Simpan data ke device?" Ya/Tidak
     - Ya → save session dari barcode → lanjut ke CheckinConfirmScreen
     - Tidak → balik MainScreen
   - **Ada session** → cocokkan data barcode vs session
     - Cocok → lanjut ke CheckinConfirmScreen
     - Tidak cocok → alert "Data tidak cocok dengan device" → balik MainScreen

---

## Task #6 — Buat CheckinConfirmScreen
**Status:** pending  
**Butuh:** #5

Buat `lib/screens/checkin_confirm_screen.dart`:
- Tampil **nama karyawan** (dari session) dan **nama outlet**
- Teks: "Apakah anda yakin absensi?"
- **Tombol Ya** → simpan record absensi lokal (timestamp sekarang) → kembali MainScreen + toast "Check-in berhasil"
- **Tombol Tidak** → kembali MainScreen tanpa simpan

---

## Task #7 — Buat HistoryScreen
**Status:** pending  
**Butuh:** #1, #2

Buat `lib/screens/history_screen.dart`:
- **Header:** "Hallo [nama]", "[nama outlet]"
- **Avatar/photo** di kanan atas → tap buka ProfileSheet
- **List riwayat** absensi: tanggal, jam, status badge (Hadir/Absen)
- **Tombol Checkout** sticky di bawah → hit `ApiService.checkout(token)` → toast sukses
- Load data via `ApiService.getAbsensiList(token)` saat init

Navigasi ke HistoryScreen dari MainScreen (tombol riwayat atau setelah check-in).

---

## Task #8 — Buat ProfileSheet
**Status:** pending  
**Butuh:** #1, #2

Buat `lib/screens/profile_sheet.dart` sebagai **bottom sheet**:
- **Photo profile** (avatar inisial atau dari URL)
- **Tombol Back** (tutup sheet)
- **Informasi Karyawan:** nama, phone
- **Informasi Store:** outlet_id, name, alamat

Data dari `ApiService.getProfile(token)`.
Dibuka dari HistoryScreen saat tap avatar.

---

## Task #9 — Hapus Kode Lama
**Status:** pending  
**Butuh:** semua task selesai

File yang dihapus:
- `lib/screens/tabs/home_tab.dart`
- `lib/screens/tabs/absensi_tab.dart`
- `lib/screens/tabs/riwayat_tab.dart`
- `lib/screens/tabs/profil_tab.dart`
- `lib/screens/camera_screen.dart` (jika tidak dipakai)

Lainnya:
- Update `SplashScreen` routing ke flow baru
- Pastikan `flutter analyze` bersih (0 error)

---

## Backlog / Nanti (setelah dummy selesai)

- [ ] Ganti DummyApiService dengan real API endpoint dari BO/server
- [ ] Login ke backend GrandePos (token real)
- [ ] Lokasi/koordinat outlet dari response API (bukan manual input)
- [ ] Lisensi bisnis ID tampil di attendance
- [ ] Alur register → aktivasi device
- [ ] Upload data absensi ke server
- [ ] Foto profil dari API
