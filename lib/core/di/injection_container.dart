import 'package:get_it/get_it.dart';
import 'package:here_sdk/location.dart';
import 'package:here_sdk/search.dart';
import 'package:here_sdk/routing.dart' as here_routing;

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

/// Service locator. `sl` is the conventional short name so call sites
/// read as `sl<MapRepository>()` rather than `serviceLocator<MapRepository>()`.
final sl = GetIt.instance;

/// Registers every dependency the app needs. Call this once from
/// `main()`, *after* `HereSdkInitializer.initialize(...)` completes and
/// *before* `runApp(...)`.
///
/// Everything here is a `lazySingleton` (constructed on first use, then
/// reused for the app's lifetime) except BLoCs, which are `factory`
/// (a fresh instance every time one is requested — i.e. once per screen
/// visit, so BLoC state doesn't leak between visits to the same screen).
///
/// Registering engines/data sources/repositories as *lazy* singletons
/// (rather than eager ones) is what makes call order safe: nothing here
/// actually touches the HERE SDK until the first `sl<T>()` call for it,
/// by which point `HereSdkInitializer.initialize()` has already run.
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

  // ---------------------------------------------------------------------
  // Feature: Navigation (optional) — same shape, plus the per-session
  // VisualNavigator factory mentioned above:
  // ---------------------------------------------------------------------
  // sl.registerFactory<here.VisualNavigator>(() => here.VisualNavigator());
  // sl.registerLazySingleton<NavigationDataSource>(
  //   () => NavigationDataSource(),
  // );
  // sl.registerLazySingleton<NavigationRepository>(
  //   () => NavigationRepositoryImpl(sl<NavigationDataSource>()),
  // );
  // sl.registerFactory(() => NavigationBloc(navigationRepository: sl()));
}