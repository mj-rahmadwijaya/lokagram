class AttendanceRecord {
  final String id;
  final String employeeName;
  final DateTime timestamp;
  final DateTime? checkOutTime;
  final String? photoPath;
  final double lat;
  final double lng;
  final bool isInsideZone;
  final bool isMocked;
  final String? barcodeData;

  const AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.timestamp,
    this.checkOutTime,
    this.photoPath,
    required this.lat,
    required this.lng,
    required this.isInsideZone,
    required this.isMocked,
    this.barcodeData,
  });

  AttendanceRecord copyWith({DateTime? checkOutTime}) => AttendanceRecord(
        id: id,
        employeeName: employeeName,
        timestamp: timestamp,
        checkOutTime: checkOutTime ?? this.checkOutTime,
        photoPath: photoPath,
        lat: lat,
        lng: lng,
        isInsideZone: isInsideZone,
        isMocked: isMocked,
        barcodeData: barcodeData,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'timestamp': timestamp.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'photoPath': photoPath,
        'lat': lat,
        'lng': lng,
        'isInsideZone': isInsideZone,
        'isMocked': isMocked,
        'barcodeData': barcodeData,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        employeeName: json['employeeName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        checkOutTime: json['checkOutTime'] != null
            ? DateTime.parse(json['checkOutTime'] as String)
            : null,
        photoPath: json['photoPath'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        isInsideZone: json['isInsideZone'] as bool,
        isMocked: json['isMocked'] as bool? ?? false,
        barcodeData: json['barcodeData'] as String?,
      );
}
