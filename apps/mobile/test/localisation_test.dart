import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_kasa/main.dart';
import 'package:namma_kasa/src/core/session.dart';
import 'package:namma_kasa/l10n/app_localizations.dart';
import 'package:namma_kasa/src/driver/oem_steps.dart';
import 'package:namma_kasa/src/resident/proximity.dart';

/// FR-RES-06 is not satisfied by having translations — it is satisfied by the
/// resident-facing strings actually resolving through them. These tests read
/// the Kannada bundle directly, so a screen that hardcodes English will not
/// make them pass, but a missing translation will fail them.
Future<L10n> _load(WidgetTester tester, String languageCode) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: const SizedBox.shrink(),
    ),
  );
  await tester.pumpAndSettle();
  return L10n.of(tester.element(find.byType(SizedBox)));
}

void main() {
  _localeWiring();

  testWidgets('every resident-facing string has Kannada copy', (tester) async {
    final kn = await _load(tester, 'kn');
    final en = await _load(tester, 'en');

    // Each of these is on a screen a resident reaches: registration, the
    // home card, the alert settings sheet, and the complaint form.
    final pairs = <String, (String, String)>{
      'residentSignIn': (en.residentSignIn, kn.residentSignIn),
      'yourName': (en.yourName, kn.yourName),
      'address': (en.address, kn.address),
      'landmarkOptional': (en.landmarkOptional, kn.landmarkOptional),
      'setPassword': (en.setPassword, kn.setPassword),
      'consentText': (en.consentText, kn.consentText),
      'dragPin': (en.dragPin, kn.dragPin),
      'finish': (en.finish, kn.finish),
      'alertMeWhen': (en.alertMeWhen, kn.alertMeWhen),
      'alertRadiusHelp': (en.alertRadiusHelp, kn.alertRadiusHelp),
      'save': (en.save, kn.save),
      'whatWentWrong': (en.whatWentWrong, kn.whatWentWrong),
      'anythingElse': (en.anythingElse, kn.anythingElse),
      'yourComplaints': (en.yourComplaints, kn.yourComplaints),
      'rateToday': (en.rateToday, kn.rateToday),
      'thanksForRating': (en.thanksForRating, kn.thanksForRating),
      'missedTodayBanner': (en.missedTodayBanner, kn.missedTodayBanner),
      'missedComplaintPrefill': (en.missedComplaintPrefill, kn.missedComplaintPrefill),
      'todayLabel': (en.todayLabel, kn.todayLabel),
      'atYourStreet': (en.atYourStreet, kn.atYourStreet),
      'reportProblem': (en.reportProblem, kn.reportProblem),
      'language': (en.language, kn.language),
    };

    for (final entry in pairs.entries) {
      final (english, kannada) = entry.value;
      expect(kannada, isNotEmpty, reason: '${entry.key} has no Kannada copy');
      // A key left untranslated falls back to the English string.
      expect(
        kannada,
        isNot(equals(english)),
        reason: '${entry.key} is still English in the Kannada bundle',
      );
    }
  });

  testWidgets('the distance label is localised, not just the near case', (tester) async {
    final kn = await _load(tester, 'kn');
    final en = await _load(tester, 'en');

    // This regressed once: atYourStreet went through l10n while the metres and
    // kilometres branches returned hardcoded English.
    expect(distanceLabel(10, kn), isNot(contains('street')));
    expect(distanceLabel(300, kn), isNot(equals(distanceLabel(300, en))));
    expect(distanceLabel(1500, kn), isNot(equals(distanceLabel(1500, en))));
  });

  group('OEM tracking guidance (FR-DRV-04)', () {
    test('gives Xiaomi its own Autostart step rather than generic wording', () {
      final guidance = oemGuidanceFor('Xiaomi');
      expect(guidance.brand, contains('Xiaomi'));
      expect(guidance.steps.join(' ').toLowerCase(), contains('autostart'));
    });

    test('matches case-insensitively and on sub-brands', () {
      expect(oemGuidanceFor('realme').brand, 'realme');
      expect(oemGuidanceFor('OPPO').brand, 'OPPO');
      expect(oemGuidanceFor('Xiaomi-Redmi').steps, oemGuidanceFor('xiaomi').steps);
    });

    test('falls back to generic Android wording for an unknown make', () {
      final guidance = oemGuidanceFor('SomePhoneCo');
      expect(guidance.brand, 'Android');
      expect(guidance.steps, isNotEmpty);
    });

    test('never returns an empty step list, whatever it is given', () {
      for (final input in [null, '', '   ', 'nokia', 'samsung']) {
        expect(oemGuidanceFor(input).steps, isNotEmpty, reason: 'input: $input');
      }
    });
  });
}

/// T101's actual claim: the stored preference reaches MaterialApp. A translated
/// bundle is worthless if the app never selects it.
void _localeWiring() {
  testWidgets('the chosen locale overrides the device locale', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(localeOverrideProvider.notifier).state = 'kn';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NammaKasaApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('kn'));
  });

  testWidgets('no choice means follow the device', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NammaKasaApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Null is what tells MaterialApp to resolve against the system locale.
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).locale, isNull);
  });
}
