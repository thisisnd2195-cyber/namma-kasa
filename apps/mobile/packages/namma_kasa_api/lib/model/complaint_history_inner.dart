//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ComplaintHistoryInner {
  /// Returns a new [ComplaintHistoryInner] instance.
  ComplaintHistoryInner({
    required this.fromStatus,
    required this.toStatus,
    required this.note,
    required this.at,
  });

  ComplaintHistoryInnerFromStatusEnum? fromStatus;

  ComplaintHistoryInnerToStatusEnum toStatus;

  String? note;

  String at;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComplaintHistoryInner &&
    other.fromStatus == fromStatus &&
    other.toStatus == toStatus &&
    other.note == note &&
    other.at == at;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fromStatus == null ? 0 : fromStatus!.hashCode) +
    (toStatus.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (at.hashCode);

  @override
  String toString() => 'ComplaintHistoryInner[fromStatus=$fromStatus, toStatus=$toStatus, note=$note, at=$at]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.fromStatus != null) {
      json[r'fromStatus'] = this.fromStatus;
    } else {
      json[r'fromStatus'] = null;
    }
      json[r'toStatus'] = this.toStatus;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'at'] = this.at;
    return json;
  }

  /// Returns a new [ComplaintHistoryInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComplaintHistoryInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fromStatus'), 'Required key "ComplaintHistoryInner[fromStatus]" is missing from JSON.');
        assert(json.containsKey(r'toStatus'), 'Required key "ComplaintHistoryInner[toStatus]" is missing from JSON.');
        assert(json[r'toStatus'] != null, 'Required key "ComplaintHistoryInner[toStatus]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "ComplaintHistoryInner[note]" is missing from JSON.');
        assert(json.containsKey(r'at'), 'Required key "ComplaintHistoryInner[at]" is missing from JSON.');
        assert(json[r'at'] != null, 'Required key "ComplaintHistoryInner[at]" has a null value in JSON.');
        return true;
      }());

      return ComplaintHistoryInner(
        fromStatus: ComplaintHistoryInnerFromStatusEnum.fromJson(json[r'fromStatus']),
        toStatus: ComplaintHistoryInnerToStatusEnum.fromJson(json[r'toStatus'])!,
        note: mapValueOfType<String>(json, r'note'),
        at: mapValueOfType<String>(json, r'at')!,
      );
    }
    return null;
  }

  static List<ComplaintHistoryInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintHistoryInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintHistoryInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComplaintHistoryInner> mapFromJson(dynamic json) {
    final map = <String, ComplaintHistoryInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComplaintHistoryInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComplaintHistoryInner-objects as value to a dart map
  static Map<String, List<ComplaintHistoryInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComplaintHistoryInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComplaintHistoryInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fromStatus',
    'toStatus',
    'note',
    'at',
  };
}


enum ComplaintHistoryInnerFromStatusEnum {
  open._(r'open'),
  inReview._(r'in_review'),
  resolved._(r'resolved'),
  rejected._(r'rejected'),
  ;

  /// Instantiate a new enum with the provided value.
  const ComplaintHistoryInnerFromStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ComplaintHistoryInnerFromStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ComplaintHistoryInnerFromStatusEnum? fromJson(dynamic value) => ComplaintHistoryInnerFromStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ComplaintHistoryInnerFromStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ComplaintHistoryInnerFromStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintHistoryInnerFromStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintHistoryInnerFromStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ComplaintHistoryInnerFromStatusEnum] to String,
/// and [decode] dynamic data back to [ComplaintHistoryInnerFromStatusEnum].
class ComplaintHistoryInnerFromStatusEnumTypeTransformer {
  factory ComplaintHistoryInnerFromStatusEnumTypeTransformer() => _instance ??= const ComplaintHistoryInnerFromStatusEnumTypeTransformer._();

  const ComplaintHistoryInnerFromStatusEnumTypeTransformer._();

  String encode(ComplaintHistoryInnerFromStatusEnum data) => data._value;

  /// Returns the instance of [ComplaintHistoryInnerFromStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ComplaintHistoryInnerFromStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ComplaintHistoryInnerFromStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'open': return ComplaintHistoryInnerFromStatusEnum.open;
        case r'in_review': return ComplaintHistoryInnerFromStatusEnum.inReview;
        case r'resolved': return ComplaintHistoryInnerFromStatusEnum.resolved;
        case r'rejected': return ComplaintHistoryInnerFromStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ComplaintHistoryInnerFromStatusEnumTypeTransformer? _instance;
}



enum ComplaintHistoryInnerToStatusEnum {
  open._(r'open'),
  inReview._(r'in_review'),
  resolved._(r'resolved'),
  rejected._(r'rejected'),
  ;

  /// Instantiate a new enum with the provided value.
  const ComplaintHistoryInnerToStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ComplaintHistoryInnerToStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ComplaintHistoryInnerToStatusEnum? fromJson(dynamic value) => ComplaintHistoryInnerToStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ComplaintHistoryInnerToStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ComplaintHistoryInnerToStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintHistoryInnerToStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintHistoryInnerToStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ComplaintHistoryInnerToStatusEnum] to String,
/// and [decode] dynamic data back to [ComplaintHistoryInnerToStatusEnum].
class ComplaintHistoryInnerToStatusEnumTypeTransformer {
  factory ComplaintHistoryInnerToStatusEnumTypeTransformer() => _instance ??= const ComplaintHistoryInnerToStatusEnumTypeTransformer._();

  const ComplaintHistoryInnerToStatusEnumTypeTransformer._();

  String encode(ComplaintHistoryInnerToStatusEnum data) => data._value;

  /// Returns the instance of [ComplaintHistoryInnerToStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ComplaintHistoryInnerToStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ComplaintHistoryInnerToStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'open': return ComplaintHistoryInnerToStatusEnum.open;
        case r'in_review': return ComplaintHistoryInnerToStatusEnum.inReview;
        case r'resolved': return ComplaintHistoryInnerToStatusEnum.resolved;
        case r'rejected': return ComplaintHistoryInnerToStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ComplaintHistoryInnerToStatusEnumTypeTransformer? _instance;
}


