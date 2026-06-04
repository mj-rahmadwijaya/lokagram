import 'gps_mode.dart';

class Store {
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  final GpsMode gpsMode;

  const Store({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.gpsMode,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
        'gpsMode': gpsMode.name,
      };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        gpsMode: GpsMode.values.byName(json['gpsMode'] as String),
      );

  Store copyWith({
    String? name,
    double? lat,
    double? lng,
    double? radiusMeters,
    GpsMode? gpsMode,
  }) =>
      Store(
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        gpsMode: gpsMode ?? this.gpsMode,
      );
}
