//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverIssueRecord {
  /// Returns a new [DriverIssueRecord] instance.
  DriverIssueRecord({
    required this.id,
    required this.kind,
    required this.note,
    required this.routeId,
    this.driverName,
    required this.acknowledgedAt,
    required this.createdAt,
  });

  String id;

  DriverIssueRecordKindEnum kind;

  String? note;

  String? routeId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverName;

  String? acknowledgedAt;

  String createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverIssueRecord &&
    other.id == id &&
    other.kind == kind &&
    other.note == note &&
    other.routeId == routeId &&
    other.driverName == driverName &&
    other.acknowledgedAt == acknowledgedAt &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (routeId == null ? 0 : routeId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (acknowledgedAt == null ? 0 : acknowledgedAt!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'DriverIssueRecord[id=$id, kind=$kind, note=$note, routeId=$routeId, driverName=$driverName, acknowledgedAt=$acknowledgedAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.routeId != null) {
      json[r'routeId'] = this.routeId;
    } else {
      json[r'routeId'] = null;
    }
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.acknowledgedAt != null) {
      json[r'acknowledgedAt'] = this.acknowledgedAt;
    } else {
      json[r'acknowledgedAt'] = null;
    }
      json[r'createdAt'] = this.createdAt;
    return json;
  }

  /// Returns a new [DriverIssueRecord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverIssueRecord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "DriverIssueRecord[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "DriverIssueRecord[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "DriverIssueRecord[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "DriverIssueRecord[kind]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "DriverIssueRecord[note]" is missing from JSON.');
        assert(json.containsKey(r'routeId'), 'Required key "DriverIssueRecord[routeId]" is missing from JSON.');
        assert(json.containsKey(r'acknowledgedAt'), 'Required key "DriverIssueRecord[acknowledgedAt]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "DriverIssueRecord[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "DriverIssueRecord[createdAt]" has a null value in JSON.');
        return true;
      }());

      return DriverIssueRecord(
        id: mapValueOfType<String>(json, r'id')!,
        kind: DriverIssueRecordKindEnum.fromJson(json[r'kind'])!,
        note: mapValueOfType<String>(json, r'note'),
        routeId: mapValueOfType<String>(json, r'routeId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        acknowledgedAt: mapValueOfType<String>(json, r'acknowledgedAt'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
      );
    }
    return null;
  }

  static List<DriverIssueRecord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssueRecord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssueRecord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverIssueRecord> mapFromJson(dynamic json) {
    final map = <String, DriverIssueRecord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverIssueRecord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverIssueRecord-objects as value to a dart map
  static Map<String, List<DriverIssueRecord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverIssueRecord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverIssueRecord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'note',
    'routeId',
    'acknowledgedAt',
    'createdAt',
  };
}


enum DriverIssueRecordKindEnum {
  breakdown._(r'breakdown'),
  roadBlocked._(r'road_blocked'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverIssueRecordKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverIssueRecordKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverIssueRecordKindEnum? fromJson(dynamic value) => DriverIssueRecordKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverIssueRecordKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverIssueRecordKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssueRecordKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssueRecordKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverIssueRecordKindEnum] to String,
/// and [decode] dynamic data back to [DriverIssueRecordKindEnum].
class DriverIssueRecordKindEnumTypeTransformer {
  factory DriverIssueRecordKindEnumTypeTransformer() => _instance ??= const DriverIssueRecordKindEnumTypeTransformer._();

  const DriverIssueRecordKindEnumTypeTransformer._();

  String encode(DriverIssueRecordKindEnum data) => data._value;

  /// Returns the instance of [DriverIssueRecordKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverIssueRecordKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverIssueRecordKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'breakdown': return DriverIssueRecordKindEnum.breakdown;
        case r'road_blocked': return DriverIssueRecordKindEnum.roadBlocked;
        case r'other': return DriverIssueRecordKindEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverIssueRecordKindEnumTypeTransformer? _instance;
}


