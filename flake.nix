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

    # Rakit Android SDK — hanya komponen yang benar-benar dibutuhkan Flutter
    androidSdk = (pkgs.androidenv.composeAndroidPackages {
      cmdLineToolsVersion = "11.0";
      platformToolsVersion = "35.0.2";
      buildToolsVersions = [ "34.0.0" "35.0.0" ];
      platformVersions = [ "34" "35" "36" ];
      cmakeVersions = [ "3.22.1" ];
      includeEmulator = true;
      includeSystemImages = true;
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
        # Ganti pkgs.flutter dengan versi spesifik kalau perlu pin:
        # pkgs.flutter324  → 3.24.x
        # pkgs.flutter327  → 3.27.x
        # pkgs.flutter332  → 3.32.x
        # pkgs.flutter338  → 3.38.x
        # pkgs.flutter341  → 3.41.x (sama dengan pkgs.flutter saat ini)
        pkgs.flutter
        androidSdk
        pkgs.jdk17
        pkgs.git
        pkgs.which
        pkgs.curl
      ];

      JAVA_HOME = "${pkgs.jdk17}";

      shellHook = ''
        # -------------------------------------------------------
        # Masalah: Nix store read-only → flutter doctor --android-licenses
        # tidak bisa menulis ke $ANDROID_HOME/licenses/.
        #
        # Solusi: buat local overlay di ~/.android/sdk dengan
        # symlink ke komponen SDK di Nix store, tapi folder
        # licenses/ tetap writable di filesystem lokal.
        # -------------------------------------------------------
        NIX_SDK="${androidSdk}/libexec/android-sdk"
        LOCAL_SDK="$HOME/.android/sdk"
        mkdir -p "$LOCAL_SDK"

        # Symlink semua komponen SDK (kecuali licenses — kita tangani sendiri)
        for d in "$NIX_SDK"/*/; do
          name=$(basename "$d")
          if [ "$name" != "licenses" ]; then
            ln -sfn "$d" "$LOCAL_SDK/$name"
          fi
        done

        # Tulis license hashes yang diperlukan Flutter ke folder writable
        mkdir -p "$LOCAL_SDK/licenses"
        printf "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee\n" \
          > "$LOCAL_SDK/licenses/android-sdk-license"
        printf "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910\n" \
          > "$LOCAL_SDK/licenses/android-sdk-preview-license"

        export ANDROID_HOME="$LOCAL_SDK"
        export ANDROID_SDK_ROOT="$LOCAL_SDK"
        export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

        flutter config --android-sdk "$ANDROID_HOME" --no-analytics 2>/dev/null || true

        # Buat AVD "lokagram_emu" kalau belum ada
        if ! avdmanager list avd 2>/dev/null | grep -q "lokagram_emu"; then
          echo "Membuat AVD lokagram_emu (API 34, x86_64)..."
          echo "no" | avdmanager create avd \
            --name lokagram_emu \
            --package "system-images;android-34;google_apis_playstore;x86_64" \
            --device "pixel_6" 2>/dev/null && echo "AVD berhasil dibuat." || echo "AVD gagal dibuat (tidak blocking)."
        fi

        echo "==================================="
        echo " Flutter + Android SDK siap!"
        echo " Flutter : $(flutter --version 2>&1 | head -1)"
        echo " Java    : $(java -version 2>&1 | head -1)"
        echo " SDK     : $ANDROID_HOME"
        echo "==================================="
        echo " Jalankan emulator : emulator -avd lokagram_emu -accel on &"
        echo " Lalu build & run  : flutter run"
        echo "==================================="
      '';
    };
  };
}
