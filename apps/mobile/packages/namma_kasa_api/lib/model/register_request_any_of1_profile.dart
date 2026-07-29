//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestAnyOf1Profile {
  /// Returns a new [RegisterRequestAnyOf1Profile] instance.
  RegisterRequestAnyOf1Profile({
    this.locale,
    required this.consent,
  });

  RegisterRequestAnyOf1ProfileLocaleEnum? locale;

  bool consent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestAnyOf1Profile &&
    other.locale == locale &&
    other.consent == consent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (locale == null ? 0 : locale!.hashCode) +
    (consent.hashCode);

  @override
  String toString() => 'RegisterRequestAnyOf1Profile[locale=$locale, consent=$consent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
      json[r'consent'] = this.consent;
    return json;
  }

  /// Returns a new [RegisterRequestAnyOf1Profile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestAnyOf1Profile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consent'), 'Required key "RegisterRequestAnyOf1Profile[consent]" is missing from JSON.');
        assert(json[r'consent'] != null, 'Required key "RegisterRequestAnyOf1Profile[consent]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestAnyOf1Profile(
        locale: RegisterRequestAnyOf1ProfileLocaleEnum.fromJson(json[r'locale']),
        consent: mapValueOfType<bool>(json, r'consent')!,
      );
    }
    return null;
  }

  static List<RegisterRequestAnyOf1Profile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestAnyOf1Profile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestAnyOf1Profile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestAnyOf1Profile> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestAnyOf1Profile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestAnyOf1Profile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestAnyOf1Profile-objects as value to a dart map
  static Map<String, List<RegisterRequestAnyOf1Profile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestAnyOf1Profile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestAnyOf1Profile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consent',
  };
}


enum RegisterRequestAnyOf1ProfileLocaleEnum {
  en._(r'en'),
  kn._(r'kn'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestAnyOf1ProfileLocaleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestAnyOf1ProfileLocaleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestAnyOf1ProfileLocaleEnum? fromJson(dynamic value) => RegisterRequestAnyOf1ProfileLocaleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestAnyOf1ProfileLocaleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestAnyOf1ProfileLocaleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestAnyOf1ProfileLocaleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestAnyOf1ProfileLocaleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestAnyOf1ProfileLocaleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestAnyOf1ProfileLocaleEnum].
class RegisterRequestAnyOf1ProfileLocaleEnumTypeTransformer {
  factory RegisterRequestAnyOf1ProfileLocaleEnumTypeTransformer() => _instance ??= const RegisterRequestAnyOf1ProfileLocaleEnumTypeTransformer._();

  const RegisterRequestAnyOf1ProfileLocaleEnumTypeTransformer._();

  String encode(RegisterRequestAnyOf1ProfileLocaleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestAnyOf1ProfileLocaleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestAnyOf1ProfileLocaleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestAnyOf1ProfileLocaleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'en': return RegisterRequestAnyOf1ProfileLocaleEnum.en;
        case r'kn': return RegisterRequestAnyOf1ProfileLocaleEnum.kn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestAnyOf1ProfileLocaleEnumTypeTransformer? _instance;
}


