import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of asking the device where it is.
sealed class DeviceLocationResult {
  const DeviceLocationResult();
}

class DeviceLocationFound extends DeviceLocationResult {
  const DeviceLocationFound(this.lat, this.lng);
  final double lat, lng;
}

enum DeviceLocationProblem {
  serviceDisabled,
  permissionDenied,
  deniedForever,
  unavailable
}

class DeviceLocationFailed extends DeviceLocationResult {
  const DeviceLocationFailed(this.problem);
  final DeviceLocationProblem problem;
}

typedef DeviceLocator = Future<DeviceLocationResult> Function();

const _fixTimeout = Duration(seconds: 20);

/// Asks for permission when needed and reads one position; replaced in tests.
final deviceLocatorProvider = Provider<DeviceLocator>((ref) => () async {
      try {
        if (!await Geolocator.isLocationServiceEnabled()) {
          return const DeviceLocationFailed(
              DeviceLocationProblem.serviceDisabled);
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          return const DeviceLocationFailed(
              DeviceLocationProblem.deniedForever);
        }
        if (permission == LocationPermission.denied) {
          return const DeviceLocationFailed(
              DeviceLocationProblem.permissionDenied);
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high, timeLimit: _fixTimeout),
        );
        return DeviceLocationFound(position.latitude, position.longitude);
      } catch (_) {
        return const DeviceLocationFailed(DeviceLocationProblem.unavailable);
      }
    });

/// Opens the system settings where the person can turn location back on.
Future<void> openLocationSettings(DeviceLocationProblem problem) =>
    problem == DeviceLocationProblem.serviceDisabled
        ? Geolocator.openLocationSettings().then((_) {})
        : Geolocator.openAppSettings().then((_) {});
