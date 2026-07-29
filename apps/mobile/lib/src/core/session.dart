import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in user as the API describes them. Kept deliberately small —
/// anything richer belongs to a screen's own state.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
    required this.locale,
    this.wardId,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;
  final String locale;
  final String? wardId;

  bool get isDriver => role == 'driver';

  Session copyWith({String? accessToken, String? refreshToken, String? locale}) => Session(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        userId: userId,
        role: role,
        locale: locale ?? this.locale,
        wardId: wardId,
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'role': role,
        'locale': locale,
        'wardId': wardId,
      };

  static Session fromJson(Map<String, dynamic> json) => Session(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as String,
        role: json['role'] as String,
        locale: json['locale'] as String? ?? 'en',
        wardId: json['wardId'] as String?,
      );
}

/// Tokens live in the platform keystore, never in shared preferences.
class SessionStore {
  SessionStore(this._storage);

  static const _key = 'session';
  final FlutterSecureStorage _storage;

  Future<Session?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(Session session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(const FlutterSecureStorage()),
);

/// Holds the active session in memory; null means signed out.
class SessionController extends StateNotifier<Session?> {
  SessionController(this._store) : super(null);

  final SessionStore _store;

  Future<void> restore() async {
    state = await _store.read();
  }

  Future<void> signIn(Session session) async {
    await _store.write(session);
    state = session;
  }

  Future<void> updateTokens({required String access, required String refresh}) async {
    final current = state;
    if (current == null) return;
    final next = current.copyWith(accessToken: access, refreshToken: refresh);
    await _store.write(next);
    state = next;
  }

  /// The language the resident chose. Held here because it drives both the
  /// UI (MaterialApp.locale) and the server's push copy, and those two must
  /// not be allowed to disagree.
  Future<void> setLocale(String locale) async {
    final current = state;
    if (current == null) return;
    final next = current.copyWith(locale: locale);
    await _store.write(next);
    state = next;
  }

  Future<void> signOut() async {
    await _store.clear();
    state = null;
  }
}

/// Set by the language chooser during registration, before any account exists
/// to store the choice on.
final localeOverrideProvider = StateProvider<String?>((ref) => null);

/// Null means "follow the device", which is the only sensible default before
/// the resident has told us anything.
final localeProvider = Provider<Locale?>((ref) {
  final chosen = ref.watch(localeOverrideProvider) ?? ref.watch(sessionProvider)?.locale;
  return chosen == null ? null : Locale(chosen);
});

final sessionProvider = StateNotifierProvider<SessionController, Session?>(
  (ref) => SessionController(ref.watch(sessionStoreProvider)),
);
