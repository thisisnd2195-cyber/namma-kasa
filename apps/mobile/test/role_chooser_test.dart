import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_kasa/l10n/app_localizations.dart';
import 'package:namma_kasa/main.dart';
import 'package:namma_kasa/src/core/theme.dart';

void main() {
  testWidgets('entry screen offers both roles', (tester) async {
    await tester.pumpWidget(const NammaKasaApp());
    expect(find.text('Login as Resident'), findsOneWidget);
    expect(find.text('Login as Driver'), findsOneWidget);
  });

  testWidgets('Kannada locale renders Kannada copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('kn'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SizedBox));
    expect(L10n.of(context).appTitle, 'ನಮ್ಮ ಕಸ');
  });

  test('driver scale meets the glove-friendly floor (FR-DRV-02)', () {
    final driver = applyDriverScale(buildLightTheme());
    expect(driver.textTheme.bodyMedium!.fontSize, greaterThanOrEqualTo(16));
    expect(
      driver.filledButtonTheme.style!.minimumSize!
          .resolve({})!.height,
      Tokens.driverTouchTarget,
    );
  });
}
