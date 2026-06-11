class Session {
  final String token;
  final String staffId;
  final String outletId;
  final String uniqueId;
  final String employeeName;
  final String phone;
  final String outletName;
  final String outletAddress;
  final double outletLat;
  final double outletLng;
  final String? logoUrl;

  const Session({
    required this.token,
    required this.staffId,
    required this.outletId,
    required this.uniqueId,
    required this.employeeName,
    required this.phone,
    required this.outletName,
    required this.outletAddress,
    required this.outletLat,
    required this.outletLng,
    this.logoUrl,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'staffId': staffId,
        'outletId': outletId,
        'uniqueId': uniqueId,
        'employeeName': employeeName,
        'phone': phone,
        'outletName': outletName,
        'outletAddress': outletAddress,
        'outletLat': outletLat,
        'outletLng': outletLng,
        'logoUrl': logoUrl,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token'] as String,
        staffId: json['staffId'] as String,
        outletId: json['outletId'] as String,
        uniqueId: json['uniqueId'] as String,
        employeeName: json['employeeName'] as String,
        phone: json['phone'] as String,
        outletName: json['outletName'] as String,
        outletAddress: json['outletAddress'] as String,
        outletLat: (json['outletLat'] as num).toDouble(),
        outletLng: (json['outletLng'] as num).toDouble(),
        logoUrl: json['logoUrl'] as String?,
      );
}
