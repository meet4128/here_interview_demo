import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/mapview.dart' hide MapError;

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/map_camera_position.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../../../search/domain/entities/place_result.dart';
import '../../../search/presentation/bloc/search_bloc.dart';
import '../../../search/presentation/bloc/search_event.dart';
import '../../../search/presentation/bloc/search_state.dart';
import '../../../routing/presentation/bloc/route_bloc.dart';
import '../../../routing/presentation/bloc/route_event.dart';
import '../../../routing/presentation/bloc/route_state.dart';

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

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> with WidgetsBindingObserver {
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
    context.read<MapBloc>().add(MapStarted(controller));
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
                if (mapState is MapError) _MapErrorCard(message: mapState.message),
                if (currentPosition != null)
                  _SearchOverlay(currentPosition: currentPosition),
              ],
            );
          },
        ),
      ),
    );
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
    _onQueryChanged('');
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