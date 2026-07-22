import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart' show HereMapController;

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigationStarted extends NavigationEvent {
  final HereMapController controller;
  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;

  const NavigationStarted({
    required this.controller,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  List<Object?> get props => [
    controller,
    originLatitude,
    originLongitude,
    destinationLatitude,
    destinationLongitude,
  ];
}

/// Stops navigation and returns to `NavigationInitial`.
class NavigationStopped extends NavigationEvent {
  const NavigationStopped();
}