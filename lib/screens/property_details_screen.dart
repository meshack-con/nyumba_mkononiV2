import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/property.dart';
import '../models/property_contact.dart';
import '../models/property_type.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, required this.property});
  final Property property;
  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _photo = 0;

  bool _showContact = false;
  bool _loadingContact = false;
  PropertyContact? _contact;
  String? _contactError;

  bool _showMap = false;
  bool _loadingMap = false;
  String? _mapError;
  LatLng? _userPoint;
  double? _distanceKm;
  List<LatLng> _routePoints = [];

  Future<void> _toggleContact() async {
    if (_showContact) {
      setState(() => _showContact = false);
      return;
    }
    if (!await ensureAuthenticated(context, asSeller: false) || !mounted) return;
    setState(() {
      _loadingContact = true;
      _contactError = null;
    });
    try {
      final contact = await ApiClient.instance.getPropertyContact(widget.property.id);
      if (!mounted) return;
      setState(() {
        _contact = contact;
        _showContact = true;
        _loadingContact = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contactError = 'Imeshindwa kupata taarifa za mmiliki';
        _loadingContact = false;
      });
    }
  }

  Future<void> _openChat() async {
    if (!await ensureAuthenticated(context, asSeller: false) || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          propertyId: widget.property.id,
          otherUserId: widget.property.ownerId,
          otherUserName: _contact?.ownerName ?? widget.property.name,
        ),
      ),
    );
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return false;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    return true;
  }

  Future<void> _toggleMap() async {
    if (_showMap) {
      setState(() => _showMap = false);
      return;
    }
    setState(() {
      _loadingMap = true;
      _mapError = null;
    });
    try {
      final allowed = await _ensureLocationPermission();
      if (!allowed) {
        setState(() {
          _mapError = 'Ruhusa ya eneo (GPS) haikuruhusiwa. Iwashe kwenye mipangilio ya simu.';
          _loadingMap = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final user = LatLng(position.latitude, position.longitude);
      final target = LatLng(widget.property.latitude, widget.property.longitude);
      final distance = const Distance().as(LengthUnit.Kilometer, user, target);

      List<LatLng> route = [];
      try {
        final uri = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${user.longitude},${user.latitude};${target.longitude},${target.latitude}'
          '?overview=full&geometries=geojson',
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final routes = data['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final geometry = routes.first['geometry'] as Map<String, dynamic>;
            final coords = geometry['coordinates'] as List<dynamic>;
            route = coords
                .map((c) => LatLng((c as List<dynamic>)[1] as double, (c[0] as num).toDouble()))
                .toList();
          }
        }
      } catch (_) {
        // Route ni ziada tu; tukikosa bado tunaonyesha umbali na alama mbili.
      }

      if (!mounted) return;
      setState(() {
        _userPoint = user;
        _distanceKm = distance;
        _routePoints = route;
        _showMap = true;
        _loadingMap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mapError = 'Imeshindwa kupata eneo lako. Hakikisha GPS iko wazi.';
        _loadingMap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 850;

    return Scaffold(
      appBar: AppBar(title: const Text('Maelezo ya nyumba', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(children: [
        SizedBox(
          height: isWide ? 420 : 300,
          child: Stack(children: [
            PageView.builder(
              itemCount: property.photoUrls.length,
              onPageChanged: (value) => setState(() => _photo = value),
              itemBuilder: (_, index) => Image.network(
                ApiClient.instance.assetUrl(property.photoUrls[index]),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: AppTheme.sand, child: Icon(Icons.home_work_outlined, size: 60)),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(20)),
                child: Text('${_photo + 1} / ${property.photoUrls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(property.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.muted),
              const SizedBox(width: 5),
              Expanded(child: Text(property.locationLabel, style: const TextStyle(color: AppTheme.muted))),
            ]),
            const SizedBox(height: 18),
            Text(property.formattedPrice, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.coral, fontWeight: FontWeight.w900)),
            Text(property.mode == 'rent' ? 'Kwa kukodisha' : 'Kwa kuuza', style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 22),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(label: Text(PropertyTypes.label(property.type))),
              Chip(label: Text(property.hasWifi ? 'Wi-Fi ipo' : 'Hakuna Wi-Fi'), avatar: Icon(property.hasWifi ? Icons.wifi : Icons.wifi_off, size: 17)),
            ]),
            const SizedBox(height: 22),
            Text('Kuhusu nyumba hii', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(property.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: AppTheme.muted)),
            const SizedBox(height: 26),

            // --- Eneo la nyumba: ramani, umbali, na njia bora ---
            OutlinedButton.icon(
              onPressed: _loadingMap ? null : _toggleMap,
              icon: _loadingMap
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_showMap ? Icons.expand_less_rounded : Icons.map_outlined),
              label: Text(_showMap ? 'Ficha eneo' : 'Angalia eneo la nyumba'),
            ),
            if (_mapError != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_mapError!, style: const TextStyle(color: Colors.red))),
            if (_showMap && _userPoint != null) ...[
              const SizedBox(height: 14),
              if (_distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.mint, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.social_distance_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Umbali kutoka ulipo: ${_distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(property.latitude, property.longitude),
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'tz.nyumbamkononi.app'),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 4, color: AppTheme.primary)]),
                      MarkerLayer(markers: [
                        Marker(point: LatLng(property.latitude, property.longitude), width: 44, height: 44, child: Icon(Icons.home, color: AppTheme.coral, size: 36)),
                        Marker(point: _userPoint!, width: 40, height: 40, child: const Icon(Icons.my_location, color: Colors.blue, size: 30)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 26),

            // --- Mmiliki na mawasiliano ---
            Text('Mmiliki wa nyumba', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (_contactError != null) Text(_contactError!, style: const TextStyle(color: Colors.red)),
            if (!_showContact)
              OutlinedButton.icon(
                onPressed: _loadingContact ? null : _toggleContact,
                icon: _loadingContact
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_outline_rounded),
                label: const Text('Ona jina na mawasiliano ya mmiliki'),
              )
            else if (_contact != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.person_rounded, size: 18, color: AppTheme.muted),
                  const SizedBox(width: 8),
                  Text(_contact!.ownerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.phone_rounded, size: 18, color: AppTheme.muted),
                  const SizedBox(width: 8),
                  Text(_contact!.ownerPhone),
                ]),
                if (_contact!.ownerEmail != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.email_outlined, size: 18, color: AppTheme.muted),
                    const SizedBox(width: 8),
                    Text(_contact!.ownerEmail!),
                  ]),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: _openChat, icon: const Icon(Icons.chat_bubble_outline_rounded), label: const Text('Tuma ujumbe')),
              ]),
          ]),
        ),
      ]),
        ),
      ),
    );
  }
}
