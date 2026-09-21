import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Kitufe cha "Weka eneo": kinaomba ruhusa ya GPS ya simu na kujaza eneo la
/// nyumba kiotomatiki (bila kuchagua kwenye ramani).
class LocationField extends StatefulWidget {
  const LocationField({super.key, required this.value, required this.onChanged});

  final PickedLocation? value;
  final ValueChanged<PickedLocation> onChanged;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  bool _loading = false;
  LocationFailure? _failure;

  Future<void> _detect() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final location = await LocationService.detectCurrent();
      if (!mounted) return;
      widget.onChanged(location);
    } on LocationFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } catch (_) {
      if (mounted) setState(() => _failure = const LocationFailure('Imeshindikana kupata eneo lako. Jaribu tena.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppTheme.darkSuccess : AppTheme.success;
    final value = widget.value;
    final failure = _failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _detect,
          icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location_rounded),
          label: Text(_loading ? 'Inatafuta eneo...' : 'Weka eneo'),
        ),
        if (value != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: success),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Eneo la nyumba limewekwa',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (failure != null) ...[
          const SizedBox(height: 10),
          Text(failure.message, style: TextStyle(color: scheme.error)),
          if (failure.action != LocationFailureAction.none)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => LocationService.openSettings(failure.action),
                child: const Text('Fungua mipangilio'),
              ),
            ),
        ],
      ],
    );
  }
}
