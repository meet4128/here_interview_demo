import 'package:equatable/equatable.dart';

import '../../domain/entities/route_info.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {
  const RouteInitial();
}

class RouteCalculating extends RouteState {
  const RouteCalculating();
}

class RouteReady extends RouteState {
  final RouteInfo route;

  const RouteReady(this.route);

  @override
  List<Object?> get props => [route];
}

class RouteNotFound extends RouteState {
  const RouteNotFound();
}

class RouteError extends RouteState {
  final String message;

  const RouteError(this.message);

  @override
  List<Object?> get props => [message];
}