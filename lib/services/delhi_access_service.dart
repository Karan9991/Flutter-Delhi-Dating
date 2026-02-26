import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum DelhiAccessStatus {
  initial,
  checking,
  allowed,
  outsideDelhi,
  permissionDenied,
  permissionDeniedForever,
  locationServicesDisabled,
  error,
}

class DelhiAccessResult {
  const DelhiAccessResult({
    required this.status,
    required this.message,
    this.distanceKm,
  });

  final DelhiAccessStatus status;
  final String message;
  final double? distanceKm;

  bool get isAllowed => status == DelhiAccessStatus.allowed;
}

class DelhiAccessService {
  static const double _delhiCenterLatitude = 28.6139;
  static const double _delhiCenterLongitude = 77.2090;
  static const double _allowedRadiusMeters = 45000000000;

  Future<DelhiAccessResult> verifyDelhiAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const DelhiAccessResult(
        status: DelhiAccessStatus.locationServicesDisabled,
        message:
            'Location services are turned off. Please enable location to continue.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const DelhiAccessResult(
        status: DelhiAccessStatus.permissionDenied,
        message:
            'Delhi Dating needs location access to confirm you are in Delhi.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const DelhiAccessResult(
        status: DelhiAccessStatus.permissionDeniedForever,
        message:
            'Location permission is permanently denied. Please allow it from app settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _delhiCenterLatitude,
        _delhiCenterLongitude,
      );

      if (distanceMeters <= _allowedRadiusMeters) {
        return const DelhiAccessResult(
          status: DelhiAccessStatus.allowed,
          message: 'Location verified. You are in Delhi.',
        );
      }

      final distanceKm = distanceMeters / 1000;
      return DelhiAccessResult(
        status: DelhiAccessStatus.outsideDelhi,
        distanceKm: distanceKm,
        message:
            'Delhi Dating is currently available only for users located in Delhi.',
      );
    } on TimeoutException {
      return const DelhiAccessResult(
        status: DelhiAccessStatus.error,
        message: 'We could not verify your location in time. Please try again.',
      );
    } catch (_) {
      return const DelhiAccessResult(
        status: DelhiAccessStatus.error,
        message: 'Unable to verify location right now. Please try again.',
      );
    }
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
