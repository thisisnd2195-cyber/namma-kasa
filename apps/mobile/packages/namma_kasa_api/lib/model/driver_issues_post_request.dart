//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverIssuesPostRequest {
  /// Returns a new [DriverIssuesPostRequest] instance.
  DriverIssuesPostRequest({
    required this.kind,
    this.note,
    this.geo,
  });

  DriverIssuesPostRequestKindEnum kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  GeoPoint? geo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverIssuesPostRequest &&
    other.kind == kind &&
    other.note == note &&
    other.geo == geo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (geo == null ? 0 : geo!.hashCode);

  @override
  String toString() => 'DriverIssuesPostRequest[kind=$kind, note=$note, geo=$geo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.geo != null) {
      json[r'geo'] = this.geo;
    } else {
      json[r'geo'] = null;
    }
    return json;
  }

  /// Returns a new [DriverIssuesPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverIssuesPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "DriverIssuesPostRequest[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "DriverIssuesPostRequest[kind]" has a null value in JSON.');
        return true;
      }());

      return DriverIssuesPostRequest(
        kind: DriverIssuesPostRequestKindEnum.fromJson(json[r'kind'])!,
        note: mapValueOfType<String>(json, r'note'),
        geo: GeoPoint.fromJson(json[r'geo']),
      );
    }
    return null;
  }

  static List<DriverIssuesPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssuesPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssuesPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverIssuesPostRequest> mapFromJson(dynamic json) {
    final map = <String, DriverIssuesPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverIssuesPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverIssuesPostRequest-objects as value to a dart map
  static Map<String, List<DriverIssuesPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverIssuesPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverIssuesPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
  };
}


enum DriverIssuesPostRequestKindEnum {
  breakdown._(r'breakdown'),
  roadBlocked._(r'road_blocked'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverIssuesPostRequestKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverIssuesPostRequestKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverIssuesPostRequestKindEnum? fromJson(dynamic value) => DriverIssuesPostRequestKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverIssuesPostRequestKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverIssuesPostRequestKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssuesPostRequestKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssuesPostRequestKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverIssuesPostRequestKindEnum] to String,
/// and [decode] dynamic data back to [DriverIssuesPostRequestKindEnum].
class DriverIssuesPostRequestKindEnumTypeTransformer {
  factory DriverIssuesPostRequestKindEnumTypeTransformer() => _instance ??= const DriverIssuesPostRequestKindEnumTypeTransformer._();

  const DriverIssuesPostRequestKindEnumTypeTransformer._();

  String encode(DriverIssuesPostRequestKindEnum data) => data._value;

  /// Returns the instance of [DriverIssuesPostRequestKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverIssuesPostRequestKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverIssuesPostRequestKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'breakdown': return DriverIssuesPostRequestKindEnum.breakdown;
        case r'road_blocked': return DriverIssuesPostRequestKindEnum.roadBlocked;
        case r'other': return DriverIssuesPostRequestKindEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverIssuesPostRequestKindEnumTypeTransformer? _instance;
}


