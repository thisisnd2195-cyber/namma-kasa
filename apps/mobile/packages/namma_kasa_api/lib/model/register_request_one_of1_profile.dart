//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestOneOf1Profile {
  /// Returns a new [RegisterRequestOneOf1Profile] instance.
  RegisterRequestOneOf1Profile({
    this.locale = const RegisterRequestOneOf1ProfileLocaleEnum._('kn'),
    required this.consent,
  });

  RegisterRequestOneOf1ProfileLocaleEnum locale;

  RegisterRequestOneOf1ProfileConsentEnum consent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestOneOf1Profile &&
    other.locale == locale &&
    other.consent == consent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (locale.hashCode) +
    (consent.hashCode);

  @override
  String toString() => 'RegisterRequestOneOf1Profile[locale=$locale, consent=$consent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'locale'] = this.locale;
      json[r'consent'] = this.consent;
    return json;
  }

  /// Returns a new [RegisterRequestOneOf1Profile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestOneOf1Profile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'consent'), 'Required key "RegisterRequestOneOf1Profile[consent]" is missing from JSON.');
        assert(json[r'consent'] != null, 'Required key "RegisterRequestOneOf1Profile[consent]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestOneOf1Profile(
        locale: RegisterRequestOneOf1ProfileLocaleEnum.fromJson(json[r'locale']) ?? const RegisterRequestOneOf1ProfileLocaleEnum._('kn'),
        consent: RegisterRequestOneOf1ProfileConsentEnum.fromJson(json[r'consent'])!,
      );
    }
    return null;
  }

  static List<RegisterRequestOneOf1Profile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOf1Profile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOf1Profile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestOneOf1Profile> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestOneOf1Profile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestOneOf1Profile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestOneOf1Profile-objects as value to a dart map
  static Map<String, List<RegisterRequestOneOf1Profile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestOneOf1Profile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestOneOf1Profile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'consent',
  };
}


enum RegisterRequestOneOf1ProfileLocaleEnum {
  en._(r'en'),
  kn._(r'kn'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestOneOf1ProfileLocaleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestOneOf1ProfileLocaleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestOneOf1ProfileLocaleEnum? fromJson(dynamic value) => RegisterRequestOneOf1ProfileLocaleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestOneOf1ProfileLocaleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestOneOf1ProfileLocaleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOf1ProfileLocaleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOf1ProfileLocaleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestOneOf1ProfileLocaleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestOneOf1ProfileLocaleEnum].
class RegisterRequestOneOf1ProfileLocaleEnumTypeTransformer {
  factory RegisterRequestOneOf1ProfileLocaleEnumTypeTransformer() => _instance ??= const RegisterRequestOneOf1ProfileLocaleEnumTypeTransformer._();

  const RegisterRequestOneOf1ProfileLocaleEnumTypeTransformer._();

  String encode(RegisterRequestOneOf1ProfileLocaleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestOneOf1ProfileLocaleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestOneOf1ProfileLocaleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestOneOf1ProfileLocaleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'en': return RegisterRequestOneOf1ProfileLocaleEnum.en;
        case r'kn': return RegisterRequestOneOf1ProfileLocaleEnum.kn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestOneOf1ProfileLocaleEnumTypeTransformer? _instance;
}



enum RegisterRequestOneOf1ProfileConsentEnum {
  true_._('true'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestOneOf1ProfileConsentEnum._(this._value);

  /// The underlying value of this enum member.
  final bool _value;

  @override
  String toString() => _value.toString();

  /// Encodes this enum as a value suitable for JSON.
  bool toJson() => _value;

  /// Returns the instance of [RegisterRequestOneOf1ProfileConsentEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestOneOf1ProfileConsentEnum? fromJson(dynamic value) => RegisterRequestOneOf1ProfileConsentEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestOneOf1ProfileConsentEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestOneOf1ProfileConsentEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOf1ProfileConsentEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOf1ProfileConsentEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestOneOf1ProfileConsentEnum] to bool,
/// and [decode] dynamic data back to [RegisterRequestOneOf1ProfileConsentEnum].
class RegisterRequestOneOf1ProfileConsentEnumTypeTransformer {
  factory RegisterRequestOneOf1ProfileConsentEnumTypeTransformer() => _instance ??= const RegisterRequestOneOf1ProfileConsentEnumTypeTransformer._();

  const RegisterRequestOneOf1ProfileConsentEnumTypeTransformer._();

  bool encode(RegisterRequestOneOf1ProfileConsentEnum data) => data._value;

  /// Returns the instance of [RegisterRequestOneOf1ProfileConsentEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestOneOf1ProfileConsentEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestOneOf1ProfileConsentEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case 'true': return RegisterRequestOneOf1ProfileConsentEnum.true_;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestOneOf1ProfileConsentEnumTypeTransformer? _instance;
}


