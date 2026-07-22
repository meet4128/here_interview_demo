import 'package:equatable/equatable.dart';

import '../../domain/entities/navigation_instruction.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationInitial extends NavigationState {
  const NavigationInitial();
}

class NavigationStarting extends NavigationState {
  const NavigationStarting();
}


class NavigationRunning extends NavigationState {
  final NavigationInstruction instruction;

  const NavigationRunning(this.instruction);

  @override
  List<Object?> get props => [instruction];
}

class NavigationArrived extends NavigationState {
  const NavigationArrived();
}

class NavigationError extends NavigationState {
  final String message;

  const NavigationError(this.message);

  @override
  List<Object?> get props => [message];
}