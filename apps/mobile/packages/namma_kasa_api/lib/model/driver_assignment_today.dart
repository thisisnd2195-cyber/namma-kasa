//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverAssignmentToday {
  /// Returns a new [DriverAssignmentToday] instance.
  DriverAssignmentToday({
    this.wasteTypes = const [],
    required this.passesTotal,
    required this.passesCompleted,
    required this.nextPassNumber,
    required this.isCollectionDay,
  });

  List<DriverAssignmentTodayWasteTypesEnum> wasteTypes;

  int passesTotal;

  int passesCompleted;

  int? nextPassNumber;

  bool isCollectionDay;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverAssignmentToday &&
    _deepEquality.equals(other.wasteTypes, wasteTypes) &&
    other.passesTotal == passesTotal &&
    other.passesCompleted == passesCompleted &&
    other.nextPassNumber == nextPassNumber &&
    other.isCollectionDay == isCollectionDay;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (wasteTypes.hashCode) +
    (passesTotal.hashCode) +
    (passesCompleted.hashCode) +
    (nextPassNumber == null ? 0 : nextPassNumber!.hashCode) +
    (isCollectionDay.hashCode);

  @override
  String toString() => 'DriverAssignmentToday[wasteTypes=$wasteTypes, passesTotal=$passesTotal, passesCompleted=$passesCompleted, nextPassNumber=$nextPassNumber, isCollectionDay=$isCollectionDay]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'wasteTypes'] = this.wasteTypes;
      json[r'passesTotal'] = this.passesTotal;
      json[r'passesCompleted'] = this.passesCompleted;
    if (this.nextPassNumber != null) {
      json[r'nextPassNumber'] = this.nextPassNumber;
    } else {
      json[r'nextPassNumber'] = null;
    }
      json[r'isCollectionDay'] = this.isCollectionDay;
    return json;
  }

  /// Returns a new [DriverAssignmentToday] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverAssignmentToday? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'wasteTypes'), 'Required key "DriverAssignmentToday[wasteTypes]" is missing from JSON.');
        assert(json[r'wasteTypes'] != null, 'Required key "DriverAssignmentToday[wasteTypes]" has a null value in JSON.');
        assert(json.containsKey(r'passesTotal'), 'Required key "DriverAssignmentToday[passesTotal]" is missing from JSON.');
        assert(json[r'passesTotal'] != null, 'Required key "DriverAssignmentToday[passesTotal]" has a null value in JSON.');
        assert(json.containsKey(r'passesCompleted'), 'Required key "DriverAssignmentToday[passesCompleted]" is missing from JSON.');
        assert(json[r'passesCompleted'] != null, 'Required key "DriverAssignmentToday[passesCompleted]" has a null value in JSON.');
        assert(json.containsKey(r'nextPassNumber'), 'Required key "DriverAssignmentToday[nextPassNumber]" is missing from JSON.');
        assert(json.containsKey(r'isCollectionDay'), 'Required key "DriverAssignmentToday[isCollectionDay]" is missing from JSON.');
        assert(json[r'isCollectionDay'] != null, 'Required key "DriverAssignmentToday[isCollectionDay]" has a null value in JSON.');
        return true;
      }());

      return DriverAssignmentToday(
        wasteTypes: DriverAssignmentTodayWasteTypesEnum.listFromJson(json[r'wasteTypes']),
        passesTotal: mapValueOfType<int>(json, r'passesTotal')!,
        passesCompleted: mapValueOfType<int>(json, r'passesCompleted')!,
        nextPassNumber: mapValueOfType<int>(json, r'nextPassNumber'),
        isCollectionDay: mapValueOfType<bool>(json, r'isCollectionDay')!,
      );
    }
    return null;
  }

  static List<DriverAssignmentToday> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentToday>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentToday.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverAssignmentToday> mapFromJson(dynamic json) {
    final map = <String, DriverAssignmentToday>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverAssignmentToday.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverAssignmentToday-objects as value to a dart map
  static Map<String, List<DriverAssignmentToday>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverAssignmentToday>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverAssignmentToday.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'wasteTypes',
    'passesTotal',
    'passesCompleted',
    'nextPassNumber',
    'isCollectionDay',
  };
}


enum DriverAssignmentTodayWasteTypesEnum {
  wet._(r'wet'),
  dry._(r'dry'),
  sanitary._(r'sanitary'),
  hazardous._(r'hazardous'),
  ewaste._(r'ewaste'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverAssignmentTodayWasteTypesEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverAssignmentTodayWasteTypesEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverAssignmentTodayWasteTypesEnum? fromJson(dynamic value) => DriverAssignmentTodayWasteTypesEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverAssignmentTodayWasteTypesEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverAssignmentTodayWasteTypesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentTodayWasteTypesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentTodayWasteTypesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverAssignmentTodayWasteTypesEnum] to String,
/// and [decode] dynamic data back to [DriverAssignmentTodayWasteTypesEnum].
class DriverAssignmentTodayWasteTypesEnumTypeTransformer {
  factory DriverAssignmentTodayWasteTypesEnumTypeTransformer() => _instance ??= const DriverAssignmentTodayWasteTypesEnumTypeTransformer._();

  const DriverAssignmentTodayWasteTypesEnumTypeTransformer._();

  String encode(DriverAssignmentTodayWasteTypesEnum data) => data._value;

  /// Returns the instance of [DriverAssignmentTodayWasteTypesEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverAssignmentTodayWasteTypesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverAssignmentTodayWasteTypesEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'wet': return DriverAssignmentTodayWasteTypesEnum.wet;
        case r'dry': return DriverAssignmentTodayWasteTypesEnum.dry;
        case r'sanitary': return DriverAssignmentTodayWasteTypesEnum.sanitary;
        case r'hazardous': return DriverAssignmentTodayWasteTypesEnum.hazardous;
        case r'ewaste': return DriverAssignmentTodayWasteTypesEnum.ewaste;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverAssignmentTodayWasteTypesEnumTypeTransformer? _instance;
}


