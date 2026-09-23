import 'dart:async';
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

  // --- Malipo ya ada ya kutangaza nyumba (TZS 10,000 - ClickPesa USSD-PUSH) -
  ListingPayment? _payment;
  bool _paymentBusy = false;
  String? _paymentError;

  // --- Mpangilio wa hatua kwa hatua (wizard) - sehemu moja kwa wakati ------
  static const _stepTitles = [
    'Picha za nyumba',
    'Taarifa za msingi',
    'Maelezo',
    'Huduma zilizopo',
    'Eneo',
    'Uthibitisho wa umiliki',
    'Malipo na kutuma',
  ];
  int get _totalSteps => _stepTitles.length;
  int _step = 0;
  String? _stepError;

  // --- Eneo: kutafuta kiotomatiki kwa GPS -----------------------------
  static const _locationProgressMessages = [
    'Inaendelea...',
    'Inachakata eneo lako...',
    'Bado kidogo...',
  ];
  Timer? _locationTimer;
  int _locationMsgIndex = 0;
  bool _detectingLocation = false;
  String? _locationError;

  @override
  void dispose() {
    for (final controller in [_name, _price, _description, _area]) {
      controller.dispose();
    }
    _locationTimer?.cancel();
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

  /// Eneo kwa ramani (njia mbadala) - mtumiaji akitaka kuchagua alama
  /// mwenyewe badala ya GPS ya kiotomatiki.
  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push<PickedLocation>(context, MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)));
    if (result != null) {
      setState(() { _location = result; _area.text = result.label; _locationError = null; });
    }
  }

  /// Njia kuu ya kuweka eneo: bonyeza kitufe kimoja, GPS ya simu
  /// inatafuta eneo kiotomatiki (hakuna ramani ya kuchagua mwenyewe
  /// inayohitajika). Wakati inatafuta, maneno ya maendeleo yanabadilika
  /// ili mtumiaji ajue mchakato unaendelea.
  Future<void> _autoDetectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
      _locationMsgIndex = 0;
    });
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() => _locationMsgIndex = (_locationMsgIndex + 1) % _locationProgressMessages.length);
    });
    try {
      final result = await LocationService.detectCurrent();
      _locationTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _location = result;
        _area.text = result.label;
        _detectingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eneo limepatikana!'), duration: Duration(seconds: 2)),
      );
    } on LocationFailure catch (failure) {
      _locationTimer?.cancel();
      if (!mounted) return;
      setState(() { _detectingLocation = false; _locationError = failure.message; });
    } catch (_) {
      _locationTimer?.cancel();
      if (!mounted) return;
      setState(() { _detectingLocation = false; _locationError = 'Imeshindikana kupata eneo lako. Jaribu tena.'; });
    }
  }

  // --- Hatua 1: mpangishaji analipa TZS 10,000 kwa ClickPesa (USSD-PUSH) --
  Future<String?> _askForPaymentPhone() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lipa TZS 10,000'),
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
                  : 'Angalia simu yako${channel != null ? ' ya $channel' : ''} - utaona ombi la kuweka PIN ili kuidhinisha malipo ya TZS 10,000. '
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

  // --- Uthibitishaji wa kila hatua kabla ya "Endelea" ---------------------
  String? _validateStep(int step) {
    switch (step) {
      case 0:
        return _photosComplete ? null : 'Weka picha 3 za nyumba kabla ya kuendelea.';
      case 1:
        if (_name.text.trim().isEmpty) return 'Jaza jina la nyumba.';
        if (_price.text.trim().isEmpty) return 'Jaza bei ya nyumba.';
        if (int.tryParse(_price.text.trim()) == null) return 'Bei lazima iwe namba.';
        return null;
      case 2:
        return _description.text.trim().isEmpty ? 'Andika maelezo ya nyumba.' : null;
      case 3:
        return null; // huduma ni hiari
      case 4:
        return _location == null ? 'Bonyeza "Weka eneo" kupata eneo la nyumba.' : null;
      case 5:
        return _document == null ? 'Pakia hati ya umiliki.' : null;
      default:
        return null;
    }
  }

  void _goNext() {
    final error = _validateStep(_step);
    if (error != null) {
      setState(() => _stepError = error);
      return;
    }
    setState(() {
      _stepError = null;
      if (_step < _totalSteps - 1) _step++;
    });
  }

  void _goBack() {
    setState(() {
      _stepError = null;
      if (_step > 0) _step--;
    });
  }

  // --- Hatua ya mwisho: tuma tangazo (baada ya malipo kufanikiwa) --------
  Future<void> _submit() async {
    for (var i = 0; i < _totalSteps - 1; i++) {
      final error = _validateStep(i);
      if (error != null) {
        setState(() { _step = i; _stepError = error; });
        return;
      }
    }
    if (_payment == null || !_payment!.isSuccessful) {
      setState(() => _error = 'Lipa TZS 10,000 kwanza kabla ya kutuma tangazo.');
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

  // Fomu hii inaonyeshwa kama "card" ya modal inayopanda kutoka chini
  // (bottom sheet) badala ya ukurasa mzima - ndiyo maana hakuna Scaffold/
  // AppBar hapa; badala yake tunajenga kadi yenye pembe za mviringo juu,
  // "drag handle", na kichwa chenye kitufe cha kufunga (X).
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          height: screenHeight * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 42, height: 5, decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(3))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Weka nyumba mpya', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: _stepHeader(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      if (_stepError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                            child: Text(_stepError!, style: const TextStyle(color: Colors.red)),
                          ),
                        ),
                      _buildStepContent(_step),
                    ],
                  ),
                ),
                _bottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hatua ${_step + 1} ya $_totalSteps', style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(_stepTitles[_step], style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_step + 1) / _totalSteps,
              minHeight: 6,
              backgroundColor: AppTheme.sand,
            ),
          ),
          const SizedBox(height: 18),
        ],
      );

  Widget _bottomNav() {
    if (_step == _totalSteps - 1) return const SizedBox.shrink(); // hatua ya mwisho ina vitufe vyake
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(child: OutlinedButton(onPressed: _goBack, child: const Text('Rudi nyuma'))),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(onPressed: _goNext, child: const Text('Endelea')),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _photosStep();
      case 1:
        return _basicInfoStep();
      case 2:
        return _descriptionStep();
      case 3:
        return _amenitiesStep();
      case 4:
        return _locationStep();
      case 5:
        return _documentStep();
      default:
        return _paymentAndSubmitStep();
    }
  }

  // --- Hatua 0: Picha za nyumba --------------------------------------
  Widget _photosStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Picha za nyumba', _photosComplete ? 'Picha 3/3 zimechaguliwa' : '${_photos.where((p) => p != null).length}/3 picha zimechaguliwa'),
          const Text('Weka picha 3 zinazoonyesha nyumba yako vizuri.', style: TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
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
        ],
      );

  // --- Hatua 1: Taarifa za msingi -------------------------------------
  Widget _basicInfoStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Taarifa za msingi', 'Eleza nyumba yako kwa uwazi'),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Jina la nyumba', prefixIcon: Icon(Icons.home_work_outlined))),
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
          TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bei kwa TZS', prefixIcon: Icon(Icons.payments_outlined))),
        ],
      );

  // --- Hatua 2: Maelezo -------------------------------------------------
  Widget _descriptionStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Maelezo ya nyumba', 'Toa maelezo kamili'),
          TextField(controller: _description, minLines: 6, maxLines: 10, decoration: const InputDecoration(alignLabelWithHint: true, hintText: 'Mfano: Nyumba ya vyumba 2, jikoni la kisasa, karibu na barabara kuu...')),
        ],
      );

  // --- Hatua 3: Huduma zilizopo -----------------------------------------
  Widget _amenitiesStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Huduma zilizopo', 'Chagua zote zinazopatikana'),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.wifi_rounded), title: const Text('Wi-Fi ipo'), value: _wifi, onChanged: (value) => setState(() => _wifi = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.local_parking_rounded), title: const Text('Sehemu ya kuegesha gari'), value: _carParking, onChanged: (value) => setState(() => _carParking = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.wc_rounded), title: const Text('Choo cha ndani'), value: _indoorToilet, onChanged: (value) => setState(() => _indoorToilet = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.bolt_rounded), title: const Text('Umeme upo'), value: _hasElectricity, onChanged: (value) => setState(() => _hasElectricity = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.water_drop_rounded), title: const Text('Maji ndani ya nyumba'), value: _waterInside, onChanged: (value) => setState(() => _waterInside = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.water_drop_outlined), title: const Text('Maji karibu na nyumba'), value: _waterNearby, onChanged: (value) => setState(() => _waterNearby = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.chair_rounded), title: const Text('Ina samani (furnished)'), value: _furnished, onChanged: (value) => setState(() => _furnished = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.pool_rounded), title: const Text('Ina swimming pool'), value: _swimmingPool, onChanged: (value) => setState(() => _swimmingPool = value)),
        ],
      );

  // --- Hatua 4: Eneo - kitufe kimoja, GPS inatafuta kiotomatiki --------
  Widget _locationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Eneo', 'Bonyeza kitufe, tutatafuta eneo lako'),
          if (_location != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_area.text, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _detectingLocation ? null : _autoDetectLocation,
                  icon: _detectingLocation
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location_rounded),
                  label: Text(_location == null ? 'Weka eneo' : 'Tafuta eneo tena'),
                ),
                if (_detectingLocation) ...[
                  const SizedBox(height: 12),
                  Text(
                    _locationProgressMessages[_locationMsgIndex],
                    style: const TextStyle(color: AppTheme.muted, fontStyle: FontStyle.italic),
                  ),
                ],
                if (_locationError != null) ...[
                  const SizedBox(height: 12),
                  Text(_locationError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _detectingLocation ? null : _pickLocationOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Chagua kwenye ramani badala yake'),
                ),
              ],
            ),
          ),
        ],
      );

  // --- Hatua 5: Uthibitisho wa umiliki -----------------------------------
  Widget _documentStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Uthibitisho wa umiliki', _documentName ?? 'Hati inahitajika'),
          OutlinedButton.icon(onPressed: _pickDocument, icon: const Icon(Icons.upload_file_outlined), label: Text(_documentName ?? 'Pakia hati')),
        ],
      );

  // --- Hatua 6: Malipo na kutuma tangazo ---------------------------------
  Widget _paymentAndSubmitStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Malipo na kutuma', 'Hatua ya mwisho'),
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
                        ? 'Malipo ya TZS 10,000 yamekamilika. Sasa unaweza kutuma tangazo.'
                        : 'Malipo ya tangazo ni TZS 10,000 (kupitia ClickPesa - M-Pesa/Tigo Pesa/Airtel Money/Halopesa). Tangazo litapitiwa ndani ya masaa 24 baada ya kutumwa.',
                  ),
                ),
              ],
            ),
          ),
          if (_paymentError != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_paymentError!, style: const TextStyle(color: Colors.red))),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _goBack, child: const Text('Rudi nyuma'))),
            ],
          ),
          const SizedBox(height: 10),
          if (_payment == null || !_payment!.isSuccessful) ...[
            OutlinedButton.icon(
              onPressed: _paymentBusy ? null : _startPaymentFlow,
              icon: _paymentBusy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.payments_outlined),
              label: Text(_payment != null && _payment!.isPending ? 'Thibitisha / jaribu malipo tena' : 'Lipa TZS 10,000 kuendelea'),
            ),
            const SizedBox(height: 10),
            const ElevatedButton(onPressed: null, child: Text('Tuma tangazo — lipa kwanza')),
          ] else
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Tuma tangazo'),
            ),
        ],
      );

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
