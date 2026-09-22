import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Screen ya kuchagua eneo la nyumba kwa kubonyeza (tap) kwenye ramani.
/// Inarudisha [PickedLocation] kupitia Navigator.pop wakati mtumiaji
/// akishathibitisha eneo lake.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// Eneo la awali (likiwepo) — mfano wakati wa ku-edit tangazo.
  final PickedLocation? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(-6.7924, 39.2083); // Dar es Salaam

  final MapController _mapController = MapController();

  late LatLng _point;
  String? _label;
  bool _resolvingLabel = false;
  bool _detectingGps = false;

  @override
  void initState() {
    super.initState();
    _point = widget.initial?.point ?? _defaultCenter;
    _label = widget.initial?.label;
  }

  Future<void> _onTap(LatLng point) async {
    setState(() {
      _point = point;
      _label = null;
    });
    await _resolveLabel(point);
  }

  Future<void> _resolveLabel(LatLng point) async {
    setState(() => _resolvingLabel = true);
    final label = await _reverseGeocode(point.latitude, point.longitude);
    if (!mounted) return;
    setState(() {
      _label = label ?? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      _resolvingLabel = false;
    });
  }

  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '16',
        'addressdetails': '1',
        'accept-language': 'sw,en',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final address = body['address'];
      if (address is! Map<String, dynamic>) return null;

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final parts = <String>[];
      final area = pick(['suburb', 'neighbourhood', 'quarter', 'city_district', 'village', 'hamlet']);
      final city = pick(['city', 'town', 'municipality', 'county', 'state']);
      if (area != null) parts.add(area);
      if (city != null && city != area) parts.add(city);
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _detectingGps = true);
    try {
      final location = await LocationService.detectCurrent();
      if (!mounted) return;
      setState(() {
        _point = location.point;
        _label = location.label;
        _detectingGps = false;
      });
      _mapController.move(location.point, 15);
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      setState(() => _detectingGps = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _detectingGps = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kupata eneo lako. Jaribu tena.')),
      );
    }
  }

  void _confirm() {
    final label = _label ?? '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}';
    Navigator.pop(context, PickedLocation(point: _point, label: label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chagua eneo la nyumba', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Tumia eneo langu la sasa',
            onPressed: _detectingGps ? null : _useCurrentLocation,
            icon: _detectingGps
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: widget.initial != null ? 15 : 12,
              onTap: (_, point) => _onTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tz.nyumbamkononi.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _point,
                  width: 44,
                  height: 44,
                  child: Icon(Icons.location_on_rounded, color: AppTheme.coral, size: 40),
                ),
              ]),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Text(
                'Bonyeza mahali popote kwenye ramani kuweka eneo la nyumba',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(Icons.place_outlined, size: 18, color: AppTheme.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _resolvingLabel
                          ? const Text('Inatafuta jina la eneo...')
                          : Text(
                              _label ?? '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _resolvingLabel ? null : _confirm,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Tumia eneo hili'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
