import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../core/api.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

/// Three big buttons and an optional note (FR-DRV-07).
///
/// A driver reaching for this has usually just broken down at the side of a
/// road, so it asks for one tap and nothing else. The note is there for the
/// cases where it helps and is never required.
class DriverIssueSheet extends ConsumerStatefulWidget {
  const DriverIssueSheet({super.key});

  @override
  ConsumerState<DriverIssueSheet> createState() => _DriverIssueSheetState();
}

class _DriverIssueSheetState extends ConsumerState<DriverIssueSheet> {
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _report(String kind) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).reportIssue(kind, note: _note.text.trim().isEmpty ? null : _note.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
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
          Text(l10n.reportIssue, style: theme.textTheme.titleMedium),
          const SizedBox(height: Tokens.space3),
          for (final option in [
            (kind: 'breakdown', label: l10n.issueBreakdown),
            (kind: 'road_blocked', label: l10n.issueRoadBlocked),
            (kind: 'other', label: l10n.issueOther),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.space2),
              child: FilledButton.tonal(
                // Glove-friendly, same as the trip controls (FR-DRV-02).
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: _busy ? null : () => _report(option.kind),
                child: Text(option.label, style: theme.textTheme.titleMedium),
              ),
            ),
          const SizedBox(height: Tokens.space2),
          TextField(
            controller: _note,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: '${l10n.issueOther} (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Tokens.error)),
        ],
      ),
    );
  }
}
