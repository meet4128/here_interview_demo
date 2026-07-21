import 'package:equatable/equatable.dart';

class MapCameraPosition extends Equatable {
  final double latitude;
  final double longitude;

  /// How far the camera sits from the earth's surface, in meters.
  final double distanceToEarthInMeters;

  const MapCameraPosition({
    required this.latitude,
    required this.longitude,
    this.distanceToEarthInMeters = 8000,
  });

  @override
  List<Object?> get props => [latitude, longitude, distanceToEarthInMeters];
}