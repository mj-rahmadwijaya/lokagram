import 'dart:math';

// --- Response models ---

class LoginResponse {
  final bool success;
  final String? token;
  final String? logoUrl;
  final OutletInfo? outlet;
  final KaryawanInfo? karyawan;
  final String message;

  const LoginResponse({
    required this.success,
    this.token,
    this.logoUrl,
    this.outlet,
    this.karyawan,
    required this.message,
  });
}

class OutletInfo {
  final String outletId;
  final String name;
  final String alamat;
  final double lat;
  final double lng;

  const OutletInfo({
    required this.outletId,
    required this.name,
    required this.alamat,
    required this.lat,
    required this.lng,
  });
}

class KaryawanInfo {
  final String staffId;
  final String outletId;
  final String uniqueId;

  const KaryawanInfo({
    required this.staffId,
    required this.outletId,
    required this.uniqueId,
  });
}

class ProfileResponse {
  final String nama;
  final String phone;
  final String outletId;
  final String outletName;
  final String alamat;
  final String? photoUrl;

  const ProfileResponse({
    required this.nama,
    required this.phone,
    required this.outletId,
    required this.outletName,
    required this.alamat,
    this.photoUrl,
  });
}

class AbsensiItem {
  final DateTime tanggal;
  final String jam;
  final String status; // 'hadir' | 'absen'

  const AbsensiItem({
    required this.tanggal,
    required this.jam,
    required this.status,
  });
}

class CheckoutResponse {
  final bool success;
  final String message;

  const CheckoutResponse({required this.success, required this.message});
}

// --- Dummy data ---

const _dummyToken = 'dummy-token-abc123xyz';

const _dummyOutlet = OutletInfo(
  outletId: '1234567890',
  name: 'Store Satu',
  alamat: 'Jl. A yani Surabaya',
  lat: -7.2575,
  lng: 112.7521,
);

const _dummyKaryawan = KaryawanInfo(
  staffId: 'STF-001',
  outletId: '1234567890',
  uniqueId: 'DEVICE-UNIQUE-001',
);

// --- ApiService ---

class ApiService {
  static final _rng = Random();

  static Future<void> _delay() => Future.delayed(
        Duration(milliseconds: 500 + _rng.nextInt(300)),
      );

  Future<LoginResponse> login({
    required String pin,
    required String uniqueIdDevice,
    required DateTime timestamp,
  }) async {
    await _delay();

    // Dummy: pin '1234' sukses, selain itu gagal
    if (pin != '1234') {
      return const LoginResponse(
        success: false,
        message: 'PIN salah. Silakan coba lagi.',
      );
    }

    return LoginResponse(
      success: true,
      token: _dummyToken,
      logoUrl: null,
      outlet: _dummyOutlet,
      karyawan: _dummyKaryawan,
      message: 'Login berhasil.',
    );
  }

  Future<bool> logout({required String token}) async {
    await _delay();
    return true;
  }

  Future<ProfileResponse> getProfile({required String token}) async {
    await _delay();
    return const ProfileResponse(
      nama: 'Budi Santoso',
      phone: '08999999100',
      outletId: '1234567890',
      outletName: 'Store Satu',
      alamat: 'Jl. A yani Surabaya',
      photoUrl: null,
    );
  }

  Future<List<AbsensiItem>> getAbsensiList({required String token}) async {
    await _delay();
    final now = DateTime.now();
    return [
      AbsensiItem(
          tanggal: now,
          jam: '07:00:30',
          status: 'hadir'),
      AbsensiItem(
          tanggal: now.subtract(const Duration(days: 1)),
          jam: '07:15:10',
          status: 'hadir'),
      AbsensiItem(
          tanggal: now.subtract(const Duration(days: 2)),
          jam: '--:--',
          status: 'absen'),
      AbsensiItem(
          tanggal: now.subtract(const Duration(days: 3)),
          jam: '07:02:45',
          status: 'hadir'),
      AbsensiItem(
          tanggal: now.subtract(const Duration(days: 4)),
          jam: '07:30:00',
          status: 'hadir'),
    ];
  }

  Future<CheckoutResponse> checkout({required String token}) async {
    await _delay();
    return const CheckoutResponse(
      success: true,
      message: 'Check out berhasil.',
    );
  }
}
