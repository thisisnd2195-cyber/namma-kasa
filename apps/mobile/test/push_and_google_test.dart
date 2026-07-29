import 'package:flutter_test/flutter_test.dart';
import 'package:namma_kasa/src/core/api.dart';
import 'package:namma_kasa/src/core/google_auth.dart';
import 'package:namma_kasa/src/core/notifications.dart';
import 'package:namma_kasa/src/core/push_messaging.dart';

/// T066 and T074 cannot be finished without a Firebase project and an OAuth
/// client id. What can be finished — and is what these cover — is everything
/// on this side of those credentials: the interfaces, the fallbacks, and the
/// decisions the app makes with what it gets back.
void main() {
  _alertController();

  group('push payload parsing (FR-NOTIF-01)', () {
    test('reads the shape NotifyService actually sends', () {
      // Matches queueProximity: title and body alongside kind and ids.
      final message = PushMessage.fromData({
        'title': 'Auto is ~300 m away',
        'body': 'Today: Wet',
        'kind': 'proximity',
        'routeId': 'r-1',
        'tripId': 't-1',
      });

      expect(message.kind, 'proximity');
      expect(message.title, 'Auto is ~300 m away');
      expect(message.body, 'Today: Wet');
      // title and body are lifted out, not left duplicated in data.
      expect(message.data, {'kind': 'proximity', 'routeId': 'r-1', 'tripId': 't-1'});
    });

    test('survives a payload missing everything it expects', () {
      final message = PushMessage.fromData({});
      expect(message.kind, 'unknown');
      expect(message.title, isEmpty);
      expect(message.body, isEmpty);
    });

    test('drops nulls rather than stringifying them', () {
      final message = PushMessage.fromData({'kind': 'arrival', 'tripId': null});
      expect(message.data.containsKey('tripId'), isFalse);
    });

    test('knows which kinds mean an auto is close', () {
      bool arrival(String kind) =>
          PushMessage.fromData({'kind': kind}).isArrivalRelated;

      expect(arrival('proximity'), isTrue);
      expect(arrival('arrival'), isTrue);
      expect(arrival('complaint_status'), isFalse);
      expect(arrival('schedule_change'), isFalse);
    });
  });

  group('push fallback without Firebase (T066)', () {
    test('reports itself unconfigured and yields no token', () async {
      final push = FakePushMessaging();
      addTearDown(push.dispose);

      expect(push.isConfigured, isFalse);
      // No token means nothing registers server-side, which is correct: the
      // resident must not be told push is on when it cannot be.
      expect(await push.obtainToken(), isNull);
      expect(push.obtainTokenCalls, 1);
    });

    test('still delivers foreground messages so the banner works', () async {
      final push = FakePushMessaging();
      addTearDown(push.dispose);

      final received = <PushMessage>[];
      final sub = push.foregroundMessages.listen(received.add);

      push.emit(const PushMessage(kind: 'proximity', title: 'Close', body: '300 m'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received.single.kind, 'proximity');
    });

    test('reports the push that launched the app, when there was one', () async {
      final push = FakePushMessaging();
      addTearDown(push.dispose);

      expect(await push.initialMessage(), isNull);

      push.setInitialMessage(const PushMessage(kind: 'arrival', title: 'Here', body: ''));
      expect((await push.initialMessage())!.kind, 'arrival');
    });
  });

  group('Google Sign-In seam (T074)', () {
    test('an unconfigured build offers no button', () {
      final auth = FakeGoogleAuthenticator(available: false);
      expect(auth.isConfigured, isFalse);
    });

    test('an unconfigured build refuses rather than faking a session', () async {
      final auth = FakeGoogleAuthenticator(available: false);
      expect(await auth.signIn(), isNull);
      expect(auth.signInCount, 1);
    });

    test('the dev fake returns a token the server will reject, not accept', () async {
      final auth = FakeGoogleAuthenticator(available: true, email: 'a@b.com');
      final token = await auth.signIn();

      expect(token, isNotNull);
      // Proves plumbing, not identity: the backend verifies against Google and
      // will refuse this, which is the honest outcome for a build with no
      // credentials.
      expect(token, contains('fake-google-id-token'));
      expect(token, contains('a@b.com'));
      expect(token!.split('.').length, lessThan(3), reason: 'must not look like a real JWT');
    });

    test('sign-out is wired', () async {
      final auth = FakeGoogleAuthenticator(available: true);
      await auth.signOut();
      expect(auth.signOutCount, 1);
    });

    test('the real implementation is inert until given a client id', () {
      expect(PlatformGoogleAuthenticator('').isConfigured, isFalse);
      expect(PlatformGoogleAuthenticator('abc.apps.googleusercontent.com').isConfigured, isTrue);
    });
  });
}

/// The controller is where the two seams meet the product decision: whether
/// the resident is on push or on the in-app banner, and what they see when a
/// push lands while the app is open.
void _alertController() {
  group('AlertController (FR-NOTIF-01, CHK039)', () {
    late FakeApi api;
    late FakePushMessaging push;
    late AlertController controller;

    setUp(() {
      api = FakeApi();
      push = FakePushMessaging();
      controller = AlertController(api, push);
    });

    tearDown(() async {
      controller.dispose();
      await push.dispose();
    });

    test('falls back to in-app when push is unconfigured, and registers nothing',
        () async {
      final channel = await controller.start();

      expect(channel, AlertChannel.inApp);
      expect(controller.state.channel, AlertChannel.inApp);
      // Registering a token we do not have would leave a dead row server-side.
      expect(api.registeredTokens, isEmpty);
    });

    test('a foreground proximity push becomes the banner', () async {
      push.emit(const PushMessage(
        kind: 'proximity',
        title: 'Auto is ~300 m away',
        body: 'Today: Wet',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.banner, 'Auto is ~300 m away — Today: Wet');
    });

    test('a schedule change is worth interrupting for; a complaint update is not',
        () async {
      push.emit(const PushMessage(
        kind: 'schedule_change',
        title: 'No collection tomorrow',
        body: 'Public holiday',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.banner, isNotNull);

      controller.dismissBanner();
      push.emit(const PushMessage(
        kind: 'complaint_status',
        title: 'Your complaint was resolved',
        body: '',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.banner, isNull);
    });

    test('an empty body does not leave a dangling separator', () async {
      push.emit(const PushMessage(kind: 'arrival', title: 'At your street', body: ''));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.banner, 'At your street');
    });

    test('a failed token registration does not break sign-in', () async {
      api.failRegistration = true;
      // The resident can still watch the live map; the token retries next launch.
      await expectLater(controller.registerToken('tok'), completes);
    });

    test('registers the token and switches to push once Firebase is configured',
        () async {
      final configured = ConfiguredFakePush();
      final live = AlertController(api, configured);
      addTearDown(() async {
        live.dispose();
        await configured.dispose();
      });

      final channel = await live.start();

      expect(channel, AlertChannel.push);
      expect(live.state.channel, AlertChannel.push);
      expect(api.registeredTokens, ['device-token-1']);
    });

    test('acts on the push that launched the app from cold', () async {
      final configured = ConfiguredFakePush()
        ..setInitialMessage(
          const PushMessage(kind: 'arrival', title: 'At your street', body: ''),
        );
      final live = AlertController(api, configured);
      addTearDown(() async {
        live.dispose();
        await configured.dispose();
      });

      await live.start();

      // Tapping a notification must land somewhere that shows it.
      expect(live.state.banner, 'At your street');
    });

    test('stays on the banner when permission is refused', () async {
      final refused = ConfiguredFakePush(token: null);
      final live = AlertController(api, refused);
      addTearDown(() async {
        live.dispose();
        await refused.dispose();
      });

      expect(await live.start(), AlertChannel.inApp);
      expect(api.registeredTokens, isEmpty);
    });

    test('the banner can be dismissed', () async {
      controller.showBanner('anything');
      expect(controller.state.banner, isNotNull);
      controller.dismissBanner();
      expect(controller.state.banner, isNull);
    });
  });
}

/// FakePushMessaging always reports itself unconfigured, which is the state
/// today. This stands in for the day a Firebase project exists, so the
/// success branch is covered before the credential arrives rather than after.
class ConfiguredFakePush extends FakePushMessaging {
  ConfiguredFakePush({this.token = 'device-token-1'});

  final String? token;

  @override
  bool get isConfigured => true;

  @override
  Future<String?> obtainToken() async {
    obtainTokenCalls += 1;
    return token;
  }
}

class FakeApi implements Api {
  final List<String> registeredTokens = [];
  bool failRegistration = false;

  @override
  Future<void> registerDeviceToken(String fcmToken) async {
    if (failRegistration) throw Exception('offline');
    registeredTokens.add(fcmToken);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used by these tests');
}
