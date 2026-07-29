//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverAssignmentRoute {
  /// Returns a new [DriverAssignmentRoute] instance.
  DriverAssignmentRoute({
    required this.id,
    required this.name,
    required this.routeCode,
    this.serviceableArea,
    required this.windowStart,
    required this.windowEnd,
    this.collectionDays = const [],
  });

  String id;

  String name;

  String routeCode;

  Object? serviceableArea;

  String windowStart;

  String windowEnd;

  List<int> collectionDays;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverAssignmentRoute &&
    other.id == id &&
    other.name == name &&
    other.routeCode == routeCode &&
    other.serviceableArea == serviceableArea &&
    other.windowStart == windowStart &&
    other.windowEnd == windowEnd &&
    _deepEquality.equals(other.collectionDays, collectionDays);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (routeCode.hashCode) +
    (serviceableArea == null ? 0 : serviceableArea!.hashCode) +
    (windowStart.hashCode) +
    (windowEnd.hashCode) +
    (collectionDays.hashCode);

  @override
  String toString() => 'DriverAssignmentRoute[id=$id, name=$name, routeCode=$routeCode, serviceableArea=$serviceableArea, windowStart=$windowStart, windowEnd=$windowEnd, collectionDays=$collectionDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'routeCode'] = this.routeCode;
    if (this.serviceableArea != null) {
      json[r'serviceableArea'] = this.serviceableArea;
    } else {
      json[r'serviceableArea'] = null;
    }
      json[r'windowStart'] = this.windowStart;
      json[r'windowEnd'] = this.windowEnd;
      json[r'collectionDays'] = this.collectionDays;
    return json;
  }

  /// Returns a new [DriverAssignmentRoute] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverAssignmentRoute? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "DriverAssignmentRoute[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "DriverAssignmentRoute[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "DriverAssignmentRoute[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "DriverAssignmentRoute[name]" has a null value in JSON.');
        assert(json.containsKey(r'routeCode'), 'Required key "DriverAssignmentRoute[routeCode]" is missing from JSON.');
        assert(json[r'routeCode'] != null, 'Required key "DriverAssignmentRoute[routeCode]" has a null value in JSON.');
        assert(json.containsKey(r'windowStart'), 'Required key "DriverAssignmentRoute[windowStart]" is missing from JSON.');
        assert(json[r'windowStart'] != null, 'Required key "DriverAssignmentRoute[windowStart]" has a null value in JSON.');
        assert(json.containsKey(r'windowEnd'), 'Required key "DriverAssignmentRoute[windowEnd]" is missing from JSON.');
        assert(json[r'windowEnd'] != null, 'Required key "DriverAssignmentRoute[windowEnd]" has a null value in JSON.');
        assert(json.containsKey(r'collectionDays'), 'Required key "DriverAssignmentRoute[collectionDays]" is missing from JSON.');
        assert(json[r'collectionDays'] != null, 'Required key "DriverAssignmentRoute[collectionDays]" has a null value in JSON.');
        return true;
      }());

      return DriverAssignmentRoute(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        routeCode: mapValueOfType<String>(json, r'routeCode')!,
        serviceableArea: mapValueOfType<Object>(json, r'serviceableArea'),
        windowStart: mapValueOfType<String>(json, r'windowStart')!,
        windowEnd: mapValueOfType<String>(json, r'windowEnd')!,
        collectionDays: json[r'collectionDays'] is Iterable
            ? (json[r'collectionDays'] as Iterable).cast<int>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<DriverAssignmentRoute> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentRoute>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentRoute.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverAssignmentRoute> mapFromJson(dynamic json) {
    final map = <String, DriverAssignmentRoute>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverAssignmentRoute.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverAssignmentRoute-objects as value to a dart map
  static Map<String, List<DriverAssignmentRoute>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverAssignmentRoute>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverAssignmentRoute.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'routeCode',
    'windowStart',
    'windowEnd',
    'collectionDays',
  };
}

