import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/mapview.dart' hide MapError;
import 'package:here_sdk/routing.dart' as here_routing;

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/map_camera_position.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../../../search/domain/entities/place_result.dart';
import '../../../search/presentation/bloc/search_bloc.dart';
import '../../../search/presentation/bloc/search_event.dart';
import '../../../search/presentation/bloc/search_state.dart';
import '../../../routing/domain/entities/route_info.dart';
import '../../../routing/presentation/bloc/route_bloc.dart';
import '../../../routing/presentation/bloc/route_event.dart';
import '../../../routing/presentation/bloc/route_state.dart';
import '../../../navigation/presentation/bloc/navigation_bloc.dart';
import '../../../navigation/presentation/bloc/navigation_event.dart';
import '../../../navigation/presentation/bloc/navigation_state.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapBloc>(
          create: (_) => sl<MapBloc>()..add(const MapLocationRequested()),
        ),
        BlocProvider<SearchBloc>(create: (_) => sl<SearchBloc>()),
        BlocProvider<RouteBloc>(create: (_) => sl<RouteBloc>()),
        BlocProvider<NavigationBloc>(create: (_) => sl<NavigationBloc>()),
      ],
      child: const _MapView(),
    );
  }
}

MapCameraPosition? _currentMapPosition(MapState state) {
  if (state is MapReady) return state.currentPosition;
  if (state is MapLocationReady) return state.initialCameraPosition;
  return null;
}

/// Maps a HERE `ManeuverAction` to a reasonable Material icon. Uses
IconData _iconForManeuverAction(here_routing.ManeuverAction action) {
  final name = action.name;
  if (name == 'depart') return Icons.trip_origin;
  if (name == 'arrive') return Icons.flag;
  if (name.contains('UTurn')) return Icons.u_turn_left;
  if (name.contains('sharpLeft') || name == 'leftTurn') return Icons.turn_left;
  if (name.contains('sharpRight') || name == 'rightTurn') {
    return Icons.turn_right;
  }
  if (name.contains('slightLeft')) return Icons.turn_slight_left;
  if (name.contains('slightRight')) return Icons.turn_slight_right;
  if (name.contains('Roundabout')) return Icons.roundabout_left;
  if (name.contains('Ramp') || name.contains('Exit') || name.contains('Fork')) {
    return Icons.merge;
  }
  return Icons.straight; // continueOn, and anything else unhandled
}

String _formatDistance(int meters) {
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
  return '$meters m';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '$hours h $minutes min';
  return '$minutes min';
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> with WidgetsBindingObserver {
  HereMapController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final bloc = context.read<MapBloc>();
      if (bloc.state is MapLocationServiceDisabled) {
        bloc.add(const MapLocationRequested());
      }
    }
  }

  void _onMapCreated(HereMapController controller) {
    _controller = controller;
    context.read<MapBloc>().add(MapStarted(controller));
  }

  void _onStartNavigation(RouteInfo route) {
    final controller = _controller;
    if (controller == null) return;

    final origin = context.read<MapBloc>().deviceLocation;
    final destination = route.polyline.last;

    context.read<NavigationBloc>().add(
      NavigationStarted(
        controller: controller,
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<RouteBloc, RouteState>(
        listener: (context, routeState) {
          final mapBloc = context.read<MapBloc>();
          if (routeState is RouteReady) {
            mapBloc.add(MapRouteDrawRequested(routeState.route.polyline));
          } else if (routeState is RouteInitial ||
              routeState is RouteNotFound ||
              routeState is RouteError) {
            mapBloc.add(const MapRouteCleared());
          }
        },
        child: BlocBuilder<MapBloc, MapState>(
          builder: (context, mapState) {
            if (mapState is MapInitial || mapState is MapLocationLoading) {
              return const _LoadingIndicator(label: 'Getting your location…');
            }

            if (mapState is MapLocationServiceDisabled) {
              return _LocationServicesDisabledPrompt(
                onEnablePressed: () => context
                    .read<MapBloc>()
                    .add(const MapLocationSettingsRequested()),
              );
            }

            final currentPosition = _currentMapPosition(mapState);

            return Stack(
              children: [
                HereMap(
                  onMapCreated: _onMapCreated,
                  mode: NativeViewMode.hybridComposition,
                ),
                if (mapState is MapSceneLoading)
                  const _LoadingIndicator(label: 'Loading map…'),
                if (mapState is MapError)
                  _MapErrorCard(message: mapState.message),
                if (currentPosition != null)
                  BlocBuilder<NavigationBloc, NavigationState>(
                    builder: (context, navState) {
                      if (navState is NavigationInitial) {
                        return Stack(
                          children: [
                            _SearchOverlay(currentPosition: currentPosition),
                            BlocBuilder<RouteBloc, RouteState>(
                              builder: (context, routeState) =>
                                  _RouteSummaryCard(
                                    routeState: routeState,
                                    onStartNavigation: _onStartNavigation,
                                  ),
                            ),
                          ],
                        );
                      }
                      return _NavigationOverlay(
                        navState: navState,
                        onStop: () => context
                            .read<NavigationBloc>()
                            .add(const NavigationStopped()),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  final RouteState routeState;
  final void Function(RouteInfo route) onStartNavigation;

  const _RouteSummaryCard({
    required this.routeState,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final routeState = this.routeState;
    Widget? content;

    if (routeState is RouteCalculating) {
      content = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Calculating route…'),
        ],
      );
    } else if (routeState is RouteNotFound) {
      content = const Text('No route could be found between these two points.');
    } else if (routeState is RouteError) {
      content = Text('Route failed: ${routeState.message}');
    } else if (routeState is RouteReady) {
      final route = routeState.route;
      content = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(route.duration),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDistance(route.lengthInMeters),
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => onStartNavigation(route),
            icon: const Icon(Icons.navigation),
            label: const Text('Start'),
          ),
        ],
      );
    }

    if (content == null) return const SizedBox.shrink(); // RouteInitial

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(padding: const EdgeInsets.all(16), child: content),
          ),
        ),
      ),
    );
  }
}

class _NavigationOverlay extends StatelessWidget {
  final NavigationState navState;
  final VoidCallback onStop;

  const _NavigationOverlay({required this.navState, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final navState = this.navState;

    if (navState is NavigationStarting) {
      return const _LoadingIndicator(label: 'Starting navigation…');
    }

    if (navState is NavigationRunning) {
      final instruction = navState.instruction;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_iconForManeuverAction(instruction.action), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatDistance(instruction.distanceToNextManeuverInMeters)} · ${instruction.roadName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          instruction.instructionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Stop navigation',
                    onPressed: onStop,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (navState is NavigationArrived) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('You have arrived at your destination.'),
                  ),
                  FilledButton(onPressed: onStop, child: const Text('Done')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (navState is NavigationError) {
      return _MapErrorCard(message: navState.message);
    }

    return const SizedBox.shrink();
  }
}

class _SearchOverlay extends StatefulWidget {
  final MapCameraPosition currentPosition;

  const _SearchOverlay({required this.currentPosition});

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    context.read<SearchBloc>().add(
      SearchQueryChanged(
        query: query,
        areaCenterLatitude: widget.currentPosition.latitude,
        areaCenterLongitude: widget.currentPosition.longitude,
      ),
    );
  }

  void _onResultTapped(PlaceResult result) {
    if (!result.hasCoordinates) return;

    final mapBloc = context.read<MapBloc>();
    final origin = mapBloc.deviceLocation;

    mapBloc.add(
      MapCameraMoveRequested(
        MapCameraPosition(
          latitude: result.latitude!,
          longitude: result.longitude!,
        ),
      ),
    );

    context.read<RouteBloc>().add(
      RouteRequested(
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        destinationLatitude: result.latitude!,
        destinationLongitude: result.longitude!,
      ),
    );

    _controller.text = result.title;
    _focusNode.unfocus();
    _onQueryChanged(''); // collapses the results list back to SearchInitial
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search for a place or address',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _onQueryChanged('');
                      },
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const _ResultsCard(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (state is SearchEmpty) {
                  return const _ResultsCard(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No results found.'),
                    ),
                  );
                }
                if (state is SearchError) {
                  return _ResultsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Search failed: ${state.message}'),
                    ),
                  );
                }
                if (state is SearchLoaded) {
                  return _ResultsCard(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = state.results[index];
                          return ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(result.title),
                            subtitle: Text(
                              result.addressText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            enabled: result.hasCoordinates,
                            onTap: () => _onResultTapped(result),
                          );
                        },
                      ),
                    ),
                  );
                }
                // SearchInitial — nothing to show below the search bar.
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final Widget child;

  const _ResultsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final String label;

  const _LoadingIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _LocationServicesDisabledPrompt extends StatelessWidget {
  final VoidCallback onEnablePressed;

  const _LocationServicesDisabledPrompt({required this.onEnablePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Location services are turned off',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Turn on Location Services to center the map on your current position.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onEnablePressed,
              child: const Text('Turn on Location Services'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapErrorCard extends StatelessWidget {
  final String message;

  const _MapErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Map failed to load: $message'),
        ),
      ),
    );
  }
}