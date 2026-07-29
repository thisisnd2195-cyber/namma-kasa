//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Driver {
  /// Returns a new [Driver] instance.
  Driver({
    required this.id,
    required this.wardId,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.photoUrl,
    required this.emergencyContact,
    required this.status,
    required this.hasAccount,
  });

  String id;

  String wardId;

  String fullName;

  String phone;

  String licenseNumber;

  String? photoUrl;

  String? emergencyContact;

  DriverStatusEnum status;

  bool hasAccount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Driver &&
    other.id == id &&
    other.wardId == wardId &&
    other.fullName == fullName &&
    other.phone == phone &&
    other.licenseNumber == licenseNumber &&
    other.photoUrl == photoUrl &&
    other.emergencyContact == emergencyContact &&
    other.status == status &&
    other.hasAccount == hasAccount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (wardId.hashCode) +
    (fullName.hashCode) +
    (phone.hashCode) +
    (licenseNumber.hashCode) +
    (photoUrl == null ? 0 : photoUrl!.hashCode) +
    (emergencyContact == null ? 0 : emergencyContact!.hashCode) +
    (status.hashCode) +
    (hasAccount.hashCode);

  @override
  String toString() => 'Driver[id=$id, wardId=$wardId, fullName=$fullName, phone=$phone, licenseNumber=$licenseNumber, photoUrl=$photoUrl, emergencyContact=$emergencyContact, status=$status, hasAccount=$hasAccount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'wardId'] = this.wardId;
      json[r'fullName'] = this.fullName;
      json[r'phone'] = this.phone;
      json[r'licenseNumber'] = this.licenseNumber;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    if (this.emergencyContact != null) {
      json[r'emergencyContact'] = this.emergencyContact;
    } else {
      json[r'emergencyContact'] = null;
    }
      json[r'status'] = this.status;
      json[r'hasAccount'] = this.hasAccount;
    return json;
  }

  /// Returns a new [Driver] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Driver? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Driver[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Driver[id]" has a null value in JSON.');
        assert(json.containsKey(r'wardId'), 'Required key "Driver[wardId]" is missing from JSON.');
        assert(json[r'wardId'] != null, 'Required key "Driver[wardId]" has a null value in JSON.');
        assert(json.containsKey(r'fullName'), 'Required key "Driver[fullName]" is missing from JSON.');
        assert(json[r'fullName'] != null, 'Required key "Driver[fullName]" has a null value in JSON.');
        assert(json.containsKey(r'phone'), 'Required key "Driver[phone]" is missing from JSON.');
        assert(json[r'phone'] != null, 'Required key "Driver[phone]" has a null value in JSON.');
        assert(json.containsKey(r'licenseNumber'), 'Required key "Driver[licenseNumber]" is missing from JSON.');
        assert(json[r'licenseNumber'] != null, 'Required key "Driver[licenseNumber]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'), 'Required key "Driver[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'emergencyContact'), 'Required key "Driver[emergencyContact]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "Driver[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Driver[status]" has a null value in JSON.');
        assert(json.containsKey(r'hasAccount'), 'Required key "Driver[hasAccount]" is missing from JSON.');
        assert(json[r'hasAccount'] != null, 'Required key "Driver[hasAccount]" has a null value in JSON.');
        return true;
      }());

      return Driver(
        id: mapValueOfType<String>(json, r'id')!,
        wardId: mapValueOfType<String>(json, r'wardId')!,
        fullName: mapValueOfType<String>(json, r'fullName')!,
        phone: mapValueOfType<String>(json, r'phone')!,
        licenseNumber: mapValueOfType<String>(json, r'licenseNumber')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        emergencyContact: mapValueOfType<String>(json, r'emergencyContact'),
        status: DriverStatusEnum.fromJson(json[r'status'])!,
        hasAccount: mapValueOfType<bool>(json, r'hasAccount')!,
      );
    }
    return null;
  }

  static List<Driver> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Driver>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Driver.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Driver> mapFromJson(dynamic json) {
    final map = <String, Driver>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Driver.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Driver-objects as value to a dart map
  static Map<String, List<Driver>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Driver>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Driver.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'wardId',
    'fullName',
    'phone',
    'licenseNumber',
    'photoUrl',
    'emergencyContact',
    'status',
    'hasAccount',
  };
}


enum DriverStatusEnum {
  active._(r'active'),
  inactive._(r'inactive'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverStatusEnum? fromJson(dynamic value) => DriverStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverStatusEnum] to String,
/// and [decode] dynamic data back to [DriverStatusEnum].
class DriverStatusEnumTypeTransformer {
  factory DriverStatusEnumTypeTransformer() => _instance ??= const DriverStatusEnumTypeTransformer._();

  const DriverStatusEnumTypeTransformer._();

  String encode(DriverStatusEnum data) => data._value;

  /// Returns the instance of [DriverStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'active': return DriverStatusEnum.active;
        case r'inactive': return DriverStatusEnum.inactive;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverStatusEnumTypeTransformer? _instance;
}


