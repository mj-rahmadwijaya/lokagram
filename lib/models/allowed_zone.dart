/// Model data (DTO) untuk satu "zona yang diizinkan".
/// Class biasa tanpa dependency Flutter — murni data.
class AllowedZone {
  // Semua field 'final' = immutable. Setelah object dibuat, nilainya tidak
  // bisa diubah. Untuk "mengubah", buat object baru (lihat copyWith di bawah).
  final double lat; // latitude pusat zona
  final double lng; // longitude pusat zona
  final double radiusMeters; // radius zona dalam meter

  // Constructor dengan named parameters + 'required'.
  // const → bisa jadi compile-time constant kalau argumennya juga const.
  const AllowedZone({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  /// Pattern idiomatic Dart untuk "update" object immutable: bikin salinan
  /// dengan sebagian field diganti. Parameter nullable (double?) → kalau tidak
  /// diisi, pakai nilai lama. Operator '??' = "kalau kiri null, pakai kanan".
  AllowedZone copyWith({double? lat, double? lng, double? radiusMeters}) {
    return AllowedZone(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }

  /// Override toString untuk debug print yang readable.
  /// Tanpa ini, print(zone) cuma keluar "Instance of 'AllowedZone'".
  /// '$var' = interpolasi sederhana, '${expr}' = interpolasi ekspresi.
  @override
  String toString() => 'AllowedZone(lat: $lat, lng: $lng, radius: ${radiusMeters}m)';
}
