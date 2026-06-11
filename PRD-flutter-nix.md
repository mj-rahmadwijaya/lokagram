# PRD — Setup Flutter Development dengan Nix

> "Produk"-nya adalah **dev environment Flutter yang reproducible, berbasis Nix Flakes**.
> Dokumen ini jadi peta belajar + referensi saat ada masalah.

- **Pemilik:** Hendro
- **Mulai:** 2026-06-03
- **Selesai:** 2026-06-04
- **Prasyarat:** PRD Belajar Nix selesai (Tahap 1–4 ✅) — paham Flakes
- **Status terkini:** SELESAI ✅ — semua Tahap 1–4 dan tujuan G1–G5 tercapai 🎉
- **Lanjutan:** App dikembangkan menjadi Attendance App — branch `attendance-3` di repo `lokagram`
- **Fase berikutnya:** Redesign alur ke PIN login + API backend — lihat `task.md`

---

## 1. Latar Belakang & Motivasi

Sebagai Flutter developer, saya ingin **dev environment yang reproducible**: siapapun yang clone project dan punya Nix, langsung bisa build — tanpa install Flutter manual, tanpa atur `ANDROID_HOME` sendiri, tanpa beda versi SDK antar mesin.

**Kenapa tidak pakai cara biasa (install Flutter manual)?**
- Install manual = "jalan di komputerku, mungkin tidak di komputermu"
- Versi Flutter/SDK bisa beda antar developer atau antar mesin
- Tidak ada cara mudah rollback kalau upgrade Flutter merusak build

**Kenapa Nix menarik untuk Flutter:**
- Satu `flake.nix` = semua dependency (Flutter, Android SDK, JDK, CMake) terkunci versinya
- `nix develop` satu perintah → langsung siap build
- Reproducible: `flake.lock` menjamin byte-for-byte environment yang sama

---

## 2. Tujuan (Goals)

| # | Tujuan | Ukuran berhasil | Status |
|---|--------|-----------------|--------|
| G1 | Bisa build APK Flutter dari Nix dev shell | `flutter build apk --debug` menghasilkan `.apk` | ✅ |
| G2 | Paham kenapa Android SDK perlu setup khusus di Nix | Bisa jelaskan masalah read-only store | ✅ |
| G3 | Flake bisa dipakai di project Flutter nyata | Copy `flake.nix` ke project, `nix develop` langsung jalan | ✅ |
| G4 | Bisa update versi Flutter/SDK di flake | Paham cara ganti `buildToolsVersions`, `platformVersions` | ✅ |
| G5 | (Lanjutan) Bisa run app di device/emulator nyata | `flutter run` berhasil di HP fisik | ✅ |

### Bukan Tujuan — untuk sekarang
- ❌ iOS build (hanya bisa di macOS)
- ✅ ~~Setup emulator Android di Nix (kompleks, butuh KVM)~~ — ternyata berhasil! AVD via `composeAndroidPackages` + KVM
- ❌ Packaging Flutter app sebagai derivation Nix (sangat lanjutan)

---

## 3. Tahapan Belajar (Milestones)

### ▶ Tahap 1 — Flutter + Android SDK bisa build APK  `[ SELESAI ✅ ]`

- [x] Buat `flake.nix` dengan `composeAndroidPackages`
- [x] Atasi error `allowUnfree` (Android SDK lisensi non-free)
- [x] Atasi error `android-sdk-license` tidak bisa diterima
- [x] Atasi masalah Nix store read-only → local overlay di `~/.android/sdk`
- [x] Temukan semua SDK component yang dibutuhkan: build-tools 35, platform-36, cmake 3.22.1
- [x] `flutter build apk --debug` berhasil ✅

### ▶ Tahap 2 — Integrasi dengan project Flutter nyata  `[ SELESAI ✅ ]`

- [x] Buat project Flutter baru (`lokagram`) di `/home/raptor/Documents/Nix/flutter-dev/` via `nix develop --command flutter create`
- [x] Tambah dependencies Lokagram ke `pubspec.yaml` (flutter_map, geolocator, image_picker, permission_handler, shared_preferences)
- [x] Copy source code dari project referensi (`lib/` — models, screens, services)
- [x] Update `AndroidManifest.xml` dengan permissions lokasi + kamera
- [x] Temukan dan atasi error `platforms;android-35` missing → tambah `"35"` ke `platformVersions` di `flake.nix`
- [x] `flutter pub get` + `flutter build apk --debug` berhasil ✅

### ▶ Tahap 3 — Run di device  `[ SELESAI ✅ ]`

- [x] Setup Android Emulator via `composeAndroidPackages` (includeEmulator, includeSystemImages, abiVersions x86_64)
- [x] AVD `lokagram_emu` dibuat otomatis di `shellHook` (API 34, Pixel 6)
- [x] Jalankan emulator stabil: `emulator -avd lokagram_emu -accel on -no-audio -no-snapshot -no-boot-anim`
- [x] Set GPS emulator ke lokasi sekarang: `adb emu geo fix <lng> <lat>`
- [x] `flutter run` berhasil — app Lokagram tampil di emulator ✅
- [x] (Tujuan utama) Sambungkan HP Android fisik (Realme RMX1941), aktifkan USB debugging, `flutter run` di HP ✅

### ▶ Tahap 4 — Update & maintenance  `[ SELESAI ✅ ]`

- [x] `nix flake update` → nixpkgs sudah di versi terbaru (tidak ada perubahan = sudah up to date)
- [x] Build tetap berhasil setelah update — tidak ada component yang break
- [x] Paham cara pin versi Flutter: ganti `pkgs.flutter` dengan `pkgs.flutter324` / `flutter327` / `flutter332` / `flutter338` / `flutter341` di `flake.nix`

---

## 4. Pengetahuan Kunci (dari sesi setup)

### 4.1 Masalah & Solusi yang sudah dihadapi

**Masalah 1: `allowUnfree` error**
```
error: Refusing to evaluate package 'androidsdk' because it has an unfree license
```
**Solusi:** Gunakan `import nixpkgs { config = { allowUnfree = true; android_sdk.accept_license = true; }; }` — bukan `legacyPackages` yang tidak bisa menerima config.

---

**Masalah 2: Nix store read-only → license tidak bisa ditulis**

`flutter doctor --android-licenses` perlu menulis ke `$ANDROID_HOME/licenses/`, tapi Nix store itu read-only.

**Solusi:** Buat local overlay di `~/.android/sdk`:
```bash
# Symlink semua komponen SDK dari Nix store
for d in "$NIX_SDK"/*/; do
  name=$(basename "$d")
  if [ "$name" != "licenses" ]; then
    ln -sfn "$d" "$LOCAL_SDK/$name"
  fi
done
# Buat licenses/ yang writable, isi dengan hash yang valid
mkdir -p "$LOCAL_SDK/licenses"
printf "8933bad161af4178b1185d1a37fbf41ea5269c55\n..." > "$LOCAL_SDK/licenses/android-sdk-license"
```

---

**Masalah 3: SDK component missing → Gradle gagal install**
```
Failed to install the following SDK components: build-tools;35.0.0
Failed to install the following SDK components: cmake;3.22.1
```
Gradle mencoba download/install component yang tidak ada, tapi gagal karena symlink ke Nix store read-only.

**Solusi:** Sertakan semua component yang dibutuhkan di `composeAndroidPackages`:
```nix
buildToolsVersions = [ "34.0.0" "35.0.0" ];
platformVersions = [ "36" ];
cmakeVersions = [ "3.22.1" ];
```

---

**Masalah 4: `flutter doctor` tetap warning "Some Android licenses not accepted"**

Warning ini **tidak blocking** — `flutter build apk` tetap berhasil. Penyebab: flutter doctor menggunakan algoritma verifikasi hash yang berbeda dari sdkmanager. Bisa diabaikan selama build berhasil.

---

### 4.2 Struktur `composeAndroidPackages` yang bekerja

```nix
androidSdk = (pkgs.androidenv.composeAndroidPackages {
  cmdLineToolsVersion = "11.0";       # tools untuk sdkmanager
  platformToolsVersion = "35.0.2";    # adb, fastboot
  buildToolsVersions = [ "34.0.0" "35.0.0" ];  # Gradle build tools
  platformVersions = [ "36" ];        # Android API level
  cmakeVersions = [ "3.22.1" ];       # untuk build native code
  includeEmulator = false;
  includeSystemImages = false;
  includeSources = false;
  extraLicenses = [
    "android-sdk-license"
    "android-sdk-preview-license"
  ];
}).androidsdk;
```

---

## 5. Sumber Belajar

- **[NixOS Wiki — Android](https://nixos.wiki/wiki/Android)** — referensi `androidenv`
- **[Nixpkgs — composeAndroidPackages](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/mobile/androidenv/compose-android-packages.nix)** — semua opsi yang tersedia
- **[flutter.dev — Linux setup](https://docs.flutter.dev/get-started/install/linux/android)** — kebutuhan SDK resmi Flutter
- **Wiki NixOS** — untuk masalah spesifik

---

## 6. Catatan Belajar (Learning Log)

| Tanggal | Yang dipelajari / kendala | Catatan |
|---------|---------------------------|---------|
| 2026-06-03 | **Tahap 1 selesai.** Setup Flutter + Android SDK dari nol. 4 iterasi error sebelum build APK berhasil. | Kendala terbesar: Nix store read-only — butuh local overlay di `~/.android/sdk`. Pola error: setiap SDK component yang missing baru ketahuan saat Gradle jalan. |
| 2026-06-04 | **Tahap 2 selesai.** Buat project Lokagram baru di `flutter-dev/` menggunakan `nix develop --command flutter create`. Copy source code dari project referensi, tambah dependencies, update `AndroidManifest.xml`. | Kendala: project baru pakai `compileSdkVersion 35` → perlu tambah `"35"` ke `platformVersions` di `flake.nix` (sebelumnya hanya `"36"`). Solusi sama: tambah versi ke `composeAndroidPackages`, `nix develop` download otomatis. |
| 2026-06-04 | **Tahap 3 selesai (via emulator).** Setup Android Emulator di Nix: tambah `includeEmulator`, `includeSystemImages`, `systemImageTypes`, `abiVersions` ke `flake.nix`. AVD dibuat otomatis via `shellHook`. `flutter run` berhasil di emulator. | Kendala: emulator not responding → atasi dengan flag `-no-audio -no-snapshot -no-boot-anim`. GPS emulator tidak otomatis → set manual via `adb emu geo fix 112.01667 -7.81667` (Kediri, koordinat dari IP). Software rendering (lavapipe) membuat emulator lambat — HP fisik tetap tujuan utama. |
| 2026-06-04 | **Tahap 3 selesai penuh (HP fisik).** `flutter run` berhasil di Realme RMX1941 via USB. App ter-install, Flutter engine + Geolocator aktif, dialog izin lokasi muncul di HP. | Kendala awal: HP tidak terdeteksi adb → solusi: kabel data (bukan charging only) + USB debugging ON + mode File Transfer. Device ID: `QSEIQGOJDM8DI7FA`. |
| 2026-06-04 | **Tahap 4 selesai.** `nix flake update` tidak ada perubahan (sudah terbaru). Build tetap OK. Dokumentasi cara pin versi Flutter ditambah ke `flake.nix` sebagai komentar. | Flutter yang tersedia di nixpkgs: `flutter324`, `flutter327`, `flutter332`, `flutter338`, `flutter341`, `flutter` (latest). Cara pin: ganti `pkgs.flutter` di `packages = [...]`. |
| 2026-06-04 | **Pengembangan lanjutan: Attendance App.** App Lokagram diubah menjadi app absensi dengan 3 mode GPS. Branch baru `attendance` di repo `mj-rahmadwijaya/lokagram`. | Fitur: Store settings (nama + lokasi + radius + mode GPS), check-in selfie front camera, riwayat absensi lokal. 3 mode: Flexible (geser pin di peta), Fixed GPS (GPS aktual), Anti Fake GPS (deteksi `isMocked`). |
| 2026-06-05 | **Perbaikan UX & fitur baru.** 5 perbaikan UX: tombol Absen sticky di bawah, bottom sheet konfirmasi sebelum kamera, animasi GPS loading, foto riwayat bisa full screen, FAB "Lokasi Saya" di StoreSettings. Tambah peta posisi karyawan vs store di mode Fixed GPS & Anti-Fake. | Fake GPS terdeteksi: sembunyikan status zona, tampilkan hanya peringatan fake GPS. |
| 2026-06-05 | **Branding & splash screen.** Tambah asset logo + icon (Attandance). Warna tema diupdate ke biru #1976D2 + hijau #43A047. Custom animated splash screen: icon bouncing + logo fade-in. Native splash minimal (putih). Packages: `flutter_launcher_icons`, `flutter_native_splash`. | Kendala: cache build menyebabkan assets tidak muncul → solusi: `adb uninstall` + `flutter clean` sebelum run. |
| 2026-06-05 | **Fix GPS cold start & skenario GPS off.** Strategi GPS 3-lapis: (1) lastKnownPosition instant, (2) network position paralel (cell/WiFi, 4s), (3) stream GPS akurasi tinggi. Timeout 8 detik → notif "GPS Tidak Terdeteksi" + tombol Coba Lagi. | Bug: saat GPS dimatikan → buka app → nyalakan GPS → tap Coba Lagi: stream GPS tidak pernah dimulai. Fix: ekstrak `_startLocationTracking()`, panggil di `_initialize()` dan `onRetry`. |
| 2026-06-08 | **Redesign UI total — branch `attendance-2`.** Redesign penuh: SplashScreen → LoginScreen (ShadInput, dummy login `test`/`123456`) → MainScreen dengan bottom nav 4 tab (Beranda, Absensi, Riwayat, Profil). Dependency baru: `shadcn_ui ^0.54.0`. | Semua screen dibangun ulang dari nol dengan design system Shadcn/UI. Login simpan session di SharedPreferences (`is_logged_in`). |
| 2026-06-08 | **HomeTab & AbsensiTab.** HomeTab: header biru, stat card (Hadir/Luar Zona/Bulan), tombol quick-absensi, 5 riwayat terbaru. AbsensiTab: peta karyawan vs store, info lokasi + status badge, jam digital real-time, tombol Check In / Check Out. | Bug: spinner absensi tidak berhenti — loading selesai sebelum GPS tracking dimulai. Fix: set `_loading = false` setelah tracking dimulai. |
| 2026-06-08 | **FakeGpsScreen & RiwayatTab.** FakeGpsScreen: toggle aktifkan fake GPS + pilih lokasi pin di peta OpenStreetMap, simpan ke SharedPreferences. RiwayatTab: kalender bulan, stat hadir/tidak hadir, card per hari dengan jam masuk & keluar. | State stale GPS di AbsensiTab: posisi tidak di-refresh saat tab dipilih ulang. Fix: `MainScreen` panggil `_absensiKey.currentState?.refresh()` setiap kali tab Absensi dipilih. |
| 2026-06-08 | **Check Out + alert GPS real-time.** Alur Check Out: tombol muncul setelah check in, validasi GPS sama dengan check in, konfirmasi bottom sheet, simpan `checkOutTime` ke record. Alert dialog GPS mati di-listen dari `MainScreen` via `Geolocator.getServiceStatusStream()` — tidak bisa di-dismiss sebelum GPS diaktifkan. | Bug: GPS service listener di AbsensiTab dan MainScreen berduplikasi. Refactor: listener global di MainScreen, AbsensiTab punya listener sendiri hanya untuk restart tracking. |
| 2026-06-09 | **Perbaikan badge & stat HomeTab.** Badge riwayat di HomeTab dan RiwayatTab diubah dari "Dalam Zona/Luar Zona" menjadi "Hadir/Absen". Stat card "Luar Zona" di HomeTab diubah menjadi "Absen" dengan logika baru: hitung hari tanpa absensi di bulan ini (`now.day - _hadirCount`). Fix warning `ListTile` di FakeGpsScreen: ganti `Container(color:)` dengan `Material(color:)` sebagai parent `SwitchListTile`. | Warning ListTile muncul karena `Container` dengan `color` menghasilkan `ColoredBox` yang menyembunyikan ink splash Material. |
| 2026-06-09 | **Flexible mode — tap peta untuk set lokasi.** Di AbsensiTab mode GPS Flexible, peta kini interaktif: user tap di peta untuk set pin lokasi sendiri. Tambah state `_flexPin` (LatLng?) dan `_mapCtrl` (MapController). Getter `_effectiveLat`/`_effectiveLng`/`_hasPosition` diupdate untuk prioritaskan `_flexPin` di mode flexible. Hint text "Tap di peta untuk set lokasi Anda" muncul di overlay bawah peta. | Sebelumnya peta selalu non-interaktif (`InteractiveFlag.none`). |
| 2026-06-09 | **Fix AbsensiTab loading terus.** `_loading = false` dipindah sebelum `ensurePermission()` agar UI langsung tampil — GPS tracking berjalan di background setelahnya. Sebelumnya: jika `!mounted` terpenuhi setelah await permission, `_loading` tidak pernah di-set false sehingga spinner tidak berhenti. | Race condition: `if (!mounted) return` sebelum `setState(_loading = false)` bisa ter-trigger saat tab switching cepat. |
| 2026-06-09 | **Branch `attendance-3` — GPS device-only + scan barcode.** Branch baru dengan konsep: GPS hanya dari device (tidak ada flexible/fixed mode), blokir fake GPS via `Position.isMocked`. Alur check-in: scan barcode → simpan (selfie dihapus). Tambah `mobile_scanner ^6.0.0`. Screen baru: `BarcodeScanScreen` dengan frame hijau 260×260, flash toggle, kamera belakang. `AttendanceRecord` tambah field `barcodeData`. | Analyze error awal: referensi `gpsMode` di home_screen/history_screen yang sudah dihapus → delete file-file tersebut. |
| 2026-06-09 | **Perbaikan fake GPS blocking & UX attendance-3.** Tombol Check In/Out di-disable + banner merah "Fake GPS Terdeteksi!" tampil real-time di layar saat mock GPS aktif (app pihak ketiga). Dialog GPS mati/hidup real-time: auto-dismiss saat GPS dinyalakan — implementasi di `MainScreen` dan `HomeTab` via `Geolocator.getServiceStatusStream()`. Hapus fitur Fake GPS internal (FakeGpsScreen dihapus), deteksi murni dari `Position.isMocked`. Tambah fitur "Hapus Semua Data Absensi" di tab Profil (section Testing). | Install APK via `adb install` langsung lebih andal daripada `flutter run` karena APK 138MB sering timeout di flutter run install step. |
| 2026-06-11 | **Redesign alur — wireframe baru, integrasi API.** Alur app dirancang ulang total berdasarkan wireframe dari tim produk. Login ganti dari email/password ke **PIN + unique_id_device + timestamp**. Struktur UI berubah dari 4 tab menjadi single check-in screen + history screen + profile sheet. GPS tidak lagi blokir — hanya tampilkan jarak ke outlet. Alur barcode diperkuat: scan → validasi data device (cocokkan staff_id, outlet_id, unique_id) → konfirmasi → simpan. Semua operasi kini hit API (login, logout, list absensi, profile, checkout) — tahap ini masih dummy, real endpoint menyusul. Auth menggunakan token dari response login. Data karyawan & outlet disimpan lokal di device sebagai `Session`. Detail task di `task.md`. | Perubahan mendasar: app bergerak dari prototype GPS lokal ke app siap integrasi backend GrandePos. |

---

## 7. Cheat-Sheet Flutter di Nix

### A. Masuk dev environment
| Perintah | Keterangan |
|----------|------------|
| `nix develop` | Masuk Flutter dev shell (dari folder dengan `flake.nix`) |
| `exit` | Keluar dari dev shell |
| `nix flake update` | Update semua input (Flutter, SDK) ke versi terbaru di Nixpkgs |

### B. Flutter sehari-hari (dari dalam `nix develop`)
| Perintah | Keterangan |
|----------|------------|
| `flutter doctor` | Cek status environment |
| `flutter create nama_app` | Buat project Flutter baru |
| `flutter pub get` | Install dependencies dari `pubspec.yaml` |
| `flutter build apk --debug` | Build APK debug |
| `flutter build apk --release` | Build APK release (butuh signing) |
| `flutter run` | Run di device yang terhubung |
| `flutter run -d chrome` | Run di Chrome (web) |
| `flutter devices` | Lihat semua device yang tersedia |

### C. Diagnostik
| Perintah | Keterangan |
|----------|------------|
| `flutter doctor -v` | Verbose — tampilkan path & versi semua komponen |
| `echo $ANDROID_HOME` | Cek ANDROID_HOME aktif (harus `~/.android/sdk`) |
| `ls $ANDROID_HOME/licenses/` | Cek license files ada |
| `yes \| sdkmanager --licenses` | Accept semua Android SDK licenses |
| `sdkmanager --list_installed` | Lihat komponen SDK yang ter-install |

### D. Kalau ada SDK component missing saat Gradle build
```
Failed to install the following SDK components: build-tools;X.X.X
```
1. Catat nama component (misal `35.0.0`, `cmake;3.22.1`, `platforms;android-36`)
2. Tambahkan ke `flake.nix`:
   ```nix
   buildToolsVersions = [ "34.0.0" "35.0.0" "X.X.X" ];  # tambah versi baru
   platformVersions = [ "36" "XX" ];                       # atau platform baru
   cmakeVersions = [ "3.22.1" ];                           # atau cmake baru
   ```
3. `exit` dari dev shell
4. `nix develop` lagi (akan download component baru)
5. Build ulang

---

## 8. Template `flake.nix` Flutter (siap pakai)

> File ini ada di `/home/raptor/Documents/Nix/flutter-dev/flake.nix`.
> Copy ke root project Flutter untuk mulai pakai.

```nix
{
  description = "Flutter dev shell — Android target";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
    };

    androidSdk = (pkgs.androidenv.composeAndroidPackages {
      cmdLineToolsVersion = "11.0";
      platformToolsVersion = "35.0.2";
      buildToolsVersions = [ "34.0.0" "35.0.0" ];
      platformVersions = [ "34" "35" "36" ];
      cmakeVersions = [ "3.22.1" ];
      includeEmulator = true;          # set false kalau tidak butuh emulator
      includeSystemImages = true;      # set false kalau tidak butuh emulator
      systemImageTypes = [ "google_apis_playstore" ];
      abiVersions = [ "x86_64" ];
      includeSources = false;
      extraLicenses = [
        "android-sdk-license"
        "android-sdk-preview-license"
      ];
    }).androidsdk;

  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.flutter
        androidSdk
        pkgs.jdk17
        pkgs.git
        pkgs.which
        pkgs.curl
      ];

      JAVA_HOME = "${pkgs.jdk17}";

      shellHook = ''
        NIX_SDK="${androidSdk}/libexec/android-sdk"
        LOCAL_SDK="$HOME/.android/sdk"
        mkdir -p "$LOCAL_SDK"

        for d in "$NIX_SDK"/*/; do
          name=$(basename "$d")
          if [ "$name" != "licenses" ]; then
            ln -sfn "$d" "$LOCAL_SDK/$name"
          fi
        done

        mkdir -p "$LOCAL_SDK/licenses"
        printf "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee\n" \
          > "$LOCAL_SDK/licenses/android-sdk-license"
        printf "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910\n" \
          > "$LOCAL_SDK/licenses/android-sdk-preview-license"

        export ANDROID_HOME="$LOCAL_SDK"
        export ANDROID_SDK_ROOT="$LOCAL_SDK"
        export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

        flutter config --android-sdk "$ANDROID_HOME" --no-analytics 2>/dev/null || true

        echo "Flutter + Android SDK siap. Coba: flutter doctor"
      '';
    };
  };
}
```
