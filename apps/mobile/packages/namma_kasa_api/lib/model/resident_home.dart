//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentHome {
  /// Returns a new [ResidentHome] instance.
  ResidentHome({
    required this.household,
    required this.route,
    this.servingAutos = const [],
    required this.currentPass,
    required this.lastCollectedAt,
    required this.canRateToday,
    required this.missedToday,
  });

  Household household;

  ResidentHomeRoute? route;

  List<ResidentHomeServingAutosInner> servingAutos;

  int? currentPass;

  String? lastCollectedAt;

  bool canRateToday;

  bool missedToday;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentHome &&
    other.household == household &&
    other.route == route &&
    _deepEquality.equals(other.servingAutos, servingAutos) &&
    other.currentPass == currentPass &&
    other.lastCollectedAt == lastCollectedAt &&
    other.canRateToday == canRateToday &&
    other.missedToday == missedToday;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (household.hashCode) +
    (route == null ? 0 : route!.hashCode) +
    (servingAutos.hashCode) +
    (currentPass == null ? 0 : currentPass!.hashCode) +
    (lastCollectedAt == null ? 0 : lastCollectedAt!.hashCode) +
    (canRateToday.hashCode) +
    (missedToday.hashCode);

  @override
  String toString() => 'ResidentHome[household=$household, route=$route, servingAutos=$servingAutos, currentPass=$currentPass, lastCollectedAt=$lastCollectedAt, canRateToday=$canRateToday, missedToday=$missedToday]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'household'] = this.household;
    if (this.route != null) {
      json[r'route'] = this.route;
    } else {
      json[r'route'] = null;
    }
      json[r'servingAutos'] = this.servingAutos;
    if (this.currentPass != null) {
      json[r'currentPass'] = this.currentPass;
    } else {
      json[r'currentPass'] = null;
    }
    if (this.lastCollectedAt != null) {
      json[r'lastCollectedAt'] = this.lastCollectedAt;
    } else {
      json[r'lastCollectedAt'] = null;
    }
      json[r'canRateToday'] = this.canRateToday;
      json[r'missedToday'] = this.missedToday;
    return json;
  }

  /// Returns a new [ResidentHome] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentHome? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'household'), 'Required key "ResidentHome[household]" is missing from JSON.');
        assert(json[r'household'] != null, 'Required key "ResidentHome[household]" has a null value in JSON.');
        assert(json.containsKey(r'route'), 'Required key "ResidentHome[route]" is missing from JSON.');
        assert(json.containsKey(r'servingAutos'), 'Required key "ResidentHome[servingAutos]" is missing from JSON.');
        assert(json[r'servingAutos'] != null, 'Required key "ResidentHome[servingAutos]" has a null value in JSON.');
        assert(json.containsKey(r'currentPass'), 'Required key "ResidentHome[currentPass]" is missing from JSON.');
        assert(json.containsKey(r'lastCollectedAt'), 'Required key "ResidentHome[lastCollectedAt]" is missing from JSON.');
        assert(json.containsKey(r'canRateToday'), 'Required key "ResidentHome[canRateToday]" is missing from JSON.');
        assert(json[r'canRateToday'] != null, 'Required key "ResidentHome[canRateToday]" has a null value in JSON.');
        assert(json.containsKey(r'missedToday'), 'Required key "ResidentHome[missedToday]" is missing from JSON.');
        assert(json[r'missedToday'] != null, 'Required key "ResidentHome[missedToday]" has a null value in JSON.');
        return true;
      }());

      return ResidentHome(
        household: Household.fromJson(json[r'household'])!,
        route: ResidentHomeRoute.fromJson(json[r'route']),
        servingAutos: ResidentHomeServingAutosInner.listFromJson(json[r'servingAutos']),
        currentPass: mapValueOfType<int>(json, r'currentPass'),
        lastCollectedAt: mapValueOfType<String>(json, r'lastCollectedAt'),
        canRateToday: mapValueOfType<bool>(json, r'canRateToday')!,
        missedToday: mapValueOfType<bool>(json, r'missedToday')!,
      );
    }
    return null;
  }

  static List<ResidentHome> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentHome>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentHome.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentHome> mapFromJson(dynamic json) {
    final map = <String, ResidentHome>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentHome.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentHome-objects as value to a dart map
  static Map<String, List<ResidentHome>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentHome>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentHome.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'household',
    'route',
    'servingAutos',
    'currentPass',
    'lastCollectedAt',
    'canRateToday',
    'missedToday',
  };
}

