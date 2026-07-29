//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Trip {
  /// Returns a new [Trip] instance.
  Trip({
    required this.id,
    required this.autoId,
    required this.driverId,
    required this.routeId,
    required this.passNumber,
    required this.serviceDate,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.endReason,
    required this.distanceCoveredM,
  });

  String id;

  String autoId;

  String driverId;

  String routeId;

  int passNumber;

  String serviceDate;

  String startedAt;

  String? endedAt;

  TripStatusEnum status;

  TripEndReasonEnum? endReason;

  int? distanceCoveredM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Trip &&
    other.id == id &&
    other.autoId == autoId &&
    other.driverId == driverId &&
    other.routeId == routeId &&
    other.passNumber == passNumber &&
    other.serviceDate == serviceDate &&
    other.startedAt == startedAt &&
    other.endedAt == endedAt &&
    other.status == status &&
    other.endReason == endReason &&
    other.distanceCoveredM == distanceCoveredM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (autoId.hashCode) +
    (driverId.hashCode) +
    (routeId.hashCode) +
    (passNumber.hashCode) +
    (serviceDate.hashCode) +
    (startedAt.hashCode) +
    (endedAt == null ? 0 : endedAt!.hashCode) +
    (status.hashCode) +
    (endReason == null ? 0 : endReason!.hashCode) +
    (distanceCoveredM == null ? 0 : distanceCoveredM!.hashCode);

  @override
  String toString() => 'Trip[id=$id, autoId=$autoId, driverId=$driverId, routeId=$routeId, passNumber=$passNumber, serviceDate=$serviceDate, startedAt=$startedAt, endedAt=$endedAt, status=$status, endReason=$endReason, distanceCoveredM=$distanceCoveredM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'autoId'] = this.autoId;
      json[r'driverId'] = this.driverId;
      json[r'routeId'] = this.routeId;
      json[r'passNumber'] = this.passNumber;
      json[r'serviceDate'] = this.serviceDate;
      json[r'startedAt'] = this.startedAt;
    if (this.endedAt != null) {
      json[r'endedAt'] = this.endedAt;
    } else {
      json[r'endedAt'] = null;
    }
      json[r'status'] = this.status;
    if (this.endReason != null) {
      json[r'endReason'] = this.endReason;
    } else {
      json[r'endReason'] = null;
    }
    if (this.distanceCoveredM != null) {
      json[r'distanceCoveredM'] = this.distanceCoveredM;
    } else {
      json[r'distanceCoveredM'] = null;
    }
    return json;
  }

  /// Returns a new [Trip] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Trip? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Trip[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Trip[id]" has a null value in JSON.');
        assert(json.containsKey(r'autoId'), 'Required key "Trip[autoId]" is missing from JSON.');
        assert(json[r'autoId'] != null, 'Required key "Trip[autoId]" has a null value in JSON.');
        assert(json.containsKey(r'driverId'), 'Required key "Trip[driverId]" is missing from JSON.');
        assert(json[r'driverId'] != null, 'Required key "Trip[driverId]" has a null value in JSON.');
        assert(json.containsKey(r'routeId'), 'Required key "Trip[routeId]" is missing from JSON.');
        assert(json[r'routeId'] != null, 'Required key "Trip[routeId]" has a null value in JSON.');
        assert(json.containsKey(r'passNumber'), 'Required key "Trip[passNumber]" is missing from JSON.');
        assert(json[r'passNumber'] != null, 'Required key "Trip[passNumber]" has a null value in JSON.');
        assert(json.containsKey(r'serviceDate'), 'Required key "Trip[serviceDate]" is missing from JSON.');
        assert(json[r'serviceDate'] != null, 'Required key "Trip[serviceDate]" has a null value in JSON.');
        assert(json.containsKey(r'startedAt'), 'Required key "Trip[startedAt]" is missing from JSON.');
        assert(json[r'startedAt'] != null, 'Required key "Trip[startedAt]" has a null value in JSON.');
        assert(json.containsKey(r'endedAt'), 'Required key "Trip[endedAt]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "Trip[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Trip[status]" has a null value in JSON.');
        assert(json.containsKey(r'endReason'), 'Required key "Trip[endReason]" is missing from JSON.');
        assert(json.containsKey(r'distanceCoveredM'), 'Required key "Trip[distanceCoveredM]" is missing from JSON.');
        return true;
      }());

      return Trip(
        id: mapValueOfType<String>(json, r'id')!,
        autoId: mapValueOfType<String>(json, r'autoId')!,
        driverId: mapValueOfType<String>(json, r'driverId')!,
        routeId: mapValueOfType<String>(json, r'routeId')!,
        passNumber: mapValueOfType<int>(json, r'passNumber')!,
        serviceDate: mapValueOfType<String>(json, r'serviceDate')!,
        startedAt: mapValueOfType<String>(json, r'startedAt')!,
        endedAt: mapValueOfType<String>(json, r'endedAt'),
        status: TripStatusEnum.fromJson(json[r'status'])!,
        endReason: TripEndReasonEnum.fromJson(json[r'endReason']),
        distanceCoveredM: mapValueOfType<int>(json, r'distanceCoveredM'),
      );
    }
    return null;
  }

  static List<Trip> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Trip>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Trip.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Trip> mapFromJson(dynamic json) {
    final map = <String, Trip>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Trip.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Trip-objects as value to a dart map
  static Map<String, List<Trip>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Trip>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Trip.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'autoId',
    'driverId',
    'routeId',
    'passNumber',
    'serviceDate',
    'startedAt',
    'endedAt',
    'status',
    'endReason',
    'distanceCoveredM',
  };
}


enum TripStatusEnum {
  active._(r'active'),
  completed._(r'completed'),
  aborted._(r'aborted'),
  ;

  /// Instantiate a new enum with the provided value.
  const TripStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TripStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TripStatusEnum? fromJson(dynamic value) => TripStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TripStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TripStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TripStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TripStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TripStatusEnum] to String,
/// and [decode] dynamic data back to [TripStatusEnum].
class TripStatusEnumTypeTransformer {
  factory TripStatusEnumTypeTransformer() => _instance ??= const TripStatusEnumTypeTransformer._();

  const TripStatusEnumTypeTransformer._();

  String encode(TripStatusEnum data) => data._value;

  /// Returns the instance of [TripStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TripStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is TripStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'active': return TripStatusEnum.active;
        case r'completed': return TripStatusEnum.completed;
        case r'aborted': return TripStatusEnum.aborted;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TripStatusEnumTypeTransformer? _instance;
}



enum TripEndReasonEnum {
  driver._(r'driver'),
  autoIdle._(r'auto_idle'),
  admin._(r'admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const TripEndReasonEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TripEndReasonEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TripEndReasonEnum? fromJson(dynamic value) => TripEndReasonEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TripEndReasonEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TripEndReasonEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TripEndReasonEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TripEndReasonEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TripEndReasonEnum] to String,
/// and [decode] dynamic data back to [TripEndReasonEnum].
class TripEndReasonEnumTypeTransformer {
  factory TripEndReasonEnumTypeTransformer() => _instance ??= const TripEndReasonEnumTypeTransformer._();

  const TripEndReasonEnumTypeTransformer._();

  String encode(TripEndReasonEnum data) => data._value;

  /// Returns the instance of [TripEndReasonEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TripEndReasonEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is TripEndReasonEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'driver': return TripEndReasonEnum.driver;
        case r'auto_idle': return TripEndReasonEnum.autoIdle;
        case r'admin': return TripEndReasonEnum.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TripEndReasonEnumTypeTransformer? _instance;
}


