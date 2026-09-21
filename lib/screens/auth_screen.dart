import 'package:flutter/material.dart';

import '../services/api_client.dart';
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
  final _email = TextEditingController();
  final _area = TextEditingController();
  bool _registering = false;
  bool _seller = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seller = widget.lockRole ?? false;
  }

  @override
  void dispose() {
    for (final controller in [_fullName, _phone, _username, _password, _email, _area]) controller.dispose();
    super.dispose();
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
      setState(() => _error = 'Imeshindikana kuwasiliana na server.');
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
                          _registering ? 'Fungua akaunti' : 'Karibu tena',
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
                              ? 'Taarifa zako zitatusaidia kukupa uzoefu bora.'
                              : 'Ingia ili uendelee na hatua yako.',
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
                          segments: const [
                            ButtonSegment(value: false, label: Text('Ingia')),
                            ButtonSegment(value: true, label: Text('Jisajili')),
                          ],
                          selected: {_registering},
                          onSelectionChanged: (value) =>
                              setState(() => _registering = value.first),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_registering) ...[
                        _field(_fullName, 'Jina kamili', Icons.badge_outlined),
                        const SizedBox(height: 12),
                        _field(_phone, 'Namba ya simu', Icons.phone_outlined, keyboard: TextInputType.phone),
                        const SizedBox(height: 12),
                      ],
                      _field(_username, 'Username', Icons.alternate_email_rounded),
                      const SizedBox(height: 12),
                      _field(_password, 'Password', Icons.lock_outline_rounded, obscure: true),
                      if (_registering && _seller) ...[
                        const SizedBox(height: 12),
                        _field(_email, 'Barua pepe', Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _field(_area, 'Eneo', Icons.location_on_outlined),
                      ],
                      if (_registering && widget.lockRole == null) ...[
                        const SizedBox(height: 18),
                        Text('Jukumu lako', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<bool>(initialValue: _seller, decoration: const InputDecoration(prefixIcon: Icon(Icons.people_outline)), items: const [DropdownMenuItem(value: false, child: Text('Mpangaji au Mnunuzi')), DropdownMenuItem(value: true, child: Text('Muuzaji au Mpangishaji'))], onChanged: (value) => setState(() => _seller = value ?? false)),
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
                                : Text(_registering ? 'Jisajili' : 'Ingia'),
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

  Widget _field(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType? keyboard}) => TextFormField(controller: controller, obscureText: obscure, keyboardType: keyboard, validator: (value) => value == null || value.trim().isEmpty ? 'Jaza $label' : null, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)));
}
