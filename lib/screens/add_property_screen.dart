import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/listing_payment.dart';
import '../models/property_type.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_field.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _stepFormKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _area = TextEditingController();
  final _landSize = TextEditingController();

  String _type = PropertyTypes.nyumba;
  String _mode = 'rent';
  int _currentStep = 0;
  bool _loading = false;
  bool _processing = false;
  String _processingMessage = 'Subiri, inachakata...';
  String? _error;
  bool _wifi = false;
  bool _carParking = false;
  bool _indoorToilet = false;
  bool _hasElectricity = false;
  bool _waterInside = false;
  bool _waterNearby = false;
  bool _furnished = false;
  bool _swimmingPool = false;

  final List<Uint8List?> _photos = [null, null, null];
  final List<String?> _photoNames = [null, null, null];
  Uint8List? _document;
  String? _documentName;
  PickedLocation? _location;

  ListingPayment? _payment;
  bool _paymentBusy = false;
  String? _paymentError;

  bool get _photosComplete => _photos.every((photo) => photo != null);
  bool get _isLand => _type == PropertyTypes.kiwanja;
  bool get _isRoom => _type == PropertyTypes.chumba;

  String get _priceHint {
    switch (_type) {
      case PropertyTypes.chumba:
        return 'Bei ya chumba kwa mwezi';
      case PropertyTypes.kiwanja:
        return 'Bei ya kiwanja';
      default:
        return 'Bei ya nyumba';
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _price, _description, _area, _landSize]) {
      controller.dispose();
    }
    super.dispose();
  }

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _document = result.files.single.bytes;
      _documentName = result.files.single.name;
    });
  }

  Future<void> _pickLocation() async {
    try {
      final location = await LocationService.detectCurrent();
      if (!mounted) return;
      setState(() {
        _location = location;
        _area.text = location.label;
      });
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

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
            const Text('Weka namba ya simu (M-Pesa / Tigo Pesa / Airtel Money / Halo Pesa) utakayotumia kulipia ada ya kutangaza mali.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Namba ya simu',
                prefixIcon: Icon(Icons.phone_android_outlined),
                hintText: '07XXXXXXXX',
              ),
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
    setState(() {
      _paymentBusy = true;
      _paymentError = null;
    });
    try {
      final payment = await ApiClient.instance.initiateListingFeePayment(phoneNumber: phone);
      setState(() => _payment = payment);
      final link = payment.redirectLink;
      if (link != null && link.isNotEmpty) {
        final uri = Uri.tryParse(link);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
              // Mtandao huenda umekatika – mtumiaji anaweza kujaribu tena.
            } finally {
              setDialogState(() => _paymentBusy = false);
            }
          }

          return AlertDialog(
            title: const Text('Thibitisha malipo'),
            content: Text(
              _paymentBusy
                  ? 'Tunaangalia hali ya malipo yako...'
                  : 'Baada ya kukamilisha malipo ya TZS 5,000 kwenye ukurasa ulioufungua, bonyeza "Nimeshalipa" kuthibitisha.',
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

  bool _canContinueFromStepOne() {
    if (_type.isEmpty) return false;
    return true;
  }

  void _moveToNextStep() {
    if (_currentStep == 0) {
      if (!_canContinueFromStepOne()) {
        setState(() => _error = 'Chagua aina ya mali ili kuendelea.');
        return;
      }
      setState(() {
        _error = null;
        _currentStep = 1;
      });
      return;
    }
    if (_currentStep == 1) {
      if (!(_stepFormKey.currentState?.validate() ?? false)) return;
      setState(() {
        _error = null;
        _currentStep = 2;
      });
      return;
    }
  }

  Future<void> _submit() async {
    if (!_stepFormKey.currentState!.validate()) return;
    if (!_photosComplete || _document == null || _location == null) {
      setState(() => _error = 'Ongeza picha tatu, hati ya umiliki, na eneo kwenye ramani.');
      return;
    }
    if (_payment == null || !_payment!.isSuccessful) {
      setState(() => _error = 'Lipa TZS 5,000 kwanza kabla ya kutuma tangazo.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
      _processingMessage = 'Subiri, inachakata...';
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _processingMessage = 'Bado kidogo...');

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _processingMessage = 'Inamaliza...');

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _loading = true);

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
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Imeshindikana kutuma tangazo.');
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              color: AppTheme.sand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _processingMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tafadhali subiri kidogo.', style: TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weka mali mpya', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _stepFormKey,
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chagua aina ya mali', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Chagua moja ya aina hizi, kisha uweke taarifa zenye hatua kwa hatua.', style: TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 20),
          _typeCard(
            value: PropertyTypes.nyumba,
            title: 'Nyumba',
            subtitle: 'Kibanda, nyumba ya kukaa, au nyumba ya biashara',
            icon: Icons.home_rounded,
          ),
          const SizedBox(height: 12),
          _typeCard(
            value: PropertyTypes.chumba,
            title: 'Chumba',
            subtitle: 'Kikazi, chumba cha kukodisha kwa mwezi',
            icon: Icons.bed_rounded,
          ),
          const SizedBox(height: 12),
          _typeCard(
            value: PropertyTypes.kiwanja,
            title: 'Kiwanja',
            subtitle: 'Kiwanja, ploti, au ardhi kwa kuwekeza',
            icon: Icons.landscape_rounded,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canContinueFromStepOne() ? _moveToNextStep : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Hifadhi na endelea'),
            ),
          ),
        ],
      );
    }

    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Taarifa za ${PropertyTypes.label(_type)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Jaza sehemu ya msingi, kisha uhifadhi ili uende kwenye hatua inayofuata.', style: TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            validator: _required,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _isLand ? 'Jina la kiwanja' : 'Jina la mali',
              prefixIcon: const Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mode,
            decoration: const InputDecoration(labelText: 'Hali'),
            items: const [
              DropdownMenuItem(value: 'rent', child: Text('Kukodisha')),
              DropdownMenuItem(value: 'sale', child: Text('Kuuza')),
            ],
            onChanged: (value) => setState(() => _mode = value ?? 'rent'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _price,
            validator: _required,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _priceHint,
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          if (_isLand) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _landSize,
              validator: _required,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(
                labelText: 'Ukubwa wa kiwanja (mita za mraba)',
                prefixIcon: Icon(Icons.straighten_rounded),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            validator: _required,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Maelezo ya mali',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _moveToNextStep,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Hifadhi na endelea'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kamilisha tangazo', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Ongeza picha, eneo na uthibitisho ili kukamilisha tangazo lako.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 20),
        _section('Picha za mali', _photosComplete ? 'Picha 3/3 zimechaguliwa' : '${_photos.where((p) => p != null).length}/3 picha zimechaguliwa'),
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
                              padding: const EdgeInsets.all(4),
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
        const SizedBox(height: 18),
        _section('Eneo', _area.text.isEmpty ? 'Chagua eneo la mali' : _area.text),
        LocationField(
          value: _location,
          onChanged: (location) => setState(() {
            _location = location;
            _area.text = location.label;
          }),
        ),
        const SizedBox(height: 18),
        _section('Uthibitisho wa umiliki', _documentName ?? 'Hati inahitajika'),
        OutlinedButton.icon(
          onPressed: _pickDocument,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_documentName ?? 'Pakia hati'),
        ),
        const SizedBox(height: 18),
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
                      : 'Malipo ya tangazo ni TZS 5,000 kupitia Flutterwave. Hii ni hatua ya mwisho kabla ya kutuma tangazo.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_paymentError != null) ...[
          Text(_paymentError!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
        ],
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
        ],
        if (_payment == null || !_payment!.isSuccessful)
          OutlinedButton.icon(
            onPressed: _paymentBusy ? null : _startPaymentFlow,
            icon: _paymentBusy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.payments_outlined),
            label: Text(_payment != null && _payment!.isPending ? 'Thibitisha / jaribu malipo tena' : 'Lipa TZS 5,000 kuendelea'),
          )
        else
          const SizedBox.shrink(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Tuma tangazo'),
          ),
        ),
      ],
    );
  }

  Widget _typeCard({required String value, required String title, required String subtitle, required IconData icon}) {
    final selected = _type == value;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _type = value;
          _error = null;
        });
        if (_currentStep == 0) {
          _moveToNextStep();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.muted.withOpacity(0.4), width: selected ? 2 : 1),
          color: selected ? AppTheme.sand : Colors.white,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.sand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

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
