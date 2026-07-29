//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LoginRequestAnyOf {
  /// Returns a new [LoginRequestAnyOf] instance.
  LoginRequestAnyOf({
    required this.phone,
    required this.password,
    this.deviceId,
  });

  String phone;

  String password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? deviceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LoginRequestAnyOf &&
    other.phone == phone &&
    other.password == password &&
    other.deviceId == deviceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (phone.hashCode) +
    (password.hashCode) +
    (deviceId == null ? 0 : deviceId!.hashCode);

  @override
  String toString() => 'LoginRequestAnyOf[phone=$phone, password=$password, deviceId=$deviceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'phone'] = this.phone;
      json[r'password'] = this.password;
    if (this.deviceId != null) {
      json[r'deviceId'] = this.deviceId;
    } else {
      json[r'deviceId'] = null;
    }
    return json;
  }

  /// Returns a new [LoginRequestAnyOf] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoginRequestAnyOf? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'phone'), 'Required key "LoginRequestAnyOf[phone]" is missing from JSON.');
        assert(json[r'phone'] != null, 'Required key "LoginRequestAnyOf[phone]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "LoginRequestAnyOf[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "LoginRequestAnyOf[password]" has a null value in JSON.');
        return true;
      }());

      return LoginRequestAnyOf(
        phone: mapValueOfType<String>(json, r'phone')!,
        password: mapValueOfType<String>(json, r'password')!,
        deviceId: mapValueOfType<String>(json, r'deviceId'),
      );
    }
    return null;
  }

  static List<LoginRequestAnyOf> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoginRequestAnyOf>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoginRequestAnyOf.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoginRequestAnyOf> mapFromJson(dynamic json) {
    final map = <String, LoginRequestAnyOf>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoginRequestAnyOf.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoginRequestAnyOf-objects as value to a dart map
  static Map<String, List<LoginRequestAnyOf>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LoginRequestAnyOf>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoginRequestAnyOf.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'phone',
    'password',
  };
}

