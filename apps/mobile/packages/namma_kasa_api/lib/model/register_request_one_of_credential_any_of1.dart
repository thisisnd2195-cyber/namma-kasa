//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestOneOfCredentialAnyOf1 {
  /// Returns a new [RegisterRequestOneOfCredentialAnyOf1] instance.
  RegisterRequestOneOfCredentialAnyOf1({
    required this.googleIdToken,
  });

  String googleIdToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestOneOfCredentialAnyOf1 &&
    other.googleIdToken == googleIdToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (googleIdToken.hashCode);

  @override
  String toString() => 'RegisterRequestOneOfCredentialAnyOf1[googleIdToken=$googleIdToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'googleIdToken'] = this.googleIdToken;
    return json;
  }

  /// Returns a new [RegisterRequestOneOfCredentialAnyOf1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestOneOfCredentialAnyOf1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'googleIdToken'), 'Required key "RegisterRequestOneOfCredentialAnyOf1[googleIdToken]" is missing from JSON.');
        assert(json[r'googleIdToken'] != null, 'Required key "RegisterRequestOneOfCredentialAnyOf1[googleIdToken]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestOneOfCredentialAnyOf1(
        googleIdToken: mapValueOfType<String>(json, r'googleIdToken')!,
      );
    }
    return null;
  }

  static List<RegisterRequestOneOfCredentialAnyOf1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOfCredentialAnyOf1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOfCredentialAnyOf1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestOneOfCredentialAnyOf1> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestOneOfCredentialAnyOf1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestOneOfCredentialAnyOf1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestOneOfCredentialAnyOf1-objects as value to a dart map
  static Map<String, List<RegisterRequestOneOfCredentialAnyOf1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestOneOfCredentialAnyOf1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestOneOfCredentialAnyOf1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'googleIdToken',
  };
}

