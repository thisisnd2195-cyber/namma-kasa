//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Rating {
  /// Returns a new [Rating] instance.
  Rating({
    required this.id,
    required this.stars,
    required this.comment,
    required this.collectionDate,
    required this.createdAt,
  });

  String id;

  int stars;

  String? comment;

  String collectionDate;

  String createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Rating &&
    other.id == id &&
    other.stars == stars &&
    other.comment == comment &&
    other.collectionDate == collectionDate &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (stars.hashCode) +
    (comment == null ? 0 : comment!.hashCode) +
    (collectionDate.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Rating[id=$id, stars=$stars, comment=$comment, collectionDate=$collectionDate, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'stars'] = this.stars;
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
      json[r'collectionDate'] = this.collectionDate;
      json[r'createdAt'] = this.createdAt;
    return json;
  }

  /// Returns a new [Rating] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Rating? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Rating[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Rating[id]" has a null value in JSON.');
        assert(json.containsKey(r'stars'), 'Required key "Rating[stars]" is missing from JSON.');
        assert(json[r'stars'] != null, 'Required key "Rating[stars]" has a null value in JSON.');
        assert(json.containsKey(r'comment'), 'Required key "Rating[comment]" is missing from JSON.');
        assert(json.containsKey(r'collectionDate'), 'Required key "Rating[collectionDate]" is missing from JSON.');
        assert(json[r'collectionDate'] != null, 'Required key "Rating[collectionDate]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "Rating[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "Rating[createdAt]" has a null value in JSON.');
        return true;
      }());

      return Rating(
        id: mapValueOfType<String>(json, r'id')!,
        stars: mapValueOfType<int>(json, r'stars')!,
        comment: mapValueOfType<String>(json, r'comment'),
        collectionDate: mapValueOfType<String>(json, r'collectionDate')!,
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
      );
    }
    return null;
  }

  static List<Rating> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Rating>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Rating.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Rating> mapFromJson(dynamic json) {
    final map = <String, Rating>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Rating.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Rating-objects as value to a dart map
  static Map<String, List<Rating>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Rating>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Rating.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'stars',
    'comment',
    'collectionDate',
    'createdAt',
  };
}

