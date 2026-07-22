import 'package:equatable/equatable.dart';

/// catch HERE SDK exceptions/error enums and map them to one of these —
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Network/backend-side failure
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// A required device permission.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// A requested resource (place, route, address) could not be found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure specific to turn-by-turn navigation/guidance.
class NavigationFailure extends Failure {
  const NavigationFailure(super.message);
}

/// Failure specific to loading or interacting with the map scene itself
class MapFailure extends Failure {
  const MapFailure(super.message);
}


/// the device's system-wide Location Services
class LocationServicesDisabledFailure extends Failure {
  const LocationServicesDisabledFailure(super.message);
}