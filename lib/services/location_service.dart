import 'package:geolocator/geolocator.dart';
import '../models/store.dart';

class LocationService {
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getLastKnownPosition() {
    return Geolocator.getLastKnownPosition();
  }

  Future<Position?> getNetworkPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
    }
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  double distanceTo(double lat, double lng, Store store) {
    return Geolocator.distanceBetween(lat, lng, store.lat, store.lng);
  }

  bool isInsideZone(double lat, double lng, Store store) {
    return distanceTo(lat, lng, store) <= store.radiusMeters;
  }
}
