import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _area = TextEditingController();

  AppUser? _user;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_fullName, _phone, _email, _area]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiClient.instance.getMe();
      _applyUser(user);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Imeshindikana kupakia taarifa zako. Angalia mtandao wako.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyUser(AppUser user) {
    if (!mounted) return;
    setState(() {
      _user = user;
      _fullName.text = user.fullName;
      _phone.text = user.phone;
      _email.text = user.email ?? '';
      _area.text = user.area ?? '';
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final updated = await ApiClient.instance.updateMyPhoto(bytes, result!.files.single.name);
      _applyUser(updated);
      if (mounted) _showMessage('Profile picha imesasishwa.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Imeshindikana kupakia picha. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ApiClient.instance.updateMe(
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        area: _area.text.trim(),
      );
      _applyUser(updated);
      if (mounted) {
        setState(() => _editing = false);
        _showMessage('Taarifa zako zimehifadhiwa.');
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Imeshindikana kuhifadhi taarifa. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _roleLabel(String role) => role == 'seller' ? 'Muuzaji / Mpangishaji' : 'Mnunuzi / Mpangaji';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taarifa binafsi'),
        actions: [
          if (!_loading && _user != null)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_editing) {
                        _save();
                      } else {
                        setState(() => _editing = true);
                      }
                    },
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_editing ? 'Hifadhi' : 'Hariri', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error ?? 'Imeshindikana kupakia taarifa zako.', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Jaribu tena')),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 54,
                                backgroundColor: AppTheme.primary,
                                backgroundImage: _user!.profilePichaUrl != null ? NetworkImage(_user!.profilePichaUrl!) : null,
                                child: _user!.profilePichaUrl == null
                                    ? Text(
                                        _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                    child: _uploadingPhoto
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(child: Text('Gusa ikoni ya kamera kubadilisha profile picha', style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
                        const SizedBox(height: 28),
                        _label('Jina kamili'),
                        _editing ? _field(_fullName, Icons.badge_outlined) : _readOnly(_user!.fullName, Icons.badge_outlined),
                        const SizedBox(height: 16),
                        _label('Namba ya simu'),
                        _editing ? _field(_phone, Icons.phone_outlined, keyboard: TextInputType.phone) : _readOnly(_user!.phone, Icons.phone_outlined),
                        const SizedBox(height: 16),
                        _label('Barua pepe'),
                        _editing
                            ? _field(_email, Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress, required: false)
                            : _readOnly(_user!.email?.isNotEmpty == true ? _user!.email! : 'Hujaweka barua pepe', Icons.mail_outline_rounded),
                        const SizedBox(height: 16),
                        _label('Eneo'),
                        _editing
                            ? _field(_area, Icons.location_on_outlined, required: false)
                            : _readOnly(_user!.area?.isNotEmpty == true ? _user!.area! : 'Hujaweka eneo', Icons.location_on_outlined),
                        const SizedBox(height: 16),
                        _label('Username'),
                        _readOnly(_user!.username, Icons.alternate_email_rounded),
                        const SizedBox(height: 16),
                        _label('Aina ya akaunti'),
                        _readOnly(_roleLabel(_user!.role), Icons.people_outline_rounded),
                        const SizedBox(height: 16),
                        _label('Tarehe ya kujiunga'),
                        _readOnly(_formatDate(_user!.createdAt), Icons.calendar_today_outlined),
                        if (_error != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                        if (_editing) ...[
                          const SizedBox(height: 28),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        _applyUser(_user!);
                                        setState(() => _editing = false);
                                      },
                                child: const Text('Ghairi'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Hifadhi mabadiliko'),
                              ),
                            ),
                          ]),
                        ],
                      ]),
                    ),
                  ),
                ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(text, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _readOnly(String value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: AppTheme.surfaceLow, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _field(TextEditingController controller, IconData icon, {TextInputType? keyboard, bool required = true}) => TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: required ? (value) => value == null || value.trim().isEmpty ? 'Sehemu hii inahitajika' : null : null,
        decoration: InputDecoration(prefixIcon: Icon(icon)),
      );
}
