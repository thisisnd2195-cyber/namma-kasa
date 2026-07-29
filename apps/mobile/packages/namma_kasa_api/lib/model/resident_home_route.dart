//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentHomeRoute {
  /// Returns a new [ResidentHomeRoute] instance.
  ResidentHomeRoute({
    required this.id,
    required this.name,
    required this.windowStart,
    required this.windowEnd,
    required this.passesPerDay,
    this.todayWasteTypes = const [],
    required this.isCollectionDay,
  });

  String id;

  String name;

  String windowStart;

  String windowEnd;

  int passesPerDay;

  List<ResidentHomeRouteTodayWasteTypesEnum> todayWasteTypes;

  bool isCollectionDay;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentHomeRoute &&
    other.id == id &&
    other.name == name &&
    other.windowStart == windowStart &&
    other.windowEnd == windowEnd &&
    other.passesPerDay == passesPerDay &&
    _deepEquality.equals(other.todayWasteTypes, todayWasteTypes) &&
    other.isCollectionDay == isCollectionDay;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (windowStart.hashCode) +
    (windowEnd.hashCode) +
    (passesPerDay.hashCode) +
    (todayWasteTypes.hashCode) +
    (isCollectionDay.hashCode);

  @override
  String toString() => 'ResidentHomeRoute[id=$id, name=$name, windowStart=$windowStart, windowEnd=$windowEnd, passesPerDay=$passesPerDay, todayWasteTypes=$todayWasteTypes, isCollectionDay=$isCollectionDay]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'windowStart'] = this.windowStart;
      json[r'windowEnd'] = this.windowEnd;
      json[r'passesPerDay'] = this.passesPerDay;
      json[r'todayWasteTypes'] = this.todayWasteTypes;
      json[r'isCollectionDay'] = this.isCollectionDay;
    return json;
  }

  /// Returns a new [ResidentHomeRoute] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentHomeRoute? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "ResidentHomeRoute[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "ResidentHomeRoute[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "ResidentHomeRoute[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "ResidentHomeRoute[name]" has a null value in JSON.');
        assert(json.containsKey(r'windowStart'), 'Required key "ResidentHomeRoute[windowStart]" is missing from JSON.');
        assert(json[r'windowStart'] != null, 'Required key "ResidentHomeRoute[windowStart]" has a null value in JSON.');
        assert(json.containsKey(r'windowEnd'), 'Required key "ResidentHomeRoute[windowEnd]" is missing from JSON.');
        assert(json[r'windowEnd'] != null, 'Required key "ResidentHomeRoute[windowEnd]" has a null value in JSON.');
        assert(json.containsKey(r'passesPerDay'), 'Required key "ResidentHomeRoute[passesPerDay]" is missing from JSON.');
        assert(json[r'passesPerDay'] != null, 'Required key "ResidentHomeRoute[passesPerDay]" has a null value in JSON.');
        assert(json.containsKey(r'todayWasteTypes'), 'Required key "ResidentHomeRoute[todayWasteTypes]" is missing from JSON.');
        assert(json[r'todayWasteTypes'] != null, 'Required key "ResidentHomeRoute[todayWasteTypes]" has a null value in JSON.');
        assert(json.containsKey(r'isCollectionDay'), 'Required key "ResidentHomeRoute[isCollectionDay]" is missing from JSON.');
        assert(json[r'isCollectionDay'] != null, 'Required key "ResidentHomeRoute[isCollectionDay]" has a null value in JSON.');
        return true;
      }());

      return ResidentHomeRoute(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        windowStart: mapValueOfType<String>(json, r'windowStart')!,
        windowEnd: mapValueOfType<String>(json, r'windowEnd')!,
        passesPerDay: mapValueOfType<int>(json, r'passesPerDay')!,
        todayWasteTypes: ResidentHomeRouteTodayWasteTypesEnum.listFromJson(json[r'todayWasteTypes']),
        isCollectionDay: mapValueOfType<bool>(json, r'isCollectionDay')!,
      );
    }
    return null;
  }

  static List<ResidentHomeRoute> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentHomeRoute>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentHomeRoute.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentHomeRoute> mapFromJson(dynamic json) {
    final map = <String, ResidentHomeRoute>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentHomeRoute.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentHomeRoute-objects as value to a dart map
  static Map<String, List<ResidentHomeRoute>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentHomeRoute>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentHomeRoute.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'windowStart',
    'windowEnd',
    'passesPerDay',
    'todayWasteTypes',
    'isCollectionDay',
  };
}


enum ResidentHomeRouteTodayWasteTypesEnum {
  wet._(r'wet'),
  dry._(r'dry'),
  sanitary._(r'sanitary'),
  hazardous._(r'hazardous'),
  ewaste._(r'ewaste'),
  ;

  /// Instantiate a new enum with the provided value.
  const ResidentHomeRouteTodayWasteTypesEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ResidentHomeRouteTodayWasteTypesEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ResidentHomeRouteTodayWasteTypesEnum? fromJson(dynamic value) => ResidentHomeRouteTodayWasteTypesEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ResidentHomeRouteTodayWasteTypesEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ResidentHomeRouteTodayWasteTypesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentHomeRouteTodayWasteTypesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentHomeRouteTodayWasteTypesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ResidentHomeRouteTodayWasteTypesEnum] to String,
/// and [decode] dynamic data back to [ResidentHomeRouteTodayWasteTypesEnum].
class ResidentHomeRouteTodayWasteTypesEnumTypeTransformer {
  factory ResidentHomeRouteTodayWasteTypesEnumTypeTransformer() => _instance ??= const ResidentHomeRouteTodayWasteTypesEnumTypeTransformer._();

  const ResidentHomeRouteTodayWasteTypesEnumTypeTransformer._();

  String encode(ResidentHomeRouteTodayWasteTypesEnum data) => data._value;

  /// Returns the instance of [ResidentHomeRouteTodayWasteTypesEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ResidentHomeRouteTodayWasteTypesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ResidentHomeRouteTodayWasteTypesEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'wet': return ResidentHomeRouteTodayWasteTypesEnum.wet;
        case r'dry': return ResidentHomeRouteTodayWasteTypesEnum.dry;
        case r'sanitary': return ResidentHomeRouteTodayWasteTypesEnum.sanitary;
        case r'hazardous': return ResidentHomeRouteTodayWasteTypesEnum.hazardous;
        case r'ewaste': return ResidentHomeRouteTodayWasteTypesEnum.ewaste;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ResidentHomeRouteTodayWasteTypesEnumTypeTransformer? _instance;
}


