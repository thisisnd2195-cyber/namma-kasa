//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestOneOf {
  /// Returns a new [RegisterRequestOneOf] instance.
  RegisterRequestOneOf({
    required this.role,
    required this.verificationToken,
    required this.credential,
    required this.profile,
  });

  RegisterRequestOneOfRoleEnum role;

  String verificationToken;

  RegisterRequestOneOfCredential credential;

  RegisterRequestOneOfProfile profile;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestOneOf &&
    other.role == role &&
    other.verificationToken == verificationToken &&
    other.credential == credential &&
    other.profile == profile;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (verificationToken.hashCode) +
    (credential.hashCode) +
    (profile.hashCode);

  @override
  String toString() => 'RegisterRequestOneOf[role=$role, verificationToken=$verificationToken, credential=$credential, profile=$profile]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
      json[r'verificationToken'] = this.verificationToken;
      json[r'credential'] = this.credential;
      json[r'profile'] = this.profile;
    return json;
  }

  /// Returns a new [RegisterRequestOneOf] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestOneOf? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "RegisterRequestOneOf[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "RegisterRequestOneOf[role]" has a null value in JSON.');
        assert(json.containsKey(r'verificationToken'), 'Required key "RegisterRequestOneOf[verificationToken]" is missing from JSON.');
        assert(json[r'verificationToken'] != null, 'Required key "RegisterRequestOneOf[verificationToken]" has a null value in JSON.');
        assert(json.containsKey(r'credential'), 'Required key "RegisterRequestOneOf[credential]" is missing from JSON.');
        assert(json[r'credential'] != null, 'Required key "RegisterRequestOneOf[credential]" has a null value in JSON.');
        assert(json.containsKey(r'profile'), 'Required key "RegisterRequestOneOf[profile]" is missing from JSON.');
        assert(json[r'profile'] != null, 'Required key "RegisterRequestOneOf[profile]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestOneOf(
        role: RegisterRequestOneOfRoleEnum.fromJson(json[r'role'])!,
        verificationToken: mapValueOfType<String>(json, r'verificationToken')!,
        credential: RegisterRequestOneOfCredential.fromJson(json[r'credential'])!,
        profile: RegisterRequestOneOfProfile.fromJson(json[r'profile'])!,
      );
    }
    return null;
  }

  static List<RegisterRequestOneOf> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOf>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOf.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestOneOf> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestOneOf>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestOneOf.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestOneOf-objects as value to a dart map
  static Map<String, List<RegisterRequestOneOf>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestOneOf>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestOneOf.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
    'verificationToken',
    'credential',
    'profile',
  };
}


enum RegisterRequestOneOfRoleEnum {
  resident._(r'resident'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestOneOfRoleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestOneOfRoleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestOneOfRoleEnum? fromJson(dynamic value) => RegisterRequestOneOfRoleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestOneOfRoleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestOneOfRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOfRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOfRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestOneOfRoleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestOneOfRoleEnum].
class RegisterRequestOneOfRoleEnumTypeTransformer {
  factory RegisterRequestOneOfRoleEnumTypeTransformer() => _instance ??= const RegisterRequestOneOfRoleEnumTypeTransformer._();

  const RegisterRequestOneOfRoleEnumTypeTransformer._();

  String encode(RegisterRequestOneOfRoleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestOneOfRoleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestOneOfRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestOneOfRoleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'resident': return RegisterRequestOneOfRoleEnum.resident;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestOneOfRoleEnumTypeTransformer? _instance;
}


