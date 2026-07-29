//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdMqttTokenPost201Response {
  /// Returns a new [DriverTripsIdMqttTokenPost201Response] instance.
  DriverTripsIdMqttTokenPost201Response({
    required this.username,
    required this.password,
    required this.expiresInSec,
  });

  String username;

  String password;

  int expiresInSec;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdMqttTokenPost201Response &&
    other.username == username &&
    other.password == password &&
    other.expiresInSec == expiresInSec;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (username.hashCode) +
    (password.hashCode) +
    (expiresInSec.hashCode);

  @override
  String toString() => 'DriverTripsIdMqttTokenPost201Response[username=$username, password=$password, expiresInSec=$expiresInSec]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'username'] = this.username;
      json[r'password'] = this.password;
      json[r'expiresInSec'] = this.expiresInSec;
    return json;
  }

  /// Returns a new [DriverTripsIdMqttTokenPost201Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdMqttTokenPost201Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'username'), 'Required key "DriverTripsIdMqttTokenPost201Response[username]" is missing from JSON.');
        assert(json[r'username'] != null, 'Required key "DriverTripsIdMqttTokenPost201Response[username]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "DriverTripsIdMqttTokenPost201Response[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "DriverTripsIdMqttTokenPost201Response[password]" has a null value in JSON.');
        assert(json.containsKey(r'expiresInSec'), 'Required key "DriverTripsIdMqttTokenPost201Response[expiresInSec]" is missing from JSON.');
        assert(json[r'expiresInSec'] != null, 'Required key "DriverTripsIdMqttTokenPost201Response[expiresInSec]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdMqttTokenPost201Response(
        username: mapValueOfType<String>(json, r'username')!,
        password: mapValueOfType<String>(json, r'password')!,
        expiresInSec: mapValueOfType<int>(json, r'expiresInSec')!,
      );
    }
    return null;
  }

  static List<DriverTripsIdMqttTokenPost201Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdMqttTokenPost201Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdMqttTokenPost201Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdMqttTokenPost201Response> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdMqttTokenPost201Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdMqttTokenPost201Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdMqttTokenPost201Response-objects as value to a dart map
  static Map<String, List<DriverTripsIdMqttTokenPost201Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdMqttTokenPost201Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdMqttTokenPost201Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'username',
    'password',
    'expiresInSec',
  };
}

