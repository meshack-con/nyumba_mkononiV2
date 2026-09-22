import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/listing_payment.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _area = TextEditingController();

  String _type = 'apartment';
  String _mode = 'rent';

  bool _wifi = false;
  bool _carParking = false;
  bool _indoorToilet = false;
  bool _hasElectricity = false;
  bool _waterInside = false;
  bool _waterNearby = false;
  bool _furnished = false;
  bool _swimmingPool = false;

  // Kila slot inashikilia picha moja: index 0, 1, 2
  final List<Uint8List?> _photos = [null, null, null];
  final List<String?> _photoNames = [null, null, null];

  Uint8List? _document;
  String? _documentName;

  PickedLocation? _location;

  bool _loading = false;
  String? _error;

  // --- Malipo ya ada ya kutangaza nyumba (TZS 5,000 - ClickPesa USSD-PUSH) -
  ListingPayment? _payment;
  bool _paymentBusy = false;
  String? _paymentError;

  @override
  void dispose() {
    for (final controller in [_name, _price, _description, _area]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _photosComplete => _photos.every((photo) => photo != null);

  Future<void> _pickSinglePhoto(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _photos[index] = result.files.single.bytes;
      _photoNames[index] = result.files.single.name;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos[index] = null;
      _photoNames[index] = null;
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    if (result == null || result.files.single.bytes == null) return;
    setState(() { _document = result.files.single.bytes; _documentName = result.files.single.name; });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedLocation>(context, MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)));
    if (result != null) setState(() { _location = result; _area.text = result.label; });
  }

  // --- Hatua 1: mpangishaji analipa TZS 5,000 kwa ClickPesa (USSD-PUSH) --
  Future<String?> _askForPaymentPhone() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lipa TZS 5,000'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weka namba ya simu (M-Pesa / Tigo Pesa / Airtel Money / Halo Pesa) utakayotumia kulipia ada ya kutangaza nyumba.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Namba ya simu', prefixIcon: Icon(Icons.phone_android_outlined), hintText: '07XXXXXXXX'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().length < 7) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('Endelea kulipa'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPaymentFlow() async {
    final phone = await _askForPaymentPhone();
    if (phone == null) return;
    setState(() { _paymentBusy = true; _paymentError = null; });
    try {
      final payment = await ApiClient.instance.initiateListingFeePayment(phoneNumber: phone);
      setState(() => _payment = payment);
      // ClickPesa imeshatuma ombi la USSD moja kwa moja kwenye simu ya
      // muuzaji (channel: M-Pesa/Tigo Pesa/Airtel Money/Halopesa) - hapa
      // HATUFUNGUI browser (tofauti na Flutterwave iliyokuwepo kabla).
      // Hatua ya mwisho (kuweka PIN kuidhinisha) inafanyika NJE ya app,
      // moja kwa moja kwenye simu ya muuzaji.
      if (mounted) await _confirmPaymentDialog();
    } on ApiException catch (error) {
      setState(() => _paymentError = error.message);
    } catch (_) {
      setState(() => _paymentError = 'Imeshindikana kuanzisha malipo. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _paymentBusy = false);
    }
  }

  Future<void> _confirmPaymentDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> checkNow() async {
            setDialogState(() => _paymentBusy = true);
            try {
              final updated = await ApiClient.instance.getListingFeePaymentStatus(_payment!.txRef);
              setState(() => _payment = updated);
              if (updated.isSuccessful || updated.isFailed) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            } catch (_) {
              // Mtandao huenda umekatika - mtumiaji anaweza kujaribu tena.
            } finally {
              setDialogState(() => _paymentBusy = false);
            }
          }

          final channel = _payment?.channel;
          return AlertDialog(
            title: const Text('Thibitisha malipo'),
            content: Text(
              _paymentBusy
                  ? 'Tunaangalia hali ya malipo yako...'
                  : 'Angalia simu yako${channel != null ? ' ya $channel' : ''} - utaona ombi la kuweka PIN ili kuidhinisha malipo ya TZS 5,000. '
                      'Ukishaweka PIN, bonyeza "Nimeshalipa" hapa kuthibitisha.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Nitathibitisha baadaye')),
              ElevatedButton(
                onPressed: _paymentBusy ? null : checkNow,
                child: const Text('Nimeshalipa'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Hatua 2: tuma tangazo (baada ya malipo kufanikiwa) ----------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_photosComplete || _document == null || _location == null) {
      setState(() => _error = 'Ongeza picha 3, hati ya umiliki na eneo kwenye ramani.');
      return;
    }
    if (_payment == null || !_payment!.isSuccessful) {
      setState(() => _error = 'Lipa TZS 5,000 kwanza kabla ya kutuma tangazo.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final photoBytes = _photos.map((photo) => photo!).toList();
      final photoNames = _photoNames.map((name) => name!).toList();

      await ApiClient.instance.createProperty(
        paymentRef: _payment!.txRef,
        name: _name.text.trim(),
        type: _type,
        mode: _mode,
        price: int.parse(_price.text.trim()),
        locationLabel: _area.text.trim(),
        latitude: _location!.point.latitude,
        longitude: _location!.point.longitude,
        hasWifi: _wifi,
        carParking: _carParking,
        indoorToilet: _indoorToilet,
        hasElectricity: _hasElectricity,
        waterInside: _waterInside,
        waterNearby: _waterNearby,
        furnished: _furnished,
        swimmingPool: _swimmingPool,
        description: _description.text.trim(),
        photos: photoBytes,
        photoNames: photoNames,
        verificationDoc: _document!,
        verificationDocName: _documentName!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tangazo limetumwa. Litapitiwa ndani ya masaa 24.')));
        Navigator.pop(context);
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Imeshindikana kutuma tangazo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Weka nyumba mpya', style: TextStyle(fontWeight: FontWeight.w800))),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              Text('Tangazo lako litapitiwa ndani ya masaa 24.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.muted)),
              const SizedBox(height: 20),
              _section('Picha za nyumba', _photosComplete ? 'Picha 3/3 zimechaguliwa' : '${_photos.where((p) => p != null).length}/3 picha zimechaguliwa'),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    ..._photos.asMap().entries.where((entry) => entry.value != null).map((entry) {
                      final index = entry.key;
                      final photo = entry.value!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(photo, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_photos.any((photo) => photo == null))
                      GestureDetector(
                        onTap: () {
                          final nextEmptyIndex = _photos.indexWhere((photo) => photo == null);
                          if (nextEmptyIndex != -1) _pickSinglePhoto(nextEmptyIndex);
                        },
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.sand,
                              border: Border.all(color: AppTheme.muted.withOpacity(0.3)),
                            ),
                            child: const Center(child: Icon(Icons.add_photo_alternate_outlined, color: AppTheme.muted, size: 28)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _section('Taarifa za msingi', 'Eleza nyumba yako kwa uwazi'),
              TextFormField(controller: _name, validator: _required, decoration: const InputDecoration(labelText: 'Jina la nyumba', prefixIcon: Icon(Icons.home_work_outlined))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Aina'),
                    items: const [
                      DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                      DropdownMenuItem(value: 'nyumba', child: Text('Nyumba')),
                      DropdownMenuItem(value: 'studio', child: Text('Studio')),
                      DropdownMenuItem(value: 'villa', child: Text('Villa')),
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
              _section('Eneo', 'Chagua alama kwenye ramani'),
              TextFormField(
                controller: _area,
                readOnly: true,
                validator: _required,
                onTap: _pickLocation,
                decoration: InputDecoration(
                  labelText: 'Eneo la nyumba',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: IconButton(onPressed: _pickLocation, icon: const Icon(Icons.map_outlined)),
                ),
              ),
              const SizedBox(height: 22),
              _section('Uthibitisho wa umiliki', _documentName ?? 'Hati inahitajika'),
              OutlinedButton.icon(onPressed: _pickDocument, icon: const Icon(Icons.upload_file_outlined), label: Text(_documentName ?? 'Pakia hati')),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_payment?.isSuccessful == true ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: _payment?.isSuccessful == true ? Colors.green : null),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _payment?.isSuccessful == true
                            ? 'Malipo ya TZS 5,000 yamekamilika. Sasa unaweza kutuma tangazo.'
                            : 'Malipo ya tangazo ni TZS 5,000 (kupitia ClickPesa - M-Pesa/Tigo Pesa/Airtel Money/Halopesa). Tangazo litapitiwa ndani ya masaa 24 baada ya kutumwa.',
                      ),
                    ),
                  ],
                ),
              ),
              if (_paymentError != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_paymentError!, style: const TextStyle(color: Colors.red))),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 20),
              if (_payment == null || !_payment!.isSuccessful) ...[
                OutlinedButton.icon(
                  onPressed: _paymentBusy ? null : _startPaymentFlow,
                  icon: _paymentBusy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.payments_outlined),
                  label: Text(_payment != null && _payment!.isPending ? 'Thibitisha / jaribu malipo tena' : 'Lipa TZS 5,000 kuendelea'),
                ),
                const SizedBox(height: 10),
                const ElevatedButton(onPressed: null, child: Text('Tuma tangazo — lipa kwanza')),
              ] else
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Tuma tangazo'),
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
