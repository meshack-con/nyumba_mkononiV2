import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

Future<bool> ensureAuthenticated(BuildContext context, {required bool asSeller}) async {
  final token = await ApiClient.instance.getToken();
  if (token != null && token.isNotEmpty) return true;
  if (!context.mounted) return false;
  final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AuthScreen(lockRole: asSeller)));
  return result == true;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.lockRole});
  final bool? lockRole;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _email = TextEditingController();
  final _area = TextEditingController();
  bool _registering = false;
  bool _seller = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  // --- Eneo: kutafuta kiotomatiki kwa GPS (badala ya kuandika) ----------
  Timer? _locationTimer;
  int _locationMsgIndex = 0;
  bool _detectingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _seller = widget.lockRole ?? false;
  }

  @override
  void dispose() {
    for (final controller in [_fullName, _phone, _username, _password, _confirmPassword, _email, _area]) controller.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  /// Njia kuu ya kuweka eneo: bonyeza kitufe kimoja, GPS ya simu inatafuta
  /// eneo kiotomatiki - hakuna kuandika kwa mkono kunakohitajika.
  Future<void> _autoDetectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
      _locationMsgIndex = 0;
    });
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() => _locationMsgIndex = (_locationMsgIndex + 1) % AppStrings.locationProgressMessages.length);
    });
    try {
      final result = await LocationService.detectCurrent();
      _locationTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _area.text = result.label;
        _detectingLocation = false;
      });
    } on LocationFailure catch (failure) {
      _locationTimer?.cancel();
      if (!mounted) return;
      setState(() { _detectingLocation = false; _locationError = failure.message; });
    } catch (_) {
      _locationTimer?.cancel();
      if (!mounted) return;
      setState(() { _detectingLocation = false; _locationError = AppStrings.t('locationFetchFailed'); });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_registering) {
        await ApiClient.instance.register(fullName: _fullName.text.trim(), phone: _phone.text.trim(), username: _username.text.trim(), password: _password.text, role: _seller ? 'seller' : 'buyer', email: _email.text.trim(), area: _area.text.trim());
      } else {
        await ApiClient.instance.login(username: _username.text.trim(), password: _password.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = AppStrings.t('serverConnectFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context, false))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                shadowColor: AppTheme.primary.withAlpha(28),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _registering ? AppStrings.t('registerTitle') : AppStrings.t('loginTitle'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _registering
                              ? AppStrings.t('registerSubtitle')
                              : AppStrings.t('loginSubtitle'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(value: false, label: Text(AppStrings.t('loginTab'))),
                            ButtonSegment(value: true, label: Text(AppStrings.t('registerTab'))),
                          ],
                          selected: {_registering},
                          onSelectionChanged: (value) =>
                              setState(() => _registering = value.first),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_registering) ...[
                        _field(_fullName, AppStrings.t('fullNameLabel'), Icons.badge_outlined),
                        const SizedBox(height: 12),
                        _field(_phone, AppStrings.t('phoneLabel'), Icons.phone_outlined, keyboard: TextInputType.phone),
                        const SizedBox(height: 12),
                      ],
                      _field(_username, AppStrings.t('usernameLabel'), Icons.alternate_email_rounded),
                      const SizedBox(height: 12),
                      _passwordField(
                        _password,
                        AppStrings.t('passwordFieldLabel'),
                        _obscurePassword,
                        () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      if (_registering) ...[
                        const SizedBox(height: 12),
                        _passwordField(
                          _confirmPassword,
                          AppStrings.t('confirmPasswordLabel'),
                          _obscureConfirmPassword,
                          () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return AppStrings.t('confirmPasswordRequired');
                            if (value != _password.text) return AppStrings.t('passwordMismatch');
                            return null;
                          },
                        ),
                      ],
                      if (_registering && _seller) ...[
                        const SizedBox(height: 12),
                        _field(_email, AppStrings.t('emailLabel'), Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _areaField(),
                      ],
                      if (_registering && widget.lockRole == null) ...[
                        const SizedBox(height: 18),
                        Text(AppStrings.t('yourRoleLabel'), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<bool>(initialValue: _seller, decoration: const InputDecoration(prefixIcon: Icon(Icons.people_outline)), items: [DropdownMenuItem(value: false, child: Text(AppStrings.t('buyerRoleTitle'))), DropdownMenuItem(value: true, child: Text(AppStrings.t('sellerRoleTitle')))], onChanged: (value) => setState(() => _seller = value ?? false)),
                      ],
                      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: _registering ? 124 : 96,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_registering ? AppStrings.t('registerTab') : AppStrings.t('loginTab')),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType? keyboard}) => TextFormField(controller: controller, obscureText: obscure, keyboardType: keyboard, validator: (value) => value == null || value.trim().isEmpty ? AppStrings.tParams('fillField', {'label': label}) : null, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)));

  /// Sehemu ya password - ina kiicon cha jicho ambacho mtumiaji anaweza
  /// kugusa ili kuonyesha/kuficha password aliyoingiza.
  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggleObscure, {
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator ?? (value) => value == null || value.trim().isEmpty ? AppStrings.tParams('fillField', {'label': label}) : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: toggleObscure,
          ),
        ),
      );

  /// Eneo halijazwi kwa kuandika - mtumiaji anabonyeza "Weka eneo" na GPS
  /// ya simu inalijaza kiotomatiki (sawa na jinsi eneo la nyumba linavyowekwa
  /// kwenye fomu ya "Weka nyumba").
  Widget _areaField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _area,
            readOnly: true,
            validator: (value) => value == null || value.trim().isEmpty ? AppStrings.t('areaRequiredMsg') : null,
            decoration: InputDecoration(
              labelText: AppStrings.t('locationSection'),
              hintText: AppStrings.t('areaFieldHint'),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _detectingLocation ? null : _autoDetectLocation,
            icon: _detectingLocation
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded),
            label: Text(_area.text.isEmpty ? AppStrings.t('setLocation') : AppStrings.t('detectLocationAgain')),
          ),
          if (_detectingLocation) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.locationProgressMessages[_locationMsgIndex],
              style: const TextStyle(color: AppTheme.muted, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(_locationError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      );
}
