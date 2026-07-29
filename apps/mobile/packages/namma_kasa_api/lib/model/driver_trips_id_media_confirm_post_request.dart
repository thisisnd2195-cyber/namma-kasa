//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdMediaConfirmPostRequest {
  /// Returns a new [DriverTripsIdMediaConfirmPostRequest] instance.
  DriverTripsIdMediaConfirmPostRequest({
    required this.uploadId,
    required this.objectUrl,
    this.type,
    this.geo,
    this.capturedAt,
  });

  String uploadId;

  String objectUrl;

  DriverTripsIdMediaConfirmPostRequestTypeEnum? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DriverTripsIdMediaConfirmPostRequestGeo? geo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? capturedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdMediaConfirmPostRequest &&
    other.uploadId == uploadId &&
    other.objectUrl == objectUrl &&
    other.type == type &&
    other.geo == geo &&
    other.capturedAt == capturedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (uploadId.hashCode) +
    (objectUrl.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (geo == null ? 0 : geo!.hashCode) +
    (capturedAt == null ? 0 : capturedAt!.hashCode);

  @override
  String toString() => 'DriverTripsIdMediaConfirmPostRequest[uploadId=$uploadId, objectUrl=$objectUrl, type=$type, geo=$geo, capturedAt=$capturedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'uploadId'] = this.uploadId;
      json[r'objectUrl'] = this.objectUrl;
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.geo != null) {
      json[r'geo'] = this.geo;
    } else {
      json[r'geo'] = null;
    }
    if (this.capturedAt != null) {
      json[r'capturedAt'] = this.capturedAt;
    } else {
      json[r'capturedAt'] = null;
    }
    return json;
  }

  /// Returns a new [DriverTripsIdMediaConfirmPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdMediaConfirmPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'uploadId'), 'Required key "DriverTripsIdMediaConfirmPostRequest[uploadId]" is missing from JSON.');
        assert(json[r'uploadId'] != null, 'Required key "DriverTripsIdMediaConfirmPostRequest[uploadId]" has a null value in JSON.');
        assert(json.containsKey(r'objectUrl'), 'Required key "DriverTripsIdMediaConfirmPostRequest[objectUrl]" is missing from JSON.');
        assert(json[r'objectUrl'] != null, 'Required key "DriverTripsIdMediaConfirmPostRequest[objectUrl]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdMediaConfirmPostRequest(
        uploadId: mapValueOfType<String>(json, r'uploadId')!,
        objectUrl: mapValueOfType<String>(json, r'objectUrl')!,
        type: DriverTripsIdMediaConfirmPostRequestTypeEnum.fromJson(json[r'type']),
        geo: DriverTripsIdMediaConfirmPostRequestGeo.fromJson(json[r'geo']),
        capturedAt: mapValueOfType<String>(json, r'capturedAt'),
      );
    }
    return null;
  }

  static List<DriverTripsIdMediaConfirmPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdMediaConfirmPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdMediaConfirmPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdMediaConfirmPostRequest> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdMediaConfirmPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdMediaConfirmPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdMediaConfirmPostRequest-objects as value to a dart map
  static Map<String, List<DriverTripsIdMediaConfirmPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdMediaConfirmPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdMediaConfirmPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'uploadId',
    'objectUrl',
  };
}


enum DriverTripsIdMediaConfirmPostRequestTypeEnum {
  collectionProof._(r'collection_proof'),
  issue._(r'issue'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverTripsIdMediaConfirmPostRequestTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverTripsIdMediaConfirmPostRequestTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverTripsIdMediaConfirmPostRequestTypeEnum? fromJson(dynamic value) => DriverTripsIdMediaConfirmPostRequestTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverTripsIdMediaConfirmPostRequestTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverTripsIdMediaConfirmPostRequestTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdMediaConfirmPostRequestTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdMediaConfirmPostRequestTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverTripsIdMediaConfirmPostRequestTypeEnum] to String,
/// and [decode] dynamic data back to [DriverTripsIdMediaConfirmPostRequestTypeEnum].
class DriverTripsIdMediaConfirmPostRequestTypeEnumTypeTransformer {
  factory DriverTripsIdMediaConfirmPostRequestTypeEnumTypeTransformer() => _instance ??= const DriverTripsIdMediaConfirmPostRequestTypeEnumTypeTransformer._();

  const DriverTripsIdMediaConfirmPostRequestTypeEnumTypeTransformer._();

  String encode(DriverTripsIdMediaConfirmPostRequestTypeEnum data) => data._value;

  /// Returns the instance of [DriverTripsIdMediaConfirmPostRequestTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverTripsIdMediaConfirmPostRequestTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverTripsIdMediaConfirmPostRequestTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'collection_proof': return DriverTripsIdMediaConfirmPostRequestTypeEnum.collectionProof;
        case r'issue': return DriverTripsIdMediaConfirmPostRequestTypeEnum.issue;
        case r'other': return DriverTripsIdMediaConfirmPostRequestTypeEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverTripsIdMediaConfirmPostRequestTypeEnumTypeTransformer? _instance;
}


