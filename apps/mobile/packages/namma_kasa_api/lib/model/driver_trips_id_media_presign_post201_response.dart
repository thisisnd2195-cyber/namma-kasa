//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdMediaPresignPost201Response {
  /// Returns a new [DriverTripsIdMediaPresignPost201Response] instance.
  DriverTripsIdMediaPresignPost201Response({
    required this.uploadUrl,
    required this.objectUrl,
    required this.uploadId,
  });

  String uploadUrl;

  String objectUrl;

  String uploadId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdMediaPresignPost201Response &&
    other.uploadUrl == uploadUrl &&
    other.objectUrl == objectUrl &&
    other.uploadId == uploadId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (uploadUrl.hashCode) +
    (objectUrl.hashCode) +
    (uploadId.hashCode);

  @override
  String toString() => 'DriverTripsIdMediaPresignPost201Response[uploadUrl=$uploadUrl, objectUrl=$objectUrl, uploadId=$uploadId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'uploadUrl'] = this.uploadUrl;
      json[r'objectUrl'] = this.objectUrl;
      json[r'uploadId'] = this.uploadId;
    return json;
  }

  /// Returns a new [DriverTripsIdMediaPresignPost201Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdMediaPresignPost201Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'uploadUrl'), 'Required key "DriverTripsIdMediaPresignPost201Response[uploadUrl]" is missing from JSON.');
        assert(json[r'uploadUrl'] != null, 'Required key "DriverTripsIdMediaPresignPost201Response[uploadUrl]" has a null value in JSON.');
        assert(json.containsKey(r'objectUrl'), 'Required key "DriverTripsIdMediaPresignPost201Response[objectUrl]" is missing from JSON.');
        assert(json[r'objectUrl'] != null, 'Required key "DriverTripsIdMediaPresignPost201Response[objectUrl]" has a null value in JSON.');
        assert(json.containsKey(r'uploadId'), 'Required key "DriverTripsIdMediaPresignPost201Response[uploadId]" is missing from JSON.');
        assert(json[r'uploadId'] != null, 'Required key "DriverTripsIdMediaPresignPost201Response[uploadId]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdMediaPresignPost201Response(
        uploadUrl: mapValueOfType<String>(json, r'uploadUrl')!,
        objectUrl: mapValueOfType<String>(json, r'objectUrl')!,
        uploadId: mapValueOfType<String>(json, r'uploadId')!,
      );
    }
    return null;
  }

  static List<DriverTripsIdMediaPresignPost201Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdMediaPresignPost201Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdMediaPresignPost201Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdMediaPresignPost201Response> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdMediaPresignPost201Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdMediaPresignPost201Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdMediaPresignPost201Response-objects as value to a dart map
  static Map<String, List<DriverTripsIdMediaPresignPost201Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdMediaPresignPost201Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdMediaPresignPost201Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'uploadUrl',
    'objectUrl',
    'uploadId',
  };
}

