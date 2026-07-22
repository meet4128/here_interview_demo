import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/navigation_instruction.dart';
import '../../domain/repositories/navigation_repository.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NavigationRepository _navigationRepository;

  NavigationBloc({required NavigationRepository navigationRepository})
      : _navigationRepository = navigationRepository,
        super(const NavigationInitial()) {
    on<NavigationStarted>(_onNavigationStarted);
    on<NavigationStopped>(_onNavigationStopped);
  }

  Future<void> _onNavigationStarted(
      NavigationStarted event,
      Emitter<NavigationState> emit,
      ) async {
    emit(const NavigationStarting());

    final result = await _navigationRepository.startNavigation(
      controller: event.controller,
      originLatitude: event.originLatitude,
      originLongitude: event.originLongitude,
      destinationLatitude: event.destinationLatitude,
      destinationLongitude: event.destinationLongitude,
    );

    await result.fold(
          (failure) async => emit(NavigationError(failure.message)),
          (instructionStream) async {
        await emit.forEach<NavigationInstruction>(
          instructionStream,
          onData: (instruction) => instruction.isArrival
              ? const NavigationArrived()
              : NavigationRunning(instruction),
          onError: (error, stackTrace) =>
              NavigationError('Navigation stream error: $error'),
        );
      },
    );
  }

  void _onNavigationStopped(
      NavigationStopped event,
      Emitter<NavigationState> emit,
      ) {
    _navigationRepository.stopNavigation();
    emit(const NavigationInitial());
  }

  @override
  Future<void> close() {
    _navigationRepository.stopNavigation();
    return super.close();
  }
}