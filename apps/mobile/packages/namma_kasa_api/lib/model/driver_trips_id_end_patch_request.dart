//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdEndPatchRequest {
  /// Returns a new [DriverTripsIdEndPatchRequest] instance.
  DriverTripsIdEndPatchRequest({
    this.reason,
    this.distanceCoveredM,
  });

  DriverTripsIdEndPatchRequestReasonEnum? reason;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? distanceCoveredM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdEndPatchRequest &&
    other.reason == reason &&
    other.distanceCoveredM == distanceCoveredM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reason == null ? 0 : reason!.hashCode) +
    (distanceCoveredM == null ? 0 : distanceCoveredM!.hashCode);

  @override
  String toString() => 'DriverTripsIdEndPatchRequest[reason=$reason, distanceCoveredM=$distanceCoveredM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
    if (this.distanceCoveredM != null) {
      json[r'distanceCoveredM'] = this.distanceCoveredM;
    } else {
      json[r'distanceCoveredM'] = null;
    }
    return json;
  }

  /// Returns a new [DriverTripsIdEndPatchRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdEndPatchRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverTripsIdEndPatchRequest(
        reason: DriverTripsIdEndPatchRequestReasonEnum.fromJson(json[r'reason']),
        distanceCoveredM: mapValueOfType<int>(json, r'distanceCoveredM'),
      );
    }
    return null;
  }

  static List<DriverTripsIdEndPatchRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdEndPatchRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdEndPatchRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdEndPatchRequest> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdEndPatchRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdEndPatchRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdEndPatchRequest-objects as value to a dart map
  static Map<String, List<DriverTripsIdEndPatchRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdEndPatchRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdEndPatchRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum DriverTripsIdEndPatchRequestReasonEnum {
  driver._(r'driver'),
  autoIdle._(r'auto_idle'),
  admin._(r'admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverTripsIdEndPatchRequestReasonEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverTripsIdEndPatchRequestReasonEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverTripsIdEndPatchRequestReasonEnum? fromJson(dynamic value) => DriverTripsIdEndPatchRequestReasonEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverTripsIdEndPatchRequestReasonEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverTripsIdEndPatchRequestReasonEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdEndPatchRequestReasonEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdEndPatchRequestReasonEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverTripsIdEndPatchRequestReasonEnum] to String,
/// and [decode] dynamic data back to [DriverTripsIdEndPatchRequestReasonEnum].
class DriverTripsIdEndPatchRequestReasonEnumTypeTransformer {
  factory DriverTripsIdEndPatchRequestReasonEnumTypeTransformer() => _instance ??= const DriverTripsIdEndPatchRequestReasonEnumTypeTransformer._();

  const DriverTripsIdEndPatchRequestReasonEnumTypeTransformer._();

  String encode(DriverTripsIdEndPatchRequestReasonEnum data) => data._value;

  /// Returns the instance of [DriverTripsIdEndPatchRequestReasonEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverTripsIdEndPatchRequestReasonEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverTripsIdEndPatchRequestReasonEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'driver': return DriverTripsIdEndPatchRequestReasonEnum.driver;
        case r'auto_idle': return DriverTripsIdEndPatchRequestReasonEnum.autoIdle;
        case r'admin': return DriverTripsIdEndPatchRequestReasonEnum.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverTripsIdEndPatchRequestReasonEnumTypeTransformer? _instance;
}


