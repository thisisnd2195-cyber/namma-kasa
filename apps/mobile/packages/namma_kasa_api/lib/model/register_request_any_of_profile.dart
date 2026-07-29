//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequestAnyOfProfile {
  /// Returns a new [RegisterRequestAnyOfProfile] instance.
  RegisterRequestAnyOfProfile({
    required this.fullName,
    required this.addressLine,
    this.landmark,
    required this.pin,
    this.locale,
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

  RegisterRequestAnyOfProfilePin pin;

  RegisterRequestAnyOfProfileLocaleEnum? locale;

  bool consent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequestAnyOfProfile &&
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
    (locale == null ? 0 : locale!.hashCode) +
    (consent.hashCode);

  @override
  String toString() => 'RegisterRequestAnyOfProfile[fullName=$fullName, addressLine=$addressLine, landmark=$landmark, pin=$pin, locale=$locale, consent=$consent]';

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
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
      json[r'consent'] = this.consent;
    return json;
  }

  /// Returns a new [RegisterRequestAnyOfProfile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequestAnyOfProfile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fullName'), 'Required key "RegisterRequestAnyOfProfile[fullName]" is missing from JSON.');
        assert(json[r'fullName'] != null, 'Required key "RegisterRequestAnyOfProfile[fullName]" has a null value in JSON.');
        assert(json.containsKey(r'addressLine'), 'Required key "RegisterRequestAnyOfProfile[addressLine]" is missing from JSON.');
        assert(json[r'addressLine'] != null, 'Required key "RegisterRequestAnyOfProfile[addressLine]" has a null value in JSON.');
        assert(json.containsKey(r'pin'), 'Required key "RegisterRequestAnyOfProfile[pin]" is missing from JSON.');
        assert(json[r'pin'] != null, 'Required key "RegisterRequestAnyOfProfile[pin]" has a null value in JSON.');
        assert(json.containsKey(r'consent'), 'Required key "RegisterRequestAnyOfProfile[consent]" is missing from JSON.');
        assert(json[r'consent'] != null, 'Required key "RegisterRequestAnyOfProfile[consent]" has a null value in JSON.');
        return true;
      }());

      return RegisterRequestAnyOfProfile(
        fullName: mapValueOfType<String>(json, r'fullName')!,
        addressLine: mapValueOfType<String>(json, r'addressLine')!,
        landmark: mapValueOfType<String>(json, r'landmark'),
        pin: RegisterRequestAnyOfProfilePin.fromJson(json[r'pin'])!,
        locale: RegisterRequestAnyOfProfileLocaleEnum.fromJson(json[r'locale']),
        consent: mapValueOfType<bool>(json, r'consent')!,
      );
    }
    return null;
  }

  static List<RegisterRequestAnyOfProfile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestAnyOfProfile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestAnyOfProfile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequestAnyOfProfile> mapFromJson(dynamic json) {
    final map = <String, RegisterRequestAnyOfProfile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequestAnyOfProfile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequestAnyOfProfile-objects as value to a dart map
  static Map<String, List<RegisterRequestAnyOfProfile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequestAnyOfProfile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequestAnyOfProfile.listFromJson(entry.value, growable: growable,);
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


enum RegisterRequestAnyOfProfileLocaleEnum {
  en._(r'en'),
  kn._(r'kn'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterRequestAnyOfProfileLocaleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterRequestAnyOfProfileLocaleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterRequestAnyOfProfileLocaleEnum? fromJson(dynamic value) => RegisterRequestAnyOfProfileLocaleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterRequestAnyOfProfileLocaleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterRequestAnyOfProfileLocaleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestAnyOfProfileLocaleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestAnyOfProfileLocaleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestAnyOfProfileLocaleEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestAnyOfProfileLocaleEnum].
class RegisterRequestAnyOfProfileLocaleEnumTypeTransformer {
  factory RegisterRequestAnyOfProfileLocaleEnumTypeTransformer() => _instance ??= const RegisterRequestAnyOfProfileLocaleEnumTypeTransformer._();

  const RegisterRequestAnyOfProfileLocaleEnumTypeTransformer._();

  String encode(RegisterRequestAnyOfProfileLocaleEnum data) => data._value;

  /// Returns the instance of [RegisterRequestAnyOfProfileLocaleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestAnyOfProfileLocaleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterRequestAnyOfProfileLocaleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'en': return RegisterRequestAnyOfProfileLocaleEnum.en;
        case r'kn': return RegisterRequestAnyOfProfileLocaleEnum.kn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterRequestAnyOfProfileLocaleEnumTypeTransformer? _instance;
}


