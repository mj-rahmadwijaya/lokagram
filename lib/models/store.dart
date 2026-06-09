class Store {
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  const Store({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
      };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
      );

  Store copyWith({
    String? name,
    double? lat,
    double? lng,
    double? radiusMeters,
  }) =>
      Store(
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radiusMeters: radiusMeters ?? this.radiusMeters,
      );
}
