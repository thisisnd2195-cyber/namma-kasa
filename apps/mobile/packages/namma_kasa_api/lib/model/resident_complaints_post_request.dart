//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentComplaintsPostRequest {
  /// Returns a new [ResidentComplaintsPostRequest] instance.
  ResidentComplaintsPostRequest({
    required this.category,
    this.description,
    this.mediaUrls = const [],
  });

  ResidentComplaintsPostRequestCategoryEnum category;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  List<String> mediaUrls;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentComplaintsPostRequest &&
    other.category == category &&
    other.description == description &&
    _deepEquality.equals(other.mediaUrls, mediaUrls);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (category.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (mediaUrls.hashCode);

  @override
  String toString() => 'ResidentComplaintsPostRequest[category=$category, description=$description, mediaUrls=$mediaUrls]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'category'] = this.category;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'mediaUrls'] = this.mediaUrls;
    return json;
  }

  /// Returns a new [ResidentComplaintsPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentComplaintsPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'category'), 'Required key "ResidentComplaintsPostRequest[category]" is missing from JSON.');
        assert(json[r'category'] != null, 'Required key "ResidentComplaintsPostRequest[category]" has a null value in JSON.');
        return true;
      }());

      return ResidentComplaintsPostRequest(
        category: ResidentComplaintsPostRequestCategoryEnum.fromJson(json[r'category'])!,
        description: mapValueOfType<String>(json, r'description'),
        mediaUrls: json[r'mediaUrls'] is Iterable
            ? (json[r'mediaUrls'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<ResidentComplaintsPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentComplaintsPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentComplaintsPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentComplaintsPostRequest> mapFromJson(dynamic json) {
    final map = <String, ResidentComplaintsPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentComplaintsPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentComplaintsPostRequest-objects as value to a dart map
  static Map<String, List<ResidentComplaintsPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentComplaintsPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentComplaintsPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
  };
}


enum ResidentComplaintsPostRequestCategoryEnum {
  missedPickup._(r'missed_pickup'),
  late_._(r'late'),
  behavior._(r'behavior'),
  segregation._(r'segregation'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const ResidentComplaintsPostRequestCategoryEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ResidentComplaintsPostRequestCategoryEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ResidentComplaintsPostRequestCategoryEnum? fromJson(dynamic value) => ResidentComplaintsPostRequestCategoryEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ResidentComplaintsPostRequestCategoryEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ResidentComplaintsPostRequestCategoryEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentComplaintsPostRequestCategoryEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentComplaintsPostRequestCategoryEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ResidentComplaintsPostRequestCategoryEnum] to String,
/// and [decode] dynamic data back to [ResidentComplaintsPostRequestCategoryEnum].
class ResidentComplaintsPostRequestCategoryEnumTypeTransformer {
  factory ResidentComplaintsPostRequestCategoryEnumTypeTransformer() => _instance ??= const ResidentComplaintsPostRequestCategoryEnumTypeTransformer._();

  const ResidentComplaintsPostRequestCategoryEnumTypeTransformer._();

  String encode(ResidentComplaintsPostRequestCategoryEnum data) => data._value;

  /// Returns the instance of [ResidentComplaintsPostRequestCategoryEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ResidentComplaintsPostRequestCategoryEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ResidentComplaintsPostRequestCategoryEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'missed_pickup': return ResidentComplaintsPostRequestCategoryEnum.missedPickup;
        case r'late': return ResidentComplaintsPostRequestCategoryEnum.late_;
        case r'behavior': return ResidentComplaintsPostRequestCategoryEnum.behavior;
        case r'segregation': return ResidentComplaintsPostRequestCategoryEnum.segregation;
        case r'other': return ResidentComplaintsPostRequestCategoryEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ResidentComplaintsPostRequestCategoryEnumTypeTransformer? _instance;
}


