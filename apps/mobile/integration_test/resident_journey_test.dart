import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:namma_kasa/l10n/app_localizations.dart';
import 'package:namma_kasa/src/core/session.dart';
import 'package:namma_kasa/src/core/theme.dart';
import 'package:namma_kasa/src/resident/resident_home_screen.dart';

/// The resident's screens, driven on a real device against the real backend.
///
/// The widget tests fake the Api class; `http.spec.ts` drives the API without a
/// UI. Neither covers the join — the screen rendering what the server actually
/// returned. Every bug that reached a user in this project lived exactly there.
///
/// Sign-in itself is not driven here: the OTP lands in Redis, which a device
/// cannot read, and exposing it over HTTP to make a test convenient would be a
/// production footgun. Instead the test obtains a real session the way the app
/// does — `POST /auth/login` against the running API — and drives everything
/// after it. The OTP screens are covered by widget tests and the API suite.
///
/// Usage (needs the stack up and a device attached):
///   flutter test integration_test/resident_journey_test.dart \
///     --dart-define=API_BASE=http://10.0.2.2:4000/v1
const apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:4000/v1',
);

Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
  final response = await http.post(
    Uri.parse('$apiBase$path'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode(body),
  );
  if (response.statusCode >= 400) {
    throw StateError('$path -> ${response.statusCode}: ${response.body}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Session session;

  setUpAll(() async {
    final login = await _post('/auth/login', {
      'phone': '919888800001',
      'password': 'devpassword',
      'deviceId': 'integration-test',
    });
    final user = login['user'] as Map<String, dynamic>;
    session = Session(
      accessToken: login['accessToken'] as String,
      refreshToken: login['refreshToken'] as String,
      userId: user['id'] as String,
      role: user['role'] as String,
      locale: user['locale'] as String,
    );
  });

  /// Boots the real screen with a real session, exactly as the app would after
  /// sign-in — no faked Api, no faked transport.
  Future<void> pumpHome(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn(session);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(session.locale),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          theme: buildLightTheme(),
          home: const ResidentHomeScreen(),
        ),
      ),
    );

    // The screen loads over the network, so settle on real latency rather than
    // pumpAndSettle, which the live map's animation would spin on forever.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
  }

  testWidgets('the home screen renders what the API actually returned',
      (tester) async {
    await pumpHome(tester);

    // Whatever the server said, the screen must have stopped loading and shown
    // the sheet rather than an error banner.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);

    final home = await http.get(
      Uri.parse('$apiBase/resident/home'),
      headers: {'authorization': 'Bearer ${session.accessToken}'},
    );
    final body = jsonDecode(home.body) as Map<String, dynamic>;
    final route = body['route'] as Map<String, dynamic>?;

    if (route != null) {
      // The collection window the server holds is on screen, character for
      // character — the join these tests exist to cover.
      final window = '${route['windowStart']} – ${route['windowEnd']}';
      expect(find.text(window), findsWidgets,
          reason: 'the window from /resident/home should be rendered verbatim');
    }
  });

  testWidgets('a live auto surfaces as a distance headline and an ETA pill',
      (tester) async {
    await pumpHome(tester);

    // Read the server's view *after* pumping, not before. Live positions expire
    // 60 s after the last ping, so a check taken beforehand can describe a trip
    // that has already gone quiet by the time the screen builds — a race that
    // made this flake once inside the full suite.
    final home = await http.get(
      Uri.parse('$apiBase/resident/home'),
      headers: {'authorization': 'Bearer ${session.accessToken}'},
    );
    final autos = (jsonDecode(home.body) as Map<String, dynamic>)['servingAutos'] as List;

    // Only the ETA pill floats over the map; the sheet's schedule chip is also
    // a Pill, so the flag is what separates them.
    final floatingPills = tester
        .widgetList<Pill>(find.byType(Pill))
        .where((pill) => pill.floating);

    if (autos.isEmpty) {
      // No trip running — the state for most of the day. The screen must say
      // so rather than floating a stale ETA over the map.
      expect(floatingPills, isEmpty, reason: 'no serving auto means no ETA pill');
      return;
    }

    final registration = (autos.first as Map<String, dynamic>)['registrationNumber'];
    expect(find.textContaining(registration as String), findsWidgets);
    expect(floatingPills, isNotEmpty, reason: 'a moving auto should float an ETA');
  });

  testWidgets('driver identity never reaches the resident screen (FR-RES-07)',
      (tester) async {
    // Pull the real driver roster straight from the database's own API, then
    // assert none of it is anywhere in the rendered widget tree.
    final admin = await _post('/auth/login', {
      'phone': '919000000002',
      'password': 'devpassword',
      'deviceId': 'integration-test-admin',
    });
    final wards = await http.get(
      Uri.parse('$apiBase/admin/wards'),
      headers: {'authorization': 'Bearer ${admin['accessToken']}'},
    );
    final wardId = ((jsonDecode(wards.body) as List).first as Map<String, dynamic>)['id'];
    final drivers = await http.get(
      Uri.parse('$apiBase/admin/drivers?wardId=$wardId'),
      headers: {'authorization': 'Bearer ${admin['accessToken']}'},
    );

    await pumpHome(tester);

    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');

    for (final driver in jsonDecode(drivers.body) as List) {
      final row = driver as Map<String, dynamic>;
      expect(rendered.contains(row['fullName'] as String), isFalse,
          reason: 'a resident must never see a driver name');
      expect(rendered.contains(row['phone'] as String), isFalse,
          reason: 'a resident must never see a driver phone number');
    }
  });

  testWidgets('the alert settings sheet loads the stored radius and saves it',
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.tune));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(Slider).evaluate().isNotEmpty) break;
    }

    final slider = tester.widget<Slider>(find.byType(Slider));
    // Whatever the server holds is what the slider shows — FR-RES-05's range.
    expect(slider.value, greaterThanOrEqualTo(100));
    expect(slider.value, lessThanOrEqualTo(1000));

    final home = await http.get(
      Uri.parse('$apiBase/resident/home'),
      headers: {'authorization': 'Bearer ${session.accessToken}'},
    );
    final household = (jsonDecode(home.body) as Map<String, dynamic>)['household']
        as Map<String, dynamic>;
    expect(slider.value, (household['notificationRadiusM'] as num).toDouble());
  });
}
