import 'package:equatable/equatable.dart';
import 'package:here_sdk/routing.dart' as here_routing;

class NavigationInstruction extends Equatable {
  final String instructionText;
  final here_routing.ManeuverAction action;
  final int distanceToNextManeuverInMeters;
  final String roadName;
  /// True only for the terminal "you have arrived" event.
  final bool isArrival;

  const NavigationInstruction({
    required this.instructionText,
    required this.action,
    required this.distanceToNextManeuverInMeters,
    required this.roadName,
    this.isArrival = false,
  });

  @override
  List<Object?> get props => [
    instructionText,
    action,
    distanceToNextManeuverInMeters,
    roadName,
    isArrival,
  ];
}