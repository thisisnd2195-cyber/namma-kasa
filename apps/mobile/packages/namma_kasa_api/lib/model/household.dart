//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Household {
  /// Returns a new [Household] instance.
  Household({
    required this.id,
    required this.fullName,
    required this.addressLine,
    required this.landmark,
    required this.pin,
    required this.wardId,
    required this.routeId,
    required this.mappingStatus,
    required this.notificationRadiusM,
  });

  String id;

  String fullName;

  String addressLine;

  String? landmark;

  DriverTripsIdMediaConfirmPostRequestGeo pin;

  String? wardId;

  String? routeId;

  HouseholdMappingStatusEnum mappingStatus;

  int notificationRadiusM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Household &&
    other.id == id &&
    other.fullName == fullName &&
    other.addressLine == addressLine &&
    other.landmark == landmark &&
    other.pin == pin &&
    other.wardId == wardId &&
    other.routeId == routeId &&
    other.mappingStatus == mappingStatus &&
    other.notificationRadiusM == notificationRadiusM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (fullName.hashCode) +
    (addressLine.hashCode) +
    (landmark == null ? 0 : landmark!.hashCode) +
    (pin.hashCode) +
    (wardId == null ? 0 : wardId!.hashCode) +
    (routeId == null ? 0 : routeId!.hashCode) +
    (mappingStatus.hashCode) +
    (notificationRadiusM.hashCode);

  @override
  String toString() => 'Household[id=$id, fullName=$fullName, addressLine=$addressLine, landmark=$landmark, pin=$pin, wardId=$wardId, routeId=$routeId, mappingStatus=$mappingStatus, notificationRadiusM=$notificationRadiusM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'fullName'] = this.fullName;
      json[r'addressLine'] = this.addressLine;
    if (this.landmark != null) {
      json[r'landmark'] = this.landmark;
    } else {
      json[r'landmark'] = null;
    }
      json[r'pin'] = this.pin;
    if (this.wardId != null) {
      json[r'wardId'] = this.wardId;
    } else {
      json[r'wardId'] = null;
    }
    if (this.routeId != null) {
      json[r'routeId'] = this.routeId;
    } else {
      json[r'routeId'] = null;
    }
      json[r'mappingStatus'] = this.mappingStatus;
      json[r'notificationRadiusM'] = this.notificationRadiusM;
    return json;
  }

  /// Returns a new [Household] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Household? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Household[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Household[id]" has a null value in JSON.');
        assert(json.containsKey(r'fullName'), 'Required key "Household[fullName]" is missing from JSON.');
        assert(json[r'fullName'] != null, 'Required key "Household[fullName]" has a null value in JSON.');
        assert(json.containsKey(r'addressLine'), 'Required key "Household[addressLine]" is missing from JSON.');
        assert(json[r'addressLine'] != null, 'Required key "Household[addressLine]" has a null value in JSON.');
        assert(json.containsKey(r'landmark'), 'Required key "Household[landmark]" is missing from JSON.');
        assert(json.containsKey(r'pin'), 'Required key "Household[pin]" is missing from JSON.');
        assert(json[r'pin'] != null, 'Required key "Household[pin]" has a null value in JSON.');
        assert(json.containsKey(r'wardId'), 'Required key "Household[wardId]" is missing from JSON.');
        assert(json.containsKey(r'routeId'), 'Required key "Household[routeId]" is missing from JSON.');
        assert(json.containsKey(r'mappingStatus'), 'Required key "Household[mappingStatus]" is missing from JSON.');
        assert(json[r'mappingStatus'] != null, 'Required key "Household[mappingStatus]" has a null value in JSON.');
        assert(json.containsKey(r'notificationRadiusM'), 'Required key "Household[notificationRadiusM]" is missing from JSON.');
        assert(json[r'notificationRadiusM'] != null, 'Required key "Household[notificationRadiusM]" has a null value in JSON.');
        return true;
      }());

      return Household(
        id: mapValueOfType<String>(json, r'id')!,
        fullName: mapValueOfType<String>(json, r'fullName')!,
        addressLine: mapValueOfType<String>(json, r'addressLine')!,
        landmark: mapValueOfType<String>(json, r'landmark'),
        pin: DriverTripsIdMediaConfirmPostRequestGeo.fromJson(json[r'pin'])!,
        wardId: mapValueOfType<String>(json, r'wardId'),
        routeId: mapValueOfType<String>(json, r'routeId'),
        mappingStatus: HouseholdMappingStatusEnum.fromJson(json[r'mappingStatus'])!,
        notificationRadiusM: mapValueOfType<int>(json, r'notificationRadiusM')!,
      );
    }
    return null;
  }

  static List<Household> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Household>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Household.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Household> mapFromJson(dynamic json) {
    final map = <String, Household>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Household.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Household-objects as value to a dart map
  static Map<String, List<Household>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Household>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Household.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'fullName',
    'addressLine',
    'landmark',
    'pin',
    'wardId',
    'routeId',
    'mappingStatus',
    'notificationRadiusM',
  };
}


enum HouseholdMappingStatusEnum {
  auto._(r'auto'),
  adminCorrected._(r'admin_corrected'),
  pendingReview._(r'pending_review'),
  ;

  /// Instantiate a new enum with the provided value.
  const HouseholdMappingStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HouseholdMappingStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HouseholdMappingStatusEnum? fromJson(dynamic value) => HouseholdMappingStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HouseholdMappingStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HouseholdMappingStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HouseholdMappingStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HouseholdMappingStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HouseholdMappingStatusEnum] to String,
/// and [decode] dynamic data back to [HouseholdMappingStatusEnum].
class HouseholdMappingStatusEnumTypeTransformer {
  factory HouseholdMappingStatusEnumTypeTransformer() => _instance ??= const HouseholdMappingStatusEnumTypeTransformer._();

  const HouseholdMappingStatusEnumTypeTransformer._();

  String encode(HouseholdMappingStatusEnum data) => data._value;

  /// Returns the instance of [HouseholdMappingStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HouseholdMappingStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is HouseholdMappingStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'auto': return HouseholdMappingStatusEnum.auto;
        case r'admin_corrected': return HouseholdMappingStatusEnum.adminCorrected;
        case r'pending_review': return HouseholdMappingStatusEnum.pendingReview;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HouseholdMappingStatusEnumTypeTransformer? _instance;
}


