//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Auto {
  /// Returns a new [Auto] instance.
  Auto({
    required this.id,
    required this.registrationNumber,
    required this.capacityKg,
    required this.wardId,
    this.photos = const [],
    required this.status,
  });

  String id;

  String registrationNumber;

  int? capacityKg;

  String wardId;

  List<String> photos;

  AutoStatusEnum status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Auto &&
    other.id == id &&
    other.registrationNumber == registrationNumber &&
    other.capacityKg == capacityKg &&
    other.wardId == wardId &&
    _deepEquality.equals(other.photos, photos) &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (registrationNumber.hashCode) +
    (capacityKg == null ? 0 : capacityKg!.hashCode) +
    (wardId.hashCode) +
    (photos.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'Auto[id=$id, registrationNumber=$registrationNumber, capacityKg=$capacityKg, wardId=$wardId, photos=$photos, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'registrationNumber'] = this.registrationNumber;
    if (this.capacityKg != null) {
      json[r'capacityKg'] = this.capacityKg;
    } else {
      json[r'capacityKg'] = null;
    }
      json[r'wardId'] = this.wardId;
      json[r'photos'] = this.photos;
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [Auto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Auto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Auto[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Auto[id]" has a null value in JSON.');
        assert(json.containsKey(r'registrationNumber'), 'Required key "Auto[registrationNumber]" is missing from JSON.');
        assert(json[r'registrationNumber'] != null, 'Required key "Auto[registrationNumber]" has a null value in JSON.');
        assert(json.containsKey(r'capacityKg'), 'Required key "Auto[capacityKg]" is missing from JSON.');
        assert(json.containsKey(r'wardId'), 'Required key "Auto[wardId]" is missing from JSON.');
        assert(json[r'wardId'] != null, 'Required key "Auto[wardId]" has a null value in JSON.');
        assert(json.containsKey(r'photos'), 'Required key "Auto[photos]" is missing from JSON.');
        assert(json[r'photos'] != null, 'Required key "Auto[photos]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Auto[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Auto[status]" has a null value in JSON.');
        return true;
      }());

      return Auto(
        id: mapValueOfType<String>(json, r'id')!,
        registrationNumber: mapValueOfType<String>(json, r'registrationNumber')!,
        capacityKg: mapValueOfType<int>(json, r'capacityKg'),
        wardId: mapValueOfType<String>(json, r'wardId')!,
        photos: json[r'photos'] is Iterable
            ? (json[r'photos'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        status: AutoStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<Auto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Auto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Auto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Auto> mapFromJson(dynamic json) {
    final map = <String, Auto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Auto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Auto-objects as value to a dart map
  static Map<String, List<Auto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Auto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Auto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'registrationNumber',
    'capacityKg',
    'wardId',
    'photos',
    'status',
  };
}


enum AutoStatusEnum {
  available._(r'available'),
  assigned._(r'assigned'),
  maintenance._(r'maintenance'),
  retired._(r'retired'),
  ;

  /// Instantiate a new enum with the provided value.
  const AutoStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AutoStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AutoStatusEnum? fromJson(dynamic value) => AutoStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AutoStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AutoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AutoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AutoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AutoStatusEnum] to String,
/// and [decode] dynamic data back to [AutoStatusEnum].
class AutoStatusEnumTypeTransformer {
  factory AutoStatusEnumTypeTransformer() => _instance ??= const AutoStatusEnumTypeTransformer._();

  const AutoStatusEnumTypeTransformer._();

  String encode(AutoStatusEnum data) => data._value;

  /// Returns the instance of [AutoStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AutoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AutoStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'available': return AutoStatusEnum.available;
        case r'assigned': return AutoStatusEnum.assigned;
        case r'maintenance': return AutoStatusEnum.maintenance;
        case r'retired': return AutoStatusEnum.retired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AutoStatusEnumTypeTransformer? _instance;
}


