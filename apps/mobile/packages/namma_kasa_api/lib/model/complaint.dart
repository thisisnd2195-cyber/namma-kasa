//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Complaint {
  /// Returns a new [Complaint] instance.
  Complaint({
    required this.id,
    required this.category,
    required this.description,
    this.mediaUrls = const [],
    required this.status,
    required this.routeId,
    required this.wardId,
    required this.slaDueAt,
    required this.resolutionNote,
    required this.createdAt,
    this.history = const [],
  });

  String id;

  ComplaintCategoryEnum category;

  String? description;

  List<String> mediaUrls;

  ComplaintStatusEnum status;

  String? routeId;

  String wardId;

  String? slaDueAt;

  String? resolutionNote;

  String createdAt;

  List<ComplaintHistoryInner> history;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Complaint &&
    other.id == id &&
    other.category == category &&
    other.description == description &&
    _deepEquality.equals(other.mediaUrls, mediaUrls) &&
    other.status == status &&
    other.routeId == routeId &&
    other.wardId == wardId &&
    other.slaDueAt == slaDueAt &&
    other.resolutionNote == resolutionNote &&
    other.createdAt == createdAt &&
    _deepEquality.equals(other.history, history);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (category.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (mediaUrls.hashCode) +
    (status.hashCode) +
    (routeId == null ? 0 : routeId!.hashCode) +
    (wardId.hashCode) +
    (slaDueAt == null ? 0 : slaDueAt!.hashCode) +
    (resolutionNote == null ? 0 : resolutionNote!.hashCode) +
    (createdAt.hashCode) +
    (history.hashCode);

  @override
  String toString() => 'Complaint[id=$id, category=$category, description=$description, mediaUrls=$mediaUrls, status=$status, routeId=$routeId, wardId=$wardId, slaDueAt=$slaDueAt, resolutionNote=$resolutionNote, createdAt=$createdAt, history=$history]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'category'] = this.category;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'mediaUrls'] = this.mediaUrls;
      json[r'status'] = this.status;
    if (this.routeId != null) {
      json[r'routeId'] = this.routeId;
    } else {
      json[r'routeId'] = null;
    }
      json[r'wardId'] = this.wardId;
    if (this.slaDueAt != null) {
      json[r'slaDueAt'] = this.slaDueAt;
    } else {
      json[r'slaDueAt'] = null;
    }
    if (this.resolutionNote != null) {
      json[r'resolutionNote'] = this.resolutionNote;
    } else {
      json[r'resolutionNote'] = null;
    }
      json[r'createdAt'] = this.createdAt;
      json[r'history'] = this.history;
    return json;
  }

  /// Returns a new [Complaint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Complaint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Complaint[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Complaint[id]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "Complaint[category]" is missing from JSON.');
        assert(json[r'category'] != null, 'Required key "Complaint[category]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "Complaint[description]" is missing from JSON.');
        assert(json.containsKey(r'mediaUrls'), 'Required key "Complaint[mediaUrls]" is missing from JSON.');
        assert(json[r'mediaUrls'] != null, 'Required key "Complaint[mediaUrls]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Complaint[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Complaint[status]" has a null value in JSON.');
        assert(json.containsKey(r'routeId'), 'Required key "Complaint[routeId]" is missing from JSON.');
        assert(json.containsKey(r'wardId'), 'Required key "Complaint[wardId]" is missing from JSON.');
        assert(json[r'wardId'] != null, 'Required key "Complaint[wardId]" has a null value in JSON.');
        assert(json.containsKey(r'slaDueAt'), 'Required key "Complaint[slaDueAt]" is missing from JSON.');
        assert(json.containsKey(r'resolutionNote'), 'Required key "Complaint[resolutionNote]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "Complaint[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "Complaint[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'history'), 'Required key "Complaint[history]" is missing from JSON.');
        assert(json[r'history'] != null, 'Required key "Complaint[history]" has a null value in JSON.');
        return true;
      }());

      return Complaint(
        id: mapValueOfType<String>(json, r'id')!,
        category: ComplaintCategoryEnum.fromJson(json[r'category'])!,
        description: mapValueOfType<String>(json, r'description'),
        mediaUrls: json[r'mediaUrls'] is Iterable
            ? (json[r'mediaUrls'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        status: ComplaintStatusEnum.fromJson(json[r'status'])!,
        routeId: mapValueOfType<String>(json, r'routeId'),
        wardId: mapValueOfType<String>(json, r'wardId')!,
        slaDueAt: mapValueOfType<String>(json, r'slaDueAt'),
        resolutionNote: mapValueOfType<String>(json, r'resolutionNote'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        history: ComplaintHistoryInner.listFromJson(json[r'history']),
      );
    }
    return null;
  }

  static List<Complaint> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Complaint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Complaint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Complaint> mapFromJson(dynamic json) {
    final map = <String, Complaint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Complaint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Complaint-objects as value to a dart map
  static Map<String, List<Complaint>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Complaint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Complaint.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'category',
    'description',
    'mediaUrls',
    'status',
    'routeId',
    'wardId',
    'slaDueAt',
    'resolutionNote',
    'createdAt',
    'history',
  };
}


enum ComplaintCategoryEnum {
  missedPickup._(r'missed_pickup'),
  late_._(r'late'),
  behavior._(r'behavior'),
  segregation._(r'segregation'),
  other._(r'other'),
  ;

  /// Instantiate a new enum with the provided value.
  const ComplaintCategoryEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ComplaintCategoryEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ComplaintCategoryEnum? fromJson(dynamic value) => ComplaintCategoryEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ComplaintCategoryEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ComplaintCategoryEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintCategoryEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintCategoryEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ComplaintCategoryEnum] to String,
/// and [decode] dynamic data back to [ComplaintCategoryEnum].
class ComplaintCategoryEnumTypeTransformer {
  factory ComplaintCategoryEnumTypeTransformer() => _instance ??= const ComplaintCategoryEnumTypeTransformer._();

  const ComplaintCategoryEnumTypeTransformer._();

  String encode(ComplaintCategoryEnum data) => data._value;

  /// Returns the instance of [ComplaintCategoryEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ComplaintCategoryEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ComplaintCategoryEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'missed_pickup': return ComplaintCategoryEnum.missedPickup;
        case r'late': return ComplaintCategoryEnum.late_;
        case r'behavior': return ComplaintCategoryEnum.behavior;
        case r'segregation': return ComplaintCategoryEnum.segregation;
        case r'other': return ComplaintCategoryEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ComplaintCategoryEnumTypeTransformer? _instance;
}



enum ComplaintStatusEnum {
  open._(r'open'),
  inReview._(r'in_review'),
  resolved._(r'resolved'),
  rejected._(r'rejected'),
  ;

  /// Instantiate a new enum with the provided value.
  const ComplaintStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ComplaintStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ComplaintStatusEnum? fromJson(dynamic value) => ComplaintStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ComplaintStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ComplaintStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ComplaintStatusEnum] to String,
/// and [decode] dynamic data back to [ComplaintStatusEnum].
class ComplaintStatusEnumTypeTransformer {
  factory ComplaintStatusEnumTypeTransformer() => _instance ??= const ComplaintStatusEnumTypeTransformer._();

  const ComplaintStatusEnumTypeTransformer._();

  String encode(ComplaintStatusEnum data) => data._value;

  /// Returns the instance of [ComplaintStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ComplaintStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ComplaintStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'open': return ComplaintStatusEnum.open;
        case r'in_review': return ComplaintStatusEnum.inReview;
        case r'resolved': return ComplaintStatusEnum.resolved;
        case r'rejected': return ComplaintStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ComplaintStatusEnumTypeTransformer? _instance;
}


