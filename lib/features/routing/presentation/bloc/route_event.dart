import 'package:equatable/equatable.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class RouteRequested extends RouteEvent {
  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;

  const RouteRequested({
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  List<Object?> get props => [
    originLatitude,
    originLongitude,
    destinationLatitude,
    destinationLongitude,
  ];
}

class RouteCleared extends RouteEvent {
  const RouteCleared();
}