//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsPostRequest {
  /// Returns a new [DriverTripsPostRequest] instance.
  DriverTripsPostRequest({
    required this.passNumber,
  });

  /// Minimum value: 1
  int passNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsPostRequest &&
    other.passNumber == passNumber;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (passNumber.hashCode);

  @override
  String toString() => 'DriverTripsPostRequest[passNumber=$passNumber]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'passNumber'] = this.passNumber;
    return json;
  }

  /// Returns a new [DriverTripsPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'passNumber'), 'Required key "DriverTripsPostRequest[passNumber]" is missing from JSON.');
        assert(json[r'passNumber'] != null, 'Required key "DriverTripsPostRequest[passNumber]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsPostRequest(
        passNumber: mapValueOfType<int>(json, r'passNumber')!,
      );
    }
    return null;
  }

  static List<DriverTripsPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsPostRequest> mapFromJson(dynamic json) {
    final map = <String, DriverTripsPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsPostRequest-objects as value to a dart map
  static Map<String, List<DriverTripsPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'passNumber',
  };
}

