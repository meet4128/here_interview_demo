import 'dart:async';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/location.dart';

import 'device_position.dart';
import 'native_location_permission_channel.dart';

class LocationPermissionException implements Exception {
  final String message;
  const LocationPermissionException(this.message);

  @override
  String toString() => 'LocationPermissionException: $message';
}

class LocationServicesDisabledException implements Exception {
  final String message;
  const LocationServicesDisabledException(this.message);

  @override
  String toString() => 'LocationServicesDisabledException: $message';
}

class LocationDataSource {
  final LocationEngine _locationEngine;
  final NativeLocationPermissionChannel _permissionChannel;

  const LocationDataSource(this._locationEngine, this._permissionChannel);

  /// Opens the system Location Settings screen
  Future<void> openLocationSettings() {
    return _permissionChannel.openLocationSettings();
  }

  Future<void> _ensureOsPermissionGranted() async {
    final serviceEnabled =
    await _permissionChannel.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException(
        'Location services are disabled on this device.',
      );
    }

    var status = await _permissionChannel.checkPermission();
    if (status == NativeLocationPermissionStatus.denied) {
      status = await _permissionChannel.requestPermission();
    }

    if (status == NativeLocationPermissionStatus.deniedForever) {
      throw const LocationPermissionException(
        'Location permission is permanently denied — enable it from system settings.',
      );
    }
    if (status != NativeLocationPermissionStatus.granted) {
      throw const LocationPermissionException(
        'Location permission was denied.',
      );
    }
  }

  Future<DevicePosition> getCurrentPosition() async {
    await _ensureOsPermissionGranted();

    _locationEngine.confirmHEREPrivacyNoticeInclusion();

    final completer = Completer<Location>();
    late final LocationListener listener;

    listener = LocationListener((Location location) {
      if (!completer.isCompleted) {
        completer.complete(location);
      }
    });

    _locationEngine.addLocationListener(listener);

    final startStatus =
    _locationEngine.startWithLocationAccuracy(LocationAccuracy.bestAvailable);

    if (startStatus != LocationEngineStatus.engineStarted &&
        startStatus != LocationEngineStatus.alreadyStarted &&
        startStatus != LocationEngineStatus.ok) {
      _locationEngine.removeLocationListener(listener);
      throw LocationPermissionException(
        'HERE LocationEngine failed to start: $startStatus',
      );
    }

    try {
      final location =
      await completer.future.timeout(const Duration(seconds: 10));
      return DevicePosition(
        latitude: location.coordinates.latitude,
        longitude: location.coordinates.longitude,
      );
    } on TimeoutException {
      throw const LocationPermissionException(
        'Timed out waiting for a GPS fix.',
      );
    } finally {
      _locationEngine.removeLocationListener(listener);
      _locationEngine.stop();
    }
  }
}