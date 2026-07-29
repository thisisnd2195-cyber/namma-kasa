//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequest {
  /// Returns a new [RegisterRequest] instance.
  RegisterRequest({
    required this.role,
    required this.verificationToken,
    required this.credential,
    required this.profile,
    required this.deviceId,
  });

  RegisterRequestRoleEnum role;

  String verificationToken;

  RegisterRequestOneOfCredential credential;

  RegisterRequestOneOf1Profile profile;

  String deviceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequest &&
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
  String toString() => 'RegisterRequest[role=$role, verificationToken=$verificationToken, credential=$credential, profile=$profile, deviceId=$deviceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
      json[r'verificationToken'] = this.verificationToken;
      json[r'credential'] = this.credential;
      json[r'profile'] = this.profile;
      json[r'deviceId'] = this.deviceId;
    return json;
  }

  /// Returns a new [RegisterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "RegisterRequest[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "RegisterRequest[role]" has a null value in JSON.');
        assert(json.containsKey(r'verificationToken'), 'Required key "RegisterRequest[verificationToken]" is missing from JSON.');
        assert(json[r'verificationToken'] != null, 'Required key "RegisterRequest[verificationToken]" has a null value in JSON.');
        assert(json.containsKey(r'credential'), 'Required key "RegisterRequest[credential]" is missing from JSON.');
        assert(json[r'credential'] != null, 'Required key "RegisterRequest[credential]" has a null value in JSON.');
        assert(json.containsKey(r'profile'), 'Required key "RegisterRequest[profile]" is missing from JSON.');
        assert(json[r'profile'] != null, 'Required key "RegisterRequest[profile]" has a null value in JSON.');
        assert(json.containsKey(r'deviceId'), 'Required key "RegisterRequest[deviceId]" is missing from JSON.');
        assert(json[r'deviceId'] != null, 'Required key "RegisterRequest[deviceId]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequest(
        role: RegisterRequestRoleEnum.fromJson(json[r'role'])!,
        verificationToken: mapValueOfType<String>(json, r'verificationToken')!,
        credential: RegisterRequestOneOfCredential.fromJson(json[r'credential'])!,
        profile: RegisterRequestOneOf1Profile.fromJson(json[r'profile'])!,
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
      );
    }
    return null;
  }

  static List<RegisterRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequest> mapFromJson(dynamic json) {
    final map = <String, RegisterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequest-objects as value to a dart map
  static Map<String, List<RegisterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequest.listFromJson(entry.value, growable: growable,);
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


enum RegisterRequestRoleEnum {
  driver._(r'driver'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestRoleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestRoleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestRoleEnum? fromJson(dynamic value) => RegisterRequestRoleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestRoleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestRoleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestRoleEnum].
class RegisterRequestRoleEnumTypeTransformer {
  factory RegisterRequestRoleEnumTypeTransformer() => _instance ??= const RegisterRequestRoleEnumTypeTransformer._();

  const RegisterRequestRoleEnumTypeTransformer._();

  String encode(RegisterRequestRoleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestRoleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestRoleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'driver': return RegisterRequestRoleEnum.driver;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestRoleEnumTypeTransformer? _instance;
}


