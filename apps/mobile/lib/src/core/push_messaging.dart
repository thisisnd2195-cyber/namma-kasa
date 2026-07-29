import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';

/// A push the server sent, flattened to what the app acts on.
///
/// Mirrors the payload `NotifyService` builds: `title`, `body`, and a `kind`
/// plus whatever ids that kind carries.
@immutable
class PushMessage {
  const PushMessage({
    required this.kind,
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String kind;
  final String title;
  final String body;
  final Map<String, String> data;

  factory PushMessage.fromData(Map<String, dynamic> payload) {
    final data = <String, String>{
      for (final entry in payload.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    return PushMessage(
      kind: data['kind'] ?? 'unknown',
      title: data.remove('title') ?? '',
      body: data.remove('body') ?? '',
      data: data,
    );
  }

  /// The alerts that mean an auto is close enough to act on (FR-NOTIF-01/03).
  bool get isArrivalRelated => kind == 'proximity' || kind == 'arrival';

  @override
  bool operator ==(Object other) =>
      other is PushMessage &&
      other.kind == kind &&
      other.title == title &&
      other.body == body &&
      mapEquals(other.data, data);

  @override
  int get hashCode => Object.hash(kind, title, body, data.length);
}

/// Device push behind a seam (FR-NOTIF-01).
///
/// `firebase_messaging` cannot even be added to the build without a
/// `google-services.json` from a real Firebase project, so the interface is
/// the deliverable: token acquisition and message delivery are abstract, and
/// every caller — registration, foreground handling, the in-app fallback — is
/// written and tested against this rather than against Firebase.
abstract class PushMessaging {
  /// Whether a real transport is configured for this build.
  bool get isConfigured;

  /// Asks for permission and returns the device token, or null if refused or
  /// unavailable.
  Future<String?> obtainToken();

  /// Pushes arriving while the app is in the foreground. The OS does not
  /// display these itself, so the app has to.
  Stream<PushMessage> get foregroundMessages;

  /// The push that launched the app from a cold start, if any.
  Future<PushMessage?> initialMessage();

  Future<void> dispose();
}

/// Used until a Firebase project exists.
///
/// Reports no token, so nothing is registered server-side and the resident
/// falls back to the in-app banner. Its message stream is driveable, which is
/// what lets the foreground and cold-start paths be tested for real.
class FakePushMessaging implements PushMessaging {
  final _controller = StreamController<PushMessage>.broadcast();
  PushMessage? _initial;
  int obtainTokenCalls = 0;

  /// Set by tests, or by a dev harness, to simulate an incoming push.
  void emit(PushMessage message) => _controller.add(message);

  /// Simulates the app being launched by tapping a notification.
  void setInitialMessage(PushMessage? message) => _initial = message;

  @override
  bool get isConfigured => false;

  @override
  Future<String?> obtainToken() async {
    obtainTokenCalls += 1;
    return null;
  }

  @override
  Stream<PushMessage> get foregroundMessages => _controller.stream;

  @override
  Future<PushMessage?> initialMessage() async => _initial;

  @override
  Future<void> dispose() => _controller.close();
}

/// The real transport, active once Firebase is configured.
///
/// Thin on purpose: everything above it already works against the interface,
/// so a live project changes only this class and the build config.
class FirebasePushMessaging implements PushMessaging {
  @override
  bool get isConfigured => true;

  @override
  Future<String?> obtainToken() async {
    throw UnimplementedError(
      'Add firebase_messaging, then return FirebaseMessaging.instance.getToken() '
      'after requestPermission(). Callers already work against PushMessaging.',
    );
  }

  @override
  Stream<PushMessage> get foregroundMessages =>
      throw UnimplementedError('Map FirebaseMessaging.onMessage to PushMessage.fromData.');

  @override
  Future<PushMessage?> initialMessage() async =>
      throw UnimplementedError('Map FirebaseMessaging.instance.getInitialMessage().');

  @override
  Future<void> dispose() async {}
}

final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final messaging = Env.firebaseConfigured ? FirebasePushMessaging() : FakePushMessaging();
  ref.onDispose(() => unawaited(messaging.dispose()));
  return messaging;
});
