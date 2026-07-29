import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'core/theme.dart';
import 'driver/driver_auth_screen.dart';
import 'resident/resident_auth_screen.dart';

/// Single binary, two audiences: the entry screen picks the role and every
/// downstream surface is scoped to it (FR-AUTH-01).
enum AppRole { resident, driver }

class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.appTitle,
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tokens.space2),
              Text(
                l10n.roleChooserPrompt,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tokens.space8),
              FilledButton(
                onPressed: () => _open(context, AppRole.resident),
                child: Text(l10n.loginAsResident),
              ),
              const SizedBox(height: Tokens.space3),
              OutlinedButton(
                onPressed: () => _open(context, AppRole.driver),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, Tokens.minTouchTarget),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.loginAsDriver),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, AppRole role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => role == AppRole.driver
            ? const DriverAuthScreen()
            : const ResidentAuthScreen(),
      ),
    );
  }
}
