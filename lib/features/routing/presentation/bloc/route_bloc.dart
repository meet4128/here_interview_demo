import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/routing_repository.dart';
import 'route_event.dart';
import 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RoutingRepository _routingRepository;

  RouteBloc({required RoutingRepository routingRepository})
      : _routingRepository = routingRepository,
        super(const RouteInitial()) {
    on<RouteRequested>(_onRouteRequested, transformer: restartable());
    on<RouteCleared>(_onRouteCleared);
  }

  Future<void> _onRouteRequested(
      RouteRequested event,
      Emitter<RouteState> emit,
      ) async {
    emit(const RouteCalculating());

    final result = await _routingRepository.calculateCarRoute(
      originLatitude: event.originLatitude,
      originLongitude: event.originLongitude,
      destinationLatitude: event.destinationLatitude,
      destinationLongitude: event.destinationLongitude,
    );

    result.fold(
          (failure) {
        if (failure is NotFoundFailure) {
          emit(const RouteNotFound());
          return;
        }
        emit(RouteError(failure.message));
      },
          (route) => emit(RouteReady(route)),
    );
  }

  void _onRouteCleared(RouteCleared event, Emitter<RouteState> emit) {
    emit(const RouteInitial());
  }
}