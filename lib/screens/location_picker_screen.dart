import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

export '../services/location_service.dart' show PickedLocation;

/// Lets a seller choose the exact property position on an OpenStreetMap map.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final PickedLocation? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(-6.7924, 39.2083);

  final MapController _mapController = MapController();
  late PickedLocation _selected;
  bool _locating = false;
  LocationFailure? _failure;

  @override
  void initState() {
    super.initState();
    final point = widget.initial?.point ?? _defaultCenter;
    _selected = widget.initial ?? PickedLocation(point: point, label: _coordinateLabel(point));
  }

  static String _coordinateLabel(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

  void _selectPoint(LatLng point) {
    setState(() {
      _selected = PickedLocation(point: point, label: _coordinateLabel(point));
      _failure = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _failure = null;
    });
    try {
      final location = await LocationService.detectCurrent();
      if (!mounted) return;
      setState(() => _selected = location);
      _mapController.move(location.point, 16);
    } on LocationFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } catch (_) {
      if (mounted) {
        setState(() => _failure = const LocationFailure('Imeshindikana kupata eneo lako. Jaribu tena.'));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chagua eneo', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected.point,
              initialZoom: widget.initial == null ? 12 : 16,
              onTap: (_, point) => _selectPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tz.nyumbamkononi.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected.point,
                    width: 54,
                    height: 54,
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.location_pin, color: AppTheme.coral, size: 48),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'current-location',
              onPressed: _locating ? null : _useCurrentLocation,
              tooltip: 'Tumia eneo nilipo',
              child: _locating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Gusa ramani kuweka alama kwenye nyumba.', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_selected.label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      if (failure != null) ...[
                        const SizedBox(height: 8),
                        Text(failure.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        if (failure.action != LocationFailureAction.none)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => LocationService.openSettings(failure.action),
                              child: const Text('Fungua mipangilio'),
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context, _selected),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Tumia eneo hili'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
