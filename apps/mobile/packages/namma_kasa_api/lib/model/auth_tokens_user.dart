//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthTokensUser {
  /// Returns a new [AuthTokensUser] instance.
  AuthTokensUser({
    required this.id,
    required this.role,
    required this.locale,
    required this.authProvider,
    required this.wardId,
  });

  String id;

  AuthTokensUserRoleEnum role;

  AuthTokensUserLocaleEnum locale;

  AuthTokensUserAuthProviderEnum authProvider;

  String? wardId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthTokensUser &&
    other.id == id &&
    other.role == role &&
    other.locale == locale &&
    other.authProvider == authProvider &&
    other.wardId == wardId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (role.hashCode) +
    (locale.hashCode) +
    (authProvider.hashCode) +
    (wardId == null ? 0 : wardId!.hashCode);

  @override
  String toString() => 'AuthTokensUser[id=$id, role=$role, locale=$locale, authProvider=$authProvider, wardId=$wardId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'role'] = this.role;
      json[r'locale'] = this.locale;
      json[r'authProvider'] = this.authProvider;
    if (this.wardId != null) {
      json[r'wardId'] = this.wardId;
    } else {
      json[r'wardId'] = null;
    }
    return json;
  }

  /// Returns a new [AuthTokensUser] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthTokensUser? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "AuthTokensUser[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "AuthTokensUser[id]" has a null value in JSON.');
        assert(json.containsKey(r'role'), 'Required key "AuthTokensUser[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "AuthTokensUser[role]" has a null value in JSON.');
        assert(json.containsKey(r'locale'), 'Required key "AuthTokensUser[locale]" is missing from JSON.');
        assert(json[r'locale'] != null, 'Required key "AuthTokensUser[locale]" has a null value in JSON.');
        assert(json.containsKey(r'authProvider'), 'Required key "AuthTokensUser[authProvider]" is missing from JSON.');
        assert(json[r'authProvider'] != null, 'Required key "AuthTokensUser[authProvider]" has a null value in JSON.');
        assert(json.containsKey(r'wardId'), 'Required key "AuthTokensUser[wardId]" is missing from JSON.');
        return true;
      }());

      return AuthTokensUser(
        id: mapValueOfType<String>(json, r'id')!,
        role: AuthTokensUserRoleEnum.fromJson(json[r'role'])!,
        locale: AuthTokensUserLocaleEnum.fromJson(json[r'locale'])!,
        authProvider: AuthTokensUserAuthProviderEnum.fromJson(json[r'authProvider'])!,
        wardId: mapValueOfType<String>(json, r'wardId'),
      );
    }
    return null;
  }

  static List<AuthTokensUser> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokensUser>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokensUser.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthTokensUser> mapFromJson(dynamic json) {
    final map = <String, AuthTokensUser>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthTokensUser.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthTokensUser-objects as value to a dart map
  static Map<String, List<AuthTokensUser>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthTokensUser>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthTokensUser.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'role',
    'locale',
    'authProvider',
    'wardId',
  };
}


enum AuthTokensUserRoleEnum {
  resident._(r'resident'),
  driver._(r'driver'),
  wardAdmin._(r'ward_admin'),
  superAdmin._(r'super_admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const AuthTokensUserRoleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AuthTokensUserRoleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AuthTokensUserRoleEnum? fromJson(dynamic value) => AuthTokensUserRoleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AuthTokensUserRoleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AuthTokensUserRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokensUserRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokensUserRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthTokensUserRoleEnum] to String,
/// and [decode] dynamic data back to [AuthTokensUserRoleEnum].
class AuthTokensUserRoleEnumTypeTransformer {
  factory AuthTokensUserRoleEnumTypeTransformer() => _instance ??= const AuthTokensUserRoleEnumTypeTransformer._();

  const AuthTokensUserRoleEnumTypeTransformer._();

  String encode(AuthTokensUserRoleEnum data) => data._value;

  /// Returns the instance of [AuthTokensUserRoleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthTokensUserRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AuthTokensUserRoleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'resident': return AuthTokensUserRoleEnum.resident;
        case r'driver': return AuthTokensUserRoleEnum.driver;
        case r'ward_admin': return AuthTokensUserRoleEnum.wardAdmin;
        case r'super_admin': return AuthTokensUserRoleEnum.superAdmin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AuthTokensUserRoleEnumTypeTransformer? _instance;
}



enum AuthTokensUserLocaleEnum {
  en._(r'en'),
  kn._(r'kn'),
  ;

  /// Instantiate a new enum with the provided value.
  const AuthTokensUserLocaleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AuthTokensUserLocaleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AuthTokensUserLocaleEnum? fromJson(dynamic value) => AuthTokensUserLocaleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AuthTokensUserLocaleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AuthTokensUserLocaleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokensUserLocaleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokensUserLocaleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthTokensUserLocaleEnum] to String,
/// and [decode] dynamic data back to [AuthTokensUserLocaleEnum].
class AuthTokensUserLocaleEnumTypeTransformer {
  factory AuthTokensUserLocaleEnumTypeTransformer() => _instance ??= const AuthTokensUserLocaleEnumTypeTransformer._();

  const AuthTokensUserLocaleEnumTypeTransformer._();

  String encode(AuthTokensUserLocaleEnum data) => data._value;

  /// Returns the instance of [AuthTokensUserLocaleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthTokensUserLocaleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AuthTokensUserLocaleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'en': return AuthTokensUserLocaleEnum.en;
        case r'kn': return AuthTokensUserLocaleEnum.kn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AuthTokensUserLocaleEnumTypeTransformer? _instance;
}



enum AuthTokensUserAuthProviderEnum {
  password._(r'password'),
  google._(r'google'),
  ;

  /// Instantiate a new enum with the provided value.
  const AuthTokensUserAuthProviderEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AuthTokensUserAuthProviderEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AuthTokensUserAuthProviderEnum? fromJson(dynamic value) => AuthTokensUserAuthProviderEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AuthTokensUserAuthProviderEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AuthTokensUserAuthProviderEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokensUserAuthProviderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokensUserAuthProviderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthTokensUserAuthProviderEnum] to String,
/// and [decode] dynamic data back to [AuthTokensUserAuthProviderEnum].
class AuthTokensUserAuthProviderEnumTypeTransformer {
  factory AuthTokensUserAuthProviderEnumTypeTransformer() => _instance ??= const AuthTokensUserAuthProviderEnumTypeTransformer._();

  const AuthTokensUserAuthProviderEnumTypeTransformer._();

  String encode(AuthTokensUserAuthProviderEnum data) => data._value;

  /// Returns the instance of [AuthTokensUserAuthProviderEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthTokensUserAuthProviderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AuthTokensUserAuthProviderEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'password': return AuthTokensUserAuthProviderEnum.password;
        case r'google': return AuthTokensUserAuthProviderEnum.google;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AuthTokensUserAuthProviderEnumTypeTransformer? _instance;
}


