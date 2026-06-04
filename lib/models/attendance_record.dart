import 'gps_mode.dart';

class AttendanceRecord {
  final String id;
  final String employeeName;
  final DateTime timestamp;
  final String? photoPath;
  final double lat;
  final double lng;
  final bool isInsideZone;
  final bool isMocked;
  final GpsMode gpsMode;

  const AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.timestamp,
    this.photoPath,
    required this.lat,
    required this.lng,
    required this.isInsideZone,
    required this.isMocked,
    required this.gpsMode,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'timestamp': timestamp.toIso8601String(),
        'photoPath': photoPath,
        'lat': lat,
        'lng': lng,
        'isInsideZone': isInsideZone,
        'isMocked': isMocked,
        'gpsMode': gpsMode.name,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        employeeName: json['employeeName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        photoPath: json['photoPath'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        isInsideZone: json['isInsideZone'] as bool,
        isMocked: json['isMocked'] as bool? ?? false,
        gpsMode: GpsMode.values.byName(json['gpsMode'] as String),
      );
}
