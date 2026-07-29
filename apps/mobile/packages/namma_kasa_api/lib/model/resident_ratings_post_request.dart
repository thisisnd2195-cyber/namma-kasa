//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentRatingsPostRequest {
  /// Returns a new [ResidentRatingsPostRequest] instance.
  ResidentRatingsPostRequest({
    required this.stars,
    this.comment,
  });

  /// Minimum value: 1
  /// Maximum value: 5
  int stars;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? comment;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentRatingsPostRequest &&
    other.stars == stars &&
    other.comment == comment;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (stars.hashCode) +
    (comment == null ? 0 : comment!.hashCode);

  @override
  String toString() => 'ResidentRatingsPostRequest[stars=$stars, comment=$comment]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'stars'] = this.stars;
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
    return json;
  }

  /// Returns a new [ResidentRatingsPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentRatingsPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'stars'), 'Required key "ResidentRatingsPostRequest[stars]" is missing from JSON.');
        assert(json[r'stars'] != null, 'Required key "ResidentRatingsPostRequest[stars]" has a null value in JSON.');
        return true;
      }());

      return ResidentRatingsPostRequest(
        stars: mapValueOfType<int>(json, r'stars')!,
        comment: mapValueOfType<String>(json, r'comment'),
      );
    }
    return null;
  }

  static List<ResidentRatingsPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentRatingsPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentRatingsPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentRatingsPostRequest> mapFromJson(dynamic json) {
    final map = <String, ResidentRatingsPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentRatingsPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentRatingsPostRequest-objects as value to a dart map
  static Map<String, List<ResidentRatingsPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentRatingsPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentRatingsPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'stars',
  };
}

