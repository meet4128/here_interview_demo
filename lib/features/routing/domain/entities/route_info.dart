import 'package:equatable/equatable.dart';

import '../../../../core/entities/geo_point.dart';

class RoutePoint extends Equatable {
  final double latitude;
  final double longitude;

  const RoutePoint({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class RouteInfo extends Equatable {
  final List<GeoPoint> polyline;
  final int lengthInMeters;
  final Duration duration;

  const RouteInfo({
    required this.polyline,
    required this.lengthInMeters,
    required this.duration,
  });

  @override
  List<Object?> get props => [polyline, lengthInMeters, duration];
}