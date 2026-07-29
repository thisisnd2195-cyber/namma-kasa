//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdPingsPost202Response {
  /// Returns a new [DriverTripsIdPingsPost202Response] instance.
  DriverTripsIdPingsPost202Response({
    required this.accepted,
    required this.rejected,
  });

  int accepted;

  int rejected;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdPingsPost202Response &&
    other.accepted == accepted &&
    other.rejected == rejected;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accepted.hashCode) +
    (rejected.hashCode);

  @override
  String toString() => 'DriverTripsIdPingsPost202Response[accepted=$accepted, rejected=$rejected]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accepted'] = this.accepted;
      json[r'rejected'] = this.rejected;
    return json;
  }

  /// Returns a new [DriverTripsIdPingsPost202Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdPingsPost202Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accepted'), 'Required key "DriverTripsIdPingsPost202Response[accepted]" is missing from JSON.');
        assert(json[r'accepted'] != null, 'Required key "DriverTripsIdPingsPost202Response[accepted]" has a null value in JSON.');
        assert(json.containsKey(r'rejected'), 'Required key "DriverTripsIdPingsPost202Response[rejected]" is missing from JSON.');
        assert(json[r'rejected'] != null, 'Required key "DriverTripsIdPingsPost202Response[rejected]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdPingsPost202Response(
        accepted: mapValueOfType<int>(json, r'accepted')!,
        rejected: mapValueOfType<int>(json, r'rejected')!,
      );
    }
    return null;
  }

  static List<DriverTripsIdPingsPost202Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdPingsPost202Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdPingsPost202Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdPingsPost202Response> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdPingsPost202Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdPingsPost202Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdPingsPost202Response-objects as value to a dart map
  static Map<String, List<DriverTripsIdPingsPost202Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdPingsPost202Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdPingsPost202Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accepted',
    'rejected',
  };
}

