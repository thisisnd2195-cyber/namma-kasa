import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/core/session.dart';
import 'src/core/theme.dart';
import 'src/role_chooser.dart';

void main() {
  runApp(const ProviderScope(child: NammaKasaApp()));
}

class NammaKasaApp extends ConsumerWidget {
  const NammaKasaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // The resident's stored choice wins over the device setting, so someone
      // on an English phone who picked Kannada gets a Kannada app — and the
      // same value drives the server's push copy (FR-RES-06).
      locale: ref.watch(localeProvider),
      onGenerateTitle: (context) => L10n.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      home: const RoleChooserScreen(),
    );
  }
}
