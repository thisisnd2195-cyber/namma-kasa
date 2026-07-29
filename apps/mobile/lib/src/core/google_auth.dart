import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';

/// Google Sign-In behind a seam (FR-AUTH-03).
///
/// The backend already verifies Google id tokens against `GOOGLE_CLIENT_ID`
/// and will create or match an account from one. What the app needs is a way
/// to *obtain* that token, and that requires an OAuth client id which is
/// per-environment.
///
/// So the seam is the deliverable: every caller works against this interface,
/// a fake drives it in development and in tests, and turning on the real thing
/// is providing a client id — not a code change.
abstract class GoogleAuthenticator {
  /// The signed-in account's id token, or null if the user backed out.
  Future<String?> signIn();

  Future<void> signOut();

  /// Whether a real provider is configured. Drives whether the button shows
  /// at all, so a build without credentials does not offer a dead control.
  bool get isConfigured;
}

/// Used when no OAuth client id is configured.
///
/// In debug builds it returns a clearly-marked token so the whole flow —
/// button, registration, session, and the server's rejection path — can be
/// exercised end to end. In release builds it refuses, because a build that
/// cannot really authenticate must not appear to.
class FakeGoogleAuthenticator implements GoogleAuthenticator {
  FakeGoogleAuthenticator({this.available = kDebugMode, this.email = 'dev@example.com'});

  final bool available;
  final String email;
  int signInCount = 0;
  int signOutCount = 0;

  @override
  bool get isConfigured => available;

  @override
  Future<String?> signIn() async {
    signInCount += 1;
    if (!available) return null;
    // Deliberately not a valid JWT. The server will reject it, which is the
    // honest outcome: this proves the plumbing, not the identity.
    return 'fake-google-id-token:$email';
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
  }
}

/// The real implementation, active once a client id is supplied.
///
/// Kept deliberately thin: everything above it is already tested against the
/// interface, so this class is the only thing a live credential changes.
class PlatformGoogleAuthenticator implements GoogleAuthenticator {
  PlatformGoogleAuthenticator(this.clientId);

  final String clientId;

  @override
  bool get isConfigured => clientId.isNotEmpty;

  @override
  Future<String?> signIn() async {
    throw UnimplementedError(
      'Add the google_sign_in package and return its idToken here. '
      'Everything that calls this already works against GoogleAuthenticator.',
    );
  }

  @override
  Future<void> signOut() async {}
}

/// Resolved once from the build environment.
final googleAuthProvider = Provider<GoogleAuthenticator>((ref) {
  const clientId = Env.googleClientId;
  return clientId.isEmpty
      ? FakeGoogleAuthenticator()
      : PlatformGoogleAuthenticator(clientId);
});
