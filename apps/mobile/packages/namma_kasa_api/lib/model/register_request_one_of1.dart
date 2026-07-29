//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestOneOf1 {
  /// Returns a new [RegisterRequestOneOf1] instance.
  RegisterRequestOneOf1({
    required this.role,
    required this.verificationToken,
    required this.credential,
    required this.profile,
    required this.deviceId,
  });

  RegisterRequestOneOf1RoleEnum role;

  String verificationToken;

  RegisterRequestOneOfCredential credential;

  RegisterRequestOneOf1Profile profile;

  String deviceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestOneOf1 &&
    other.role == role &&
    other.verificationToken == verificationToken &&
    other.credential == credential &&
    other.profile == profile &&
    other.deviceId == deviceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (verificationToken.hashCode) +
    (credential.hashCode) +
    (profile.hashCode) +
    (deviceId.hashCode);

  @override
  String toString() => 'RegisterRequestOneOf1[role=$role, verificationToken=$verificationToken, credential=$credential, profile=$profile, deviceId=$deviceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
      json[r'verificationToken'] = this.verificationToken;
      json[r'credential'] = this.credential;
      json[r'profile'] = this.profile;
      json[r'deviceId'] = this.deviceId;
    return json;
  }

  /// Returns a new [RegisterRequestOneOf1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestOneOf1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "RegisterRequestOneOf1[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "RegisterRequestOneOf1[role]" has a null value in JSON.');
        assert(json.containsKey(r'verificationToken'), 'Required key "RegisterRequestOneOf1[verificationToken]" is missing from JSON.');
        assert(json[r'verificationToken'] != null, 'Required key "RegisterRequestOneOf1[verificationToken]" has a null value in JSON.');
        assert(json.containsKey(r'credential'), 'Required key "RegisterRequestOneOf1[credential]" is missing from JSON.');
        assert(json[r'credential'] != null, 'Required key "RegisterRequestOneOf1[credential]" has a null value in JSON.');
        assert(json.containsKey(r'profile'), 'Required key "RegisterRequestOneOf1[profile]" is missing from JSON.');
        assert(json[r'profile'] != null, 'Required key "RegisterRequestOneOf1[profile]" has a null value in JSON.');
        assert(json.containsKey(r'deviceId'), 'Required key "RegisterRequestOneOf1[deviceId]" is missing from JSON.');
        assert(json[r'deviceId'] != null, 'Required key "RegisterRequestOneOf1[deviceId]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestOneOf1(
        role: RegisterRequestOneOf1RoleEnum.fromJson(json[r'role'])!,
        verificationToken: mapValueOfType<String>(json, r'verificationToken')!,
        credential: RegisterRequestOneOfCredential.fromJson(json[r'credential'])!,
        profile: RegisterRequestOneOf1Profile.fromJson(json[r'profile'])!,
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
      );
    }
    return null;
  }

  static List<RegisterRequestOneOf1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOf1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOf1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestOneOf1> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestOneOf1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestOneOf1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestOneOf1-objects as value to a dart map
  static Map<String, List<RegisterRequestOneOf1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestOneOf1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestOneOf1.listFromJson(entry.value, growable: growable,);
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
    'deviceId',
  };
}


enum RegisterRequestOneOf1RoleEnum {
  driver._(r'driver'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestOneOf1RoleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestOneOf1RoleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestOneOf1RoleEnum? fromJson(dynamic value) => RegisterRequestOneOf1RoleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestOneOf1RoleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestOneOf1RoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOf1RoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOf1RoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestOneOf1RoleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestOneOf1RoleEnum].
class RegisterRequestOneOf1RoleEnumTypeTransformer {
  factory RegisterRequestOneOf1RoleEnumTypeTransformer() => _instance ??= const RegisterRequestOneOf1RoleEnumTypeTransformer._();

  const RegisterRequestOneOf1RoleEnumTypeTransformer._();

  String encode(RegisterRequestOneOf1RoleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestOneOf1RoleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestOneOf1RoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestOneOf1RoleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'driver': return RegisterRequestOneOf1RoleEnum.driver;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestOneOf1RoleEnumTypeTransformer? _instance;
}


