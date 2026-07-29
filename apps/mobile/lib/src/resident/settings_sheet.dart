import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

/// How close the auto gets before the resident is told. Someone on a long
/// street wants more warning than someone whose gate is on the route
/// (FR-RES-05).
class ResidentSettingsSheet extends ConsumerStatefulWidget {
  const ResidentSettingsSheet({super.key});

  @override
  ConsumerState<ResidentSettingsSheet> createState() => _ResidentSettingsSheetState();
}

class _ResidentSettingsSheetState extends ConsumerState<ResidentSettingsSheet> {
  double _radius = 300;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final home = await ref.read(apiProvider).residentHome();
      if (mounted) {
        setState(() {
          _radius = home.household.notificationRadiusM.toDouble();
          _loaded = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).updateSettings(notificationRadiusM: _radius.round());
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: Tokens.space4,
        right: Tokens.space4,
        top: Tokens.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + Tokens.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alert me when the auto is', style: theme.textTheme.titleMedium),
          const SizedBox(height: Tokens.space2),
          if (!_loaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            Semantics(
              liveRegion: true,
              label: 'Alert distance ${_radius.round()} metres',
              child: Text(
                '${_radius.round()} m away',
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            Slider(
              value: _radius,
              min: 100,
              max: 1000,
              divisions: 18,
              label: '${_radius.round()} m',
              onChanged: (value) => setState(() => _radius = value),
            ),
            Text(
              'A longer distance gives you more time; a shorter one means fewer '
              'alerts when the auto is only passing nearby.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.space3),
              child: Text(_error!, style: const TextStyle(color: Tokens.error)),
            ),
          const SizedBox(height: Tokens.space4),
          FilledButton(
            onPressed: _busy || !_loaded ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}
