//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverAssignmentAuto {
  /// Returns a new [DriverAssignmentAuto] instance.
  DriverAssignmentAuto({
    required this.id,
    required this.registrationNumber,
  });

  String id;

  String registrationNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverAssignmentAuto &&
    other.id == id &&
    other.registrationNumber == registrationNumber;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (registrationNumber.hashCode);

  @override
  String toString() => 'DriverAssignmentAuto[id=$id, registrationNumber=$registrationNumber]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'registrationNumber'] = this.registrationNumber;
    return json;
  }

  /// Returns a new [DriverAssignmentAuto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverAssignmentAuto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "DriverAssignmentAuto[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "DriverAssignmentAuto[id]" has a null value in JSON.');
        assert(json.containsKey(r'registrationNumber'), 'Required key "DriverAssignmentAuto[registrationNumber]" is missing from JSON.');
        assert(json[r'registrationNumber'] != null, 'Required key "DriverAssignmentAuto[registrationNumber]" has a null value in JSON.');
        return true;
      }());

      return DriverAssignmentAuto(
        id: mapValueOfType<String>(json, r'id')!,
        registrationNumber: mapValueOfType<String>(json, r'registrationNumber')!,
      );
    }
    return null;
  }

  static List<DriverAssignmentAuto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentAuto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentAuto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverAssignmentAuto> mapFromJson(dynamic json) {
    final map = <String, DriverAssignmentAuto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverAssignmentAuto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverAssignmentAuto-objects as value to a dart map
  static Map<String, List<DriverAssignmentAuto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverAssignmentAuto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverAssignmentAuto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'registrationNumber',
  };
}

