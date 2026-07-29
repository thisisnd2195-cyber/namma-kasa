//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentHouseholdPatchRequestPin {
  /// Returns a new [ResidentHouseholdPatchRequestPin] instance.
  ResidentHouseholdPatchRequestPin({
    required this.lat,
    required this.lng,
  });

  /// Minimum value: 12.7
  /// Maximum value: 13.25
  num lat;

  /// Minimum value: 77.3
  /// Maximum value: 77.9
  num lng;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentHouseholdPatchRequestPin &&
    other.lat == lat &&
    other.lng == lng;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lat.hashCode) +
    (lng.hashCode);

  @override
  String toString() => 'ResidentHouseholdPatchRequestPin[lat=$lat, lng=$lng]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    return json;
  }

  /// Returns a new [ResidentHouseholdPatchRequestPin] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentHouseholdPatchRequestPin? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'lat'), 'Required key "ResidentHouseholdPatchRequestPin[lat]" is missing from JSON.');
        assert(json[r'lat'] != null, 'Required key "ResidentHouseholdPatchRequestPin[lat]" has a null value in JSON.');
        assert(json.containsKey(r'lng'), 'Required key "ResidentHouseholdPatchRequestPin[lng]" is missing from JSON.');
        assert(json[r'lng'] != null, 'Required key "ResidentHouseholdPatchRequestPin[lng]" has a null value in JSON.');
        return true;
      }());

      return ResidentHouseholdPatchRequestPin(
        lat: num.parse('${json[r'lat']}'),
        lng: num.parse('${json[r'lng']}'),
      );
    }
    return null;
  }

  static List<ResidentHouseholdPatchRequestPin> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentHouseholdPatchRequestPin>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentHouseholdPatchRequestPin.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentHouseholdPatchRequestPin> mapFromJson(dynamic json) {
    final map = <String, ResidentHouseholdPatchRequestPin>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentHouseholdPatchRequestPin.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentHouseholdPatchRequestPin-objects as value to a dart map
  static Map<String, List<ResidentHouseholdPatchRequestPin>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentHouseholdPatchRequestPin>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentHouseholdPatchRequestPin.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lat',
    'lng',
  };
}

