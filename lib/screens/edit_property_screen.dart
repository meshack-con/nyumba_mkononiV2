import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/property.dart';
import '../models/property_type.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_field.dart';

/// Skrini ya kuhariri tangazo la nyumba ambalo mwenye tangazo (seller)
/// ameshaliweka kwenye mfumo. Picha na hati ya uthibitisho HAZIBADILISHWI
/// hapa - ni za kudumu tangu kuunda tangazo (zinaendana na PATCH
/// /properties/{id} upande wa backend).
class EditPropertyScreen extends StatefulWidget {
  const EditPropertyScreen({super.key, required this.property});
  final Property property;
  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late String _type;
  late String _mode;
  late bool _wifi;
  late bool _carParking;
  late bool _indoorToilet;
  late bool _hasElectricity;
  late bool _waterInside;
  late bool _waterNearby;
  late bool _furnished;
  late bool _swimmingPool;
  late PickedLocation _location;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _name = TextEditingController(text: p.name);
    _price = TextEditingController(text: '${p.price}');
    _description = TextEditingController(text: p.description);
    _type = PropertyTypes.normalize(p.type);
    _mode = p.mode;
    _wifi = p.hasWifi;
    _carParking = p.carParking;
    _indoorToilet = p.indoorToilet;
    _hasElectricity = p.hasElectricity;
    _waterInside = p.waterInside;
    _waterNearby = p.waterNearby;
    _furnished = p.furnished;
    _swimmingPool = p.swimmingPool;
    _location = PickedLocation(point: LatLng(p.latitude, p.longitude), label: p.locationLabel);
  }

  @override
  void dispose() {
    for (final controller in [_name, _price, _description]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.updateProperty(
        id: widget.property.id,
        name: _name.text.trim(),
        type: _type,
        mode: _mode,
        price: int.parse(_price.text.trim()),
        locationLabel: _location.label,
        latitude: _location.point.latitude,
        longitude: _location.point.longitude,
        hasWifi: _wifi,
        carParking: _carParking,
        indoorToilet: _indoorToilet,
        hasElectricity: _hasElectricity,
        waterInside: _waterInside,
        waterNearby: _waterNearby,
        furnished: _furnished,
        swimmingPool: _swimmingPool,
        description: _description.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tangazo limehaririwa.')));
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Imeshindikana kuhariri tangazo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hariri tangazo', style: TextStyle(fontWeight: FontWeight.w800))),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              _section('Taarifa za msingi', 'Eleza nyumba yako kwa uwazi'),
              TextFormField(controller: _name, validator: _required, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Jina la mtaa / kata', hintText: 'Mfano: Sinza, Mikocheni', prefixIcon: Icon(Icons.location_city_outlined))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Aina'),
                    items: const [
                      DropdownMenuItem(value: PropertyTypes.chumba, child: Text('Chumba')),
                      DropdownMenuItem(value: PropertyTypes.nyumba, child: Text('Nyumba')),
                      DropdownMenuItem(value: PropertyTypes.kiwanja, child: Text('Kiwanja')),
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _mode,
                    decoration: const InputDecoration(labelText: 'Hali'),
                    items: const [
                      DropdownMenuItem(value: 'rent', child: Text('Kukodisha')),
                      DropdownMenuItem(value: 'sale', child: Text('Kuuza')),
                    ],
                    onChanged: (value) => setState(() => _mode = value!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _price, validator: _required, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bei kwa TZS', prefixIcon: Icon(Icons.payments_outlined))),
              const SizedBox(height: 12),
              TextFormField(controller: _description, validator: _required, minLines: 4, maxLines: 6, decoration: const InputDecoration(labelText: 'Maelezo ya nyumba', alignLabelWithHint: true)),
              const SizedBox(height: 10),
              _section('Huduma zilizopo', 'Chagua zote zinazopatikana'),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.wifi_rounded), title: const Text('Wi-Fi ipo'), value: _wifi, onChanged: (value) => setState(() => _wifi = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.local_parking_rounded), title: const Text('Sehemu ya kuegesha gari'), value: _carParking, onChanged: (value) => setState(() => _carParking = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.wc_rounded), title: const Text('Choo cha ndani'), value: _indoorToilet, onChanged: (value) => setState(() => _indoorToilet = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.bolt_rounded), title: const Text('Umeme upo'), value: _hasElectricity, onChanged: (value) => setState(() => _hasElectricity = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.water_drop_rounded), title: const Text('Maji ndani ya nyumba'), value: _waterInside, onChanged: (value) => setState(() => _waterInside = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.water_drop_outlined), title: const Text('Maji karibu na nyumba'), value: _waterNearby, onChanged: (value) => setState(() => _waterNearby = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.chair_rounded), title: const Text('Ina samani (furnished)'), value: _furnished, onChanged: (value) => setState(() => _furnished = value)),
              SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.pool_rounded), title: const Text('Ina swimming pool'), value: _swimmingPool, onChanged: (value) => setState(() => _swimmingPool = value)),
              const SizedBox(height: 10),
              _section('Eneo', 'Ruhusu GPS ya simu yako'),
              LocationField(value: _location, onChanged: (location) => setState(() => _location = location)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded),
                    SizedBox(width: 10),
                    Expanded(child: Text('Picha na hati ya umiliki haziwezi kubadilishwa hapa. Wasiliana na msaada ikiwa unahitaji kuzibadilisha.')),
                  ],
                ),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Hifadhi mabadiliko'),
              ),
            ],
          ),
        ),
      );

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Sehemu hii inahitajika' : null;
  Widget _section(String title, String caption) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Flexible(child: Text(caption, textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
          ],
        ),
      );
}
