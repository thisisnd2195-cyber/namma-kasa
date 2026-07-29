//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverAssignment {
  /// Returns a new [DriverAssignment] instance.
  DriverAssignment({
    required this.auto,
    required this.route,
    required this.today,
    required this.activeTrip,
  });

  DriverAssignmentAuto auto;

  DriverAssignmentRoute route;

  DriverAssignmentToday today;

  Trip? activeTrip;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverAssignment &&
    other.auto == auto &&
    other.route == route &&
    other.today == today &&
    other.activeTrip == activeTrip;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (auto.hashCode) +
    (route.hashCode) +
    (today.hashCode) +
    (activeTrip == null ? 0 : activeTrip!.hashCode);

  @override
  String toString() => 'DriverAssignment[auto=$auto, route=$route, today=$today, activeTrip=$activeTrip]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'auto'] = this.auto;
      json[r'route'] = this.route;
      json[r'today'] = this.today;
    if (this.activeTrip != null) {
      json[r'activeTrip'] = this.activeTrip;
    } else {
      json[r'activeTrip'] = null;
    }
    return json;
  }

  /// Returns a new [DriverAssignment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverAssignment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'auto'), 'Required key "DriverAssignment[auto]" is missing from JSON.');
        assert(json[r'auto'] != null, 'Required key "DriverAssignment[auto]" has a null value in JSON.');
        assert(json.containsKey(r'route'), 'Required key "DriverAssignment[route]" is missing from JSON.');
        assert(json[r'route'] != null, 'Required key "DriverAssignment[route]" has a null value in JSON.');
        assert(json.containsKey(r'today'), 'Required key "DriverAssignment[today]" is missing from JSON.');
        assert(json[r'today'] != null, 'Required key "DriverAssignment[today]" has a null value in JSON.');
        assert(json.containsKey(r'activeTrip'), 'Required key "DriverAssignment[activeTrip]" is missing from JSON.');
        return true;
      }());

      return DriverAssignment(
        auto: DriverAssignmentAuto.fromJson(json[r'auto'])!,
        route: DriverAssignmentRoute.fromJson(json[r'route'])!,
        today: DriverAssignmentToday.fromJson(json[r'today'])!,
        activeTrip: Trip.fromJson(json[r'activeTrip']),
      );
    }
    return null;
  }

  static List<DriverAssignment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverAssignment> mapFromJson(dynamic json) {
    final map = <String, DriverAssignment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverAssignment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverAssignment-objects as value to a dart map
  static Map<String, List<DriverAssignment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverAssignment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverAssignment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'auto',
    'route',
    'today',
    'activeTrip',
  };
}

