//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestOneOfProfile {
  /// Returns a new [RegisterRequestOneOfProfile] instance.
  RegisterRequestOneOfProfile({
    required this.fullName,
    required this.addressLine,
    this.landmark,
    required this.pin,
    this.locale = const RegisterRequestOneOfProfileLocaleEnum._('en'),
    required this.consent,
  });

  String fullName;

  String addressLine;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? landmark;

  RegisterRequestOneOfProfilePin pin;

  RegisterRequestOneOfProfileLocaleEnum locale;

  RegisterRequestOneOfProfileConsentEnum consent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestOneOfProfile &&
    other.fullName == fullName &&
    other.addressLine == addressLine &&
    other.landmark == landmark &&
    other.pin == pin &&
    other.locale == locale &&
    other.consent == consent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fullName.hashCode) +
    (addressLine.hashCode) +
    (landmark == null ? 0 : landmark!.hashCode) +
    (pin.hashCode) +
    (locale.hashCode) +
    (consent.hashCode);

  @override
  String toString() => 'RegisterRequestOneOfProfile[fullName=$fullName, addressLine=$addressLine, landmark=$landmark, pin=$pin, locale=$locale, consent=$consent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fullName'] = this.fullName;
      json[r'addressLine'] = this.addressLine;
    if (this.landmark != null) {
      json[r'landmark'] = this.landmark;
    } else {
      json[r'landmark'] = null;
    }
      json[r'pin'] = this.pin;
      json[r'locale'] = this.locale;
      json[r'consent'] = this.consent;
    return json;
  }

  /// Returns a new [RegisterRequestOneOfProfile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestOneOfProfile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fullName'), 'Required key "RegisterRequestOneOfProfile[fullName]" is missing from JSON.');
        assert(json[r'fullName'] != null, 'Required key "RegisterRequestOneOfProfile[fullName]" has a null value in JSON.');
        assert(json.containsKey(r'addressLine'), 'Required key "RegisterRequestOneOfProfile[addressLine]" is missing from JSON.');
        assert(json[r'addressLine'] != null, 'Required key "RegisterRequestOneOfProfile[addressLine]" has a null value in JSON.');
        assert(json.containsKey(r'pin'), 'Required key "RegisterRequestOneOfProfile[pin]" is missing from JSON.');
        assert(json[r'pin'] != null, 'Required key "RegisterRequestOneOfProfile[pin]" has a null value in JSON.');
        assert(json.containsKey(r'consent'), 'Required key "RegisterRequestOneOfProfile[consent]" is missing from JSON.');
        assert(json[r'consent'] != null, 'Required key "RegisterRequestOneOfProfile[consent]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestOneOfProfile(
        fullName: mapValueOfType<String>(json, r'fullName')!,
        addressLine: mapValueOfType<String>(json, r'addressLine')!,
        landmark: mapValueOfType<String>(json, r'landmark'),
        pin: RegisterRequestOneOfProfilePin.fromJson(json[r'pin'])!,
        locale: RegisterRequestOneOfProfileLocaleEnum.fromJson(json[r'locale']) ?? const RegisterRequestOneOfProfileLocaleEnum._('en'),
        consent: RegisterRequestOneOfProfileConsentEnum.fromJson(json[r'consent'])!,
      );
    }
    return null;
  }

  static List<RegisterRequestOneOfProfile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOfProfile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOfProfile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestOneOfProfile> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestOneOfProfile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestOneOfProfile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestOneOfProfile-objects as value to a dart map
  static Map<String, List<RegisterRequestOneOfProfile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestOneOfProfile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestOneOfProfile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fullName',
    'addressLine',
    'pin',
    'consent',
  };
}


enum RegisterRequestOneOfProfileLocaleEnum {
  en._(r'en'),
  kn._(r'kn'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestOneOfProfileLocaleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestOneOfProfileLocaleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestOneOfProfileLocaleEnum? fromJson(dynamic value) => RegisterRequestOneOfProfileLocaleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestOneOfProfileLocaleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestOneOfProfileLocaleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOfProfileLocaleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOfProfileLocaleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestOneOfProfileLocaleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestOneOfProfileLocaleEnum].
class RegisterRequestOneOfProfileLocaleEnumTypeTransformer {
  factory RegisterRequestOneOfProfileLocaleEnumTypeTransformer() => _instance ??= const RegisterRequestOneOfProfileLocaleEnumTypeTransformer._();

  const RegisterRequestOneOfProfileLocaleEnumTypeTransformer._();

  String encode(RegisterRequestOneOfProfileLocaleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestOneOfProfileLocaleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestOneOfProfileLocaleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestOneOfProfileLocaleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'en': return RegisterRequestOneOfProfileLocaleEnum.en;
        case r'kn': return RegisterRequestOneOfProfileLocaleEnum.kn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestOneOfProfileLocaleEnumTypeTransformer? _instance;
}



enum RegisterRequestOneOfProfileConsentEnum {
  true_._('true'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestOneOfProfileConsentEnum._(this._value);

  /// The underlying value of this enum member.
  final bool _value;

  @override
  String toString() => _value.toString();

  /// Encodes this enum as a value suitable for JSON.
  bool toJson() => _value;

  /// Returns the instance of [RegisterRequestOneOfProfileConsentEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestOneOfProfileConsentEnum? fromJson(dynamic value) => RegisterRequestOneOfProfileConsentEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestOneOfProfileConsentEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestOneOfProfileConsentEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestOneOfProfileConsentEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestOneOfProfileConsentEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestOneOfProfileConsentEnum] to bool,
/// and [decode] dynamic data back to [RegisterRequestOneOfProfileConsentEnum].
class RegisterRequestOneOfProfileConsentEnumTypeTransformer {
  factory RegisterRequestOneOfProfileConsentEnumTypeTransformer() => _instance ??= const RegisterRequestOneOfProfileConsentEnumTypeTransformer._();

  const RegisterRequestOneOfProfileConsentEnumTypeTransformer._();

  bool encode(RegisterRequestOneOfProfileConsentEnum data) => data._value;

  /// Returns the instance of [RegisterRequestOneOfProfileConsentEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestOneOfProfileConsentEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestOneOfProfileConsentEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case 'true': return RegisterRequestOneOfProfileConsentEnum.true_;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestOneOfProfileConsentEnumTypeTransformer? _instance;
}


