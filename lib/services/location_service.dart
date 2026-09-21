import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Eneo la nyumba: alama ya GPS pamoja na jina linaloonyeshwa.
class PickedLocation {
  const PickedLocation({required this.point, required this.label});
  final LatLng point;
  final String label;
}

/// Hatua ambayo mtumiaji anaweza kuchukua ili kutatua tatizo la eneo.
enum LocationFailureAction { none, openLocationSettings, openAppSettings }

class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.action = LocationFailureAction.none});
  final String message;
  final LocationFailureAction action;
}

class LocationService {
  const LocationService._();

  /// Inaomba ruhusa ya GPS ya simu, inapata eneo la sasa na kulijaza
  /// kiotomatiki (pamoja na jina la mtaa/eneo likipatikana).
  /// Inatupa [LocationFailure] yenye ujumbe wa Kiswahili ikishindikana.
  static Future<PickedLocation> detectCurrent() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Ruhusa ya eneo imekataliwa. Bonyeza "Weka eneo" tena kisha uchague "Ruhusu".',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        kIsWeb
            ? 'Ruhusa ya eneo imezuiwa. Iruhusu kwenye mipangilio ya browser kisha jaribu tena.'
            : 'Ruhusa ya eneo imezuiwa. Iruhusu kwenye mipangilio ya app kisha jaribu tena.',
        action: kIsWeb ? LocationFailureAction.none : LocationFailureAction.openAppSettings,
      );
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationFailure(
        'GPS ya simu imezimwa. Iwashe kisha bonyeza "Weka eneo" tena.',
        action: kIsWeb ? LocationFailureAction.none : LocationFailureAction.openLocationSettings,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure(
        'Imechukua muda mrefu kupata eneo. Hakikisha GPS imewashwa na uko eneo wazi, kisha jaribu tena.',
      );
    } catch (_) {
      throw const LocationFailure('Imeshindikana kupata eneo lako. Jaribu tena.');
    }

    final label = await _reverseGeocode(position.latitude, position.longitude) ??
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    return PickedLocation(point: LatLng(position.latitude, position.longitude), label: label);
  }

  /// Inabadilisha alama ya GPS kuwa jina la eneo (mfano "Sinza, Dar es Salaam")
  /// kwa kutumia OpenStreetMap Nominatim. Ikishindikana inarudisha null.
  static Future<String?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '16',
        'addressdetails': '1',
        'accept-language': 'sw,en',
      });
      final response = await http
          .get(uri, headers: {if (!kIsWeb) 'User-Agent': 'tz.nyumbamkononi.app'})
          .timeout(const Duration(seconds: 8));
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

  static Future<void> openSettings(LocationFailureAction action) async {
    switch (action) {
      case LocationFailureAction.openLocationSettings:
        await Geolocator.openLocationSettings();
        break;
      case LocationFailureAction.openAppSettings:
        await Geolocator.openAppSettings();
        break;
      case LocationFailureAction.none:
        break;
    }
  }
}
