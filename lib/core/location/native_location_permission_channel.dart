import 'package:flutter/services.dart';

enum NativeLocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}

class NativeLocationPermissionException implements Exception {
  final String message;
  const NativeLocationPermissionException(this.message);

  @override
  String toString() => 'NativeLocationPermissionException: $message';
}

class NativeLocationPermissionChannel {
  static const MethodChannel _channel =
  MethodChannel('here_navigate_demo/location_permission');

  /// Opens the system Location Settings screen
  Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod<void>('openLocationSettings');
    } on PlatformException catch (e) {
      throw NativeLocationPermissionException(
        'Failed to open location settings: ${e.message}',
      );
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      final result =
      await _channel.invokeMethod<bool>('isLocationServiceEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      throw NativeLocationPermissionException(
        'Failed to check location service status: ${e.message}',
      );
    }
  }

  /// Checks current status without prompting the user.
  Future<NativeLocationPermissionStatus> checkPermission() async {
    return _invokeAndParse('checkPermission');
  }

  /// Triggers the OS permission dialog if not already granted
  Future<NativeLocationPermissionStatus> requestPermission() async {
    return _invokeAndParse('requestPermission');
  }

  Future<NativeLocationPermissionStatus> _invokeAndParse(
      String method,
      ) async {
    try {
      final result = await _channel.invokeMethod<String>(method);
      switch (result) {
        case 'granted':
          return NativeLocationPermissionStatus.granted;
        case 'deniedForever':
          return NativeLocationPermissionStatus.deniedForever;
        case 'denied':
        default:
          return NativeLocationPermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      throw NativeLocationPermissionException(
        'Native permission channel error ($method): ${e.message}',
      );
    }
  }
}