//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthTokens {
  /// Returns a new [AuthTokens] instance.
  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSec,
    required this.user,
  });

  String accessToken;

  String refreshToken;

  int expiresInSec;

  AuthTokensUser user;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthTokens &&
    other.accessToken == accessToken &&
    other.refreshToken == refreshToken &&
    other.expiresInSec == expiresInSec &&
    other.user == user;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessToken.hashCode) +
    (refreshToken.hashCode) +
    (expiresInSec.hashCode) +
    (user.hashCode);

  @override
  String toString() => 'AuthTokens[accessToken=$accessToken, refreshToken=$refreshToken, expiresInSec=$expiresInSec, user=$user]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accessToken'] = this.accessToken;
      json[r'refreshToken'] = this.refreshToken;
      json[r'expiresInSec'] = this.expiresInSec;
      json[r'user'] = this.user;
    return json;
  }

  /// Returns a new [AuthTokens] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthTokens? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accessToken'), 'Required key "AuthTokens[accessToken]" is missing from JSON.');
        assert(json[r'accessToken'] != null, 'Required key "AuthTokens[accessToken]" has a null value in JSON.');
        assert(json.containsKey(r'refreshToken'), 'Required key "AuthTokens[refreshToken]" is missing from JSON.');
        assert(json[r'refreshToken'] != null, 'Required key "AuthTokens[refreshToken]" has a null value in JSON.');
        assert(json.containsKey(r'expiresInSec'), 'Required key "AuthTokens[expiresInSec]" is missing from JSON.');
        assert(json[r'expiresInSec'] != null, 'Required key "AuthTokens[expiresInSec]" has a null value in JSON.');
        assert(json.containsKey(r'user'), 'Required key "AuthTokens[user]" is missing from JSON.');
        assert(json[r'user'] != null, 'Required key "AuthTokens[user]" has a null value in JSON.');
        return true;
      }());

      return AuthTokens(
        accessToken: mapValueOfType<String>(json, r'accessToken')!,
        refreshToken: mapValueOfType<String>(json, r'refreshToken')!,
        expiresInSec: mapValueOfType<int>(json, r'expiresInSec')!,
        user: AuthTokensUser.fromJson(json[r'user'])!,
      );
    }
    return null;
  }

  static List<AuthTokens> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokens>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokens.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthTokens> mapFromJson(dynamic json) {
    final map = <String, AuthTokens>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthTokens.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthTokens-objects as value to a dart map
  static Map<String, List<AuthTokens>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthTokens>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthTokens.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accessToken',
    'refreshToken',
    'expiresInSec',
    'user',
  };
}

