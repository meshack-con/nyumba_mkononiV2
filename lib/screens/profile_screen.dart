import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signedIn = false;
  AppUser? _user;
  bool _appearanceExpanded = false;
  bool _primaryColorExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await ApiClient.instance.getToken();
    final signedIn = token?.isNotEmpty == true;
    if (mounted) setState(() => _signedIn = signedIn);
    if (!signedIn) {
      if (mounted) setState(() => _user = null);
      return;
    }
    try {
      final user = await ApiClient.instance.getMe();
      await ThemeController.instance.loadForUser(user.id);
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // Ikiwa imeshindwa kupakia (mfano token imeisha), UI inabaki
      // katika hali ya "Mgeni" bila kuvunjika.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 28, 20, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 58,
            backgroundColor: AppTheme.primary,
            backgroundImage: _user?.profilePichaUrl != null ? NetworkImage(_user!.profilePichaUrl!) : null,
            child: _user?.profilePichaUrl == null
                ? Text(
                    _signedIn && _user != null && _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'MK',
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            _signedIn ? (_user?.fullName ?? s('member')) : s('guest'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _signedIn ? s('accountReady') : s('signInPrompt'),
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppTheme.darkSuccess : AppTheme.success),
          ),
        ),
        const SizedBox(height: 32),
        _SectionLabel(s('account')),
        _ProfileTile(icon: Icons.person_outline_rounded, title: s('personalInfo'), onTap: _openPersonalInfo),
        _ProfileTile(icon: Icons.notifications_none_rounded, title: s('notifications'), onTap: _openNotifications),
        _ProfileTile(
          icon: Icons.language_rounded,
          title: s('language'),
          subtitle: LocaleController.instance.currentName,
          onTap: _chooseLanguage,
        ),
        _ProfileTile(
          icon: Icons.logout_rounded,
          title: _signedIn ? s('signOut') : s('signIn'),
          danger: _signedIn,
          onTap: _signedIn ? _signOut : _openAuth,
        ),
        const SizedBox(height: 24),
        _SectionLabel(s('feedbackSection')),
        _ProfileTile(
          icon: Icons.feedback_outlined,
          title: s('feedback'),
          subtitle: s('feedbackSubtitle'),
          onTap: _openFeedback,
        ),
        const SizedBox(height: 24),
        _ExpandableSection(
          title: s('appearance'),
          expanded: _appearanceExpanded,
          onTap: () {
            _toggleAppearance();
          },
          child: const _ThemeSelector(),
        ),
        const SizedBox(height: 8),
        _ExpandableSection(
          title: s('primaryColor'),
          expanded: _primaryColorExpanded,
          onTap: () {
            _togglePrimaryColor();
          },
          child: const _AccentSelector(),
        ),
      ],
    );
  }

  Future<void> _openPersonalInfo() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
    _loadSession();
  }

  Future<void> _openNotifications() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  Future<void> _openAuth() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    await _loadSession();
  }

  Future<void> _signOut() async {
    await ApiClient.instance.clearSession();
    await ThemeController.instance.loadForUser(null);
    if (mounted) {
      setState(() {
        _signedIn = false;
        _user = null;
      });
    }
  }

  Future<void> _toggleAppearance() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    if (mounted) setState(() => _appearanceExpanded = !_appearanceExpanded);
  }

  Future<void> _togglePrimaryColor() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    if (mounted) setState(() => _primaryColorExpanded = !_primaryColorExpanded);
  }

  Future<void> _chooseLanguage() async {
    final controller = LocaleController.instance;
    final code = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.t('chooseLanguage'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            for (final option in LocaleController.languages)
              ListTile(
                title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: option.code == controller.code
                    ? Icon(Icons.check_rounded, color: Theme.of(sheetContext).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option.code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (code != null) await controller.setLanguage(code);
  }

  Future<void> _openFeedback() async {
    if (!_signedIn) {
      await _openAuth();
      if (!_signedIn) return;
    }
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FeedbackSheet(),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('feedbackThanks'))),
      );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({required this.title, required this.expanded, required this.onTap, required this.child});
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
          ),
          if (expanded) child,
        ],
      );
}

/// Kichwa "Theme" chenye vitufe vya White / Dark ndani yake.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.surfaceContainerLow,
                  foregroundColor: scheme.onSurface,
                  child: const Icon(Icons.brightness_6_outlined),
                ),
                const SizedBox(width: 16),
                Text(
                  AppStrings.t('theme'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppTheme.primary,
                  selectedForegroundColor: Colors.white,
                ),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(AppStrings.t('white')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(AppStrings.t('dark')),
                  ),
                ],
                selected: {controller.mode},
                onSelectionChanged: (selection) => controller.setMode(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSelector extends StatelessWidget {
  const _AccentSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (final option in ThemeController.accents)
              _AccentDot(
                option: option,
                selected: option.id == controller.accent.id,
                onTap: () => controller.setAccent(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.option, required this.selected, required this.onTap});
  final AccentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: option.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 70,
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: option.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? onSurface : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
              ),
              const SizedBox(height: 6),
              Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerColor = isDark ? Colors.red.shade300 : Colors.red;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: danger ? dangerColor.withAlpha(30) : scheme.surfaceContainerLow,
        foregroundColor: danger ? dangerColor : scheme.onSurface,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppStrings.t('feedbackEmpty'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await FeedbackService.send(text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = AppStrings.t('feedbackFailed');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('feedbackTitle'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !_sending,
            minLines: 4,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: AppStrings.t('feedbackHint'),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(AppStrings.t('feedbackSend')),
          ),
        ],
      ),
    );
  }
}
