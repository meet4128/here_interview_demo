import 'package:get_it/get_it.dart';
import 'package:here_sdk/location.dart';
import 'package:here_sdk/search.dart';
import 'package:here_sdk/routing.dart' as here_routing;

import '../../features/navigation/data/datasources/navigation_data_source.dart';
import '../../features/navigation/data/repositories/navigation_repository_impl.dart';
import '../../features/navigation/domain/repositories/navigation_repository.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../features/routing/data/datasources/routing_data_source.dart';
import '../../features/routing/data/repositories/routing_repository_impl.dart';
import '../../features/routing/domain/repositories/routing_repository.dart';
import '../../features/routing/presentation/bloc/route_bloc.dart';
import '../../features/search/data/datasources/search_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../location/location_data_source.dart';
import '../location/location_repository.dart';
import '../location/location_repository_impl.dart';
import '../location/native_location_permission_channel.dart';
import '../../features/map_display/data/datasources/map_data_source.dart';
import '../../features/map_display/data/repositories/map_repository_impl.dart';
import '../../features/map_display/domain/repositories/map_repository.dart';
import '../../features/map_display/presentation/bloc/map_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  // HERE SDK engines
  sl.registerLazySingleton<SearchEngine>(() => SearchEngine());
  sl.registerLazySingleton<here_routing.RoutingEngine>(
    () => here_routing.RoutingEngine(),
  );

  sl.registerLazySingleton<LocationEngine>(() => LocationEngine());
  sl.registerLazySingleton<NativeLocationPermissionChannel>(
    () => NativeLocationPermissionChannel(),
  );
  sl.registerLazySingleton<LocationDataSource>(
    () => LocationDataSource(
      sl<LocationEngine>(),
      sl<NativeLocationPermissionChannel>(),
    ),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl<LocationDataSource>()),
  );

  // Feature: Map display
  sl.registerLazySingleton<MapDataSource>(() => MapDataSource());
  sl.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(sl<MapDataSource>()),
  );
  sl.registerFactory(
    () => MapBloc(
      mapRepository: sl<MapRepository>(),
      locationRepository: sl<LocationRepository>(),
    ),
  );

  // Feature: Search
  sl.registerLazySingleton<SearchDataSource>(
    () => SearchDataSource(sl<SearchEngine>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(sl<SearchDataSource>()),
  );

  sl.registerFactory(
    () => SearchBloc(searchRepository: sl<SearchRepository>()),
  );

  // Feature: Routing
  sl.registerLazySingleton<RoutingDataSource>(
    () => RoutingDataSource(sl<here_routing.RoutingEngine>()),
  );
  sl.registerLazySingleton<RoutingRepository>(
    () => RoutingRepositoryImpl(sl<RoutingDataSource>()),
  );
  sl.registerFactory(
    () => RouteBloc(routingRepository: sl<RoutingRepository>()),
  );

  // Feature: Navigation
  sl.registerLazySingleton<NavigationDataSource>(
    () => NavigationDataSource(
      sl<here_routing.RoutingEngine>(),
      sl<LocationEngine>(),
    ),
  );
  sl.registerLazySingleton<NavigationRepository>(
    () => NavigationRepositoryImpl(sl<NavigationDataSource>()),
  );
  sl.registerFactory(
    () => NavigationBloc(navigationRepository: sl<NavigationRepository>()),
  );
}