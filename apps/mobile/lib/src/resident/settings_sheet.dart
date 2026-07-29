import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../../l10n/app_localizations.dart';
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

  /// Persisted server-side as well as locally, because the same value picks
  /// the language of the push notifications (FR-RES-06).
  Future<void> _setLocale(String locale) async {
    try {
      await ref.read(apiProvider).updateSettings(locale: locale);
      await ref.read(sessionProvider.notifier).setLocale(locale);
      ref.read(localeOverrideProvider.notifier).state = locale;
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
    final l10n = L10n.of(context);

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
          Text(l10n.language, style: theme.textTheme.titleMedium),
          const SizedBox(height: Tokens.space2),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
              ButtonSegment(value: 'kn', label: Text(l10n.languageKannada)),
            ],
            selected: {ref.watch(sessionProvider)?.locale ?? 'en'},
            onSelectionChanged: (next) => unawaited(_setLocale(next.first)),
          ),
          const SizedBox(height: Tokens.space4),
          Text(l10n.alertMeWhen, style: theme.textTheme.titleMedium),
          const SizedBox(height: Tokens.space2),
          if (!_loaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            Semantics(
              liveRegion: true,
              label: l10n.alertDistance(_radius.round()),
              child: Text(
                l10n.metresAway(_radius.round()),
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            Slider(
              value: _radius,
              min: 100,
              max: 1000,
              divisions: 18,
              label: l10n.alertDistance(_radius.round()),
              onChanged: (value) => setState(() => _radius = value),
            ),
            Text(
              l10n.alertRadiusHelp,
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
            child: Text(_busy ? l10n.saving : l10n.save),
          ),
        ],
      ),
    );
  }
}
