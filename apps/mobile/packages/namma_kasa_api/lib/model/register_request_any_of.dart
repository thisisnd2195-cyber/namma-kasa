//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestAnyOf {
  /// Returns a new [RegisterRequestAnyOf] instance.
  RegisterRequestAnyOf({
    required this.role,
    required this.verificationToken,
    this.credential = const {},
    required this.profile,
  });

  RegisterRequestAnyOfRoleEnum role;

  String verificationToken;

  Map<String, Object?> credential;

  RegisterRequestAnyOfProfile profile;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestAnyOf &&
    other.role == role &&
    other.verificationToken == verificationToken &&
    _deepEquality.equals(other.credential, credential) &&
    other.profile == profile;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (verificationToken.hashCode) +
    (credential.hashCode) +
    (profile.hashCode);

  @override
  String toString() => 'RegisterRequestAnyOf[role=$role, verificationToken=$verificationToken, credential=$credential, profile=$profile]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
      json[r'verificationToken'] = this.verificationToken;
      json[r'credential'] = this.credential;
      json[r'profile'] = this.profile;
    return json;
  }

  /// Returns a new [RegisterRequestAnyOf] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestAnyOf? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "RegisterRequestAnyOf[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "RegisterRequestAnyOf[role]" has a null value in JSON.');
        assert(json.containsKey(r'verificationToken'), 'Required key "RegisterRequestAnyOf[verificationToken]" is missing from JSON.');
        assert(json[r'verificationToken'] != null, 'Required key "RegisterRequestAnyOf[verificationToken]" has a null value in JSON.');
        assert(json.containsKey(r'credential'), 'Required key "RegisterRequestAnyOf[credential]" is missing from JSON.');
        assert(json[r'credential'] != null, 'Required key "RegisterRequestAnyOf[credential]" has a null value in JSON.');
        assert(json.containsKey(r'profile'), 'Required key "RegisterRequestAnyOf[profile]" is missing from JSON.');
        assert(json[r'profile'] != null, 'Required key "RegisterRequestAnyOf[profile]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestAnyOf(
        role: RegisterRequestAnyOfRoleEnum.fromJson(json[r'role'])!,
        verificationToken: mapValueOfType<String>(json, r'verificationToken')!,
        credential: mapCastOfType<String, Object>(json, r'credential')!,
        profile: RegisterRequestAnyOfProfile.fromJson(json[r'profile'])!,
      );
    }
    return null;
  }

  static List<RegisterRequestAnyOf> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestAnyOf>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestAnyOf.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestAnyOf> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestAnyOf>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestAnyOf.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestAnyOf-objects as value to a dart map
  static Map<String, List<RegisterRequestAnyOf>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestAnyOf>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestAnyOf.listFromJson(entry.value, growable: growable,);
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


enum RegisterRequestAnyOfRoleEnum {
  resident._(r'resident'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestAnyOfRoleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestAnyOfRoleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestAnyOfRoleEnum? fromJson(dynamic value) => RegisterRequestAnyOfRoleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestAnyOfRoleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestAnyOfRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestAnyOfRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestAnyOfRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestAnyOfRoleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestAnyOfRoleEnum].
class RegisterRequestAnyOfRoleEnumTypeTransformer {
  factory RegisterRequestAnyOfRoleEnumTypeTransformer() => _instance ??= const RegisterRequestAnyOfRoleEnumTypeTransformer._();

  const RegisterRequestAnyOfRoleEnumTypeTransformer._();

  String encode(RegisterRequestAnyOfRoleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestAnyOfRoleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestAnyOfRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestAnyOfRoleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'resident': return RegisterRequestAnyOfRoleEnum.resident;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestAnyOfRoleEnumTypeTransformer? _instance;
}


