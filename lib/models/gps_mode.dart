enum GpsMode {
  flexible,
  fixed,
  antiFake;

  String get label {
    switch (this) {
      case GpsMode.flexible:
        return 'Flexible';
      case GpsMode.fixed:
        return 'Fixed GPS';
      case GpsMode.antiFake:
        return 'Anti Fake GPS';
    }
  }

  String get description {
    switch (this) {
      case GpsMode.flexible:
        return 'Test 1 — karyawan bisa geser lokasi GPS di peta';
      case GpsMode.fixed:
        return 'Test 2 — GPS harus benar-benar di lokasi store';
      case GpsMode.antiFake:
        return 'Test 3 — GPS nyata + blokir fake GPS';
    }
  }
}
