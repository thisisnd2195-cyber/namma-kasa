//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MeDelete202Response {
  /// Returns a new [MeDelete202Response] instance.
  MeDelete202Response({
    required this.erasesAfter,
    required this.note,
  });

  DateTime erasesAfter;

  String note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MeDelete202Response &&
    other.erasesAfter == erasesAfter &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (erasesAfter.hashCode) +
    (note.hashCode);

  @override
  String toString() => 'MeDelete202Response[erasesAfter=$erasesAfter, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'erasesAfter'] = this.erasesAfter.toUtc().toIso8601String();
      json[r'note'] = this.note;
    return json;
  }

  /// Returns a new [MeDelete202Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeDelete202Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'erasesAfter'), 'Required key "MeDelete202Response[erasesAfter]" is missing from JSON.');
        assert(json[r'erasesAfter'] != null, 'Required key "MeDelete202Response[erasesAfter]" has a null value in JSON.');
        assert(json.containsKey(r'note'), 'Required key "MeDelete202Response[note]" is missing from JSON.');
        assert(json[r'note'] != null, 'Required key "MeDelete202Response[note]" has a null value in JSON.');
        return true;
      }());

      return MeDelete202Response(
        erasesAfter: mapDateTime(json, r'erasesAfter', r'')!,
        note: mapValueOfType<String>(json, r'note')!,
      );
    }
    return null;
  }

  static List<MeDelete202Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeDelete202Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeDelete202Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeDelete202Response> mapFromJson(dynamic json) {
    final map = <String, MeDelete202Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeDelete202Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeDelete202Response-objects as value to a dart map
  static Map<String, List<MeDelete202Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MeDelete202Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeDelete202Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'erasesAfter',
    'note',
  };
}

