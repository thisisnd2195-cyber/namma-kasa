//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdMediaPresignPostRequest {
  /// Returns a new [DriverTripsIdMediaPresignPostRequest] instance.
  DriverTripsIdMediaPresignPostRequest({
    required this.contentType,
    this.type,
  });

  String contentType;

  DriverTripsIdMediaPresignPostRequestTypeEnum? type;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdMediaPresignPostRequest &&
    other.contentType == contentType &&
    other.type == type;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (contentType.hashCode) +
    (type == null ? 0 : type!.hashCode);

  @override
  String toString() => 'DriverTripsIdMediaPresignPostRequest[contentType=$contentType, type=$type]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'contentType'] = this.contentType;
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    return json;
  }

  /// Returns a new [DriverTripsIdMediaPresignPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdMediaPresignPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contentType'), 'Required key "DriverTripsIdMediaPresignPostRequest[contentType]" is missing from JSON.');
        assert(json[r'contentType'] != null, 'Required key "DriverTripsIdMediaPresignPostRequest[contentType]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdMediaPresignPostRequest(
        contentType: mapValueOfType<String>(json, r'contentType')!,
        type: DriverTripsIdMediaPresignPostRequestTypeEnum.fromJson(json[r'type']),
      );
    }
    return null;
  }

  static List<DriverTripsIdMediaPresignPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdMediaPresignPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdMediaPresignPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdMediaPresignPostRequest> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdMediaPresignPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdMediaPresignPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdMediaPresignPostRequest-objects as value to a dart map
  static Map<String, List<DriverTripsIdMediaPresignPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdMediaPresignPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdMediaPresignPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contentType',
  };
}


enum DriverTripsIdMediaPresignPostRequestTypeEnum {
  collectionProof._(r'collection_proof'),
  issue._(r'issue'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const DriverTripsIdMediaPresignPostRequestTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DriverTripsIdMediaPresignPostRequestTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DriverTripsIdMediaPresignPostRequestTypeEnum? fromJson(dynamic value) => DriverTripsIdMediaPresignPostRequestTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DriverTripsIdMediaPresignPostRequestTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DriverTripsIdMediaPresignPostRequestTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdMediaPresignPostRequestTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdMediaPresignPostRequestTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverTripsIdMediaPresignPostRequestTypeEnum] to String,
/// and [decode] dynamic data back to [DriverTripsIdMediaPresignPostRequestTypeEnum].
class DriverTripsIdMediaPresignPostRequestTypeEnumTypeTransformer {
  factory DriverTripsIdMediaPresignPostRequestTypeEnumTypeTransformer() => _instance ??= const DriverTripsIdMediaPresignPostRequestTypeEnumTypeTransformer._();

  const DriverTripsIdMediaPresignPostRequestTypeEnumTypeTransformer._();

  String encode(DriverTripsIdMediaPresignPostRequestTypeEnum data) => data._value;

  /// Returns the instance of [DriverTripsIdMediaPresignPostRequestTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverTripsIdMediaPresignPostRequestTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DriverTripsIdMediaPresignPostRequestTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'collection_proof': return DriverTripsIdMediaPresignPostRequestTypeEnum.collectionProof;
        case r'issue': return DriverTripsIdMediaPresignPostRequestTypeEnum.issue;
        case r'other': return DriverTripsIdMediaPresignPostRequestTypeEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DriverTripsIdMediaPresignPostRequestTypeEnumTypeTransformer? _instance;
}


