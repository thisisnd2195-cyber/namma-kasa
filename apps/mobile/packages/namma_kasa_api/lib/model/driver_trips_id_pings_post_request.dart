//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdPingsPostRequest {
  /// Returns a new [DriverTripsIdPingsPostRequest] instance.
  DriverTripsIdPingsPostRequest({
    this.pings = const [],
  });

  List<DriverTripsIdPingsPostRequestPingsInner> pings;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdPingsPostRequest &&
    _deepEquality.equals(other.pings, pings);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (pings.hashCode);

  @override
  String toString() => 'DriverTripsIdPingsPostRequest[pings=$pings]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'pings'] = this.pings;
    return json;
  }

  /// Returns a new [DriverTripsIdPingsPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdPingsPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'pings'), 'Required key "DriverTripsIdPingsPostRequest[pings]" is missing from JSON.');
        assert(json[r'pings'] != null, 'Required key "DriverTripsIdPingsPostRequest[pings]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdPingsPostRequest(
        pings: DriverTripsIdPingsPostRequestPingsInner.listFromJson(json[r'pings']),
      );
    }
    return null;
  }

  static List<DriverTripsIdPingsPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdPingsPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdPingsPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdPingsPostRequest> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdPingsPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdPingsPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdPingsPostRequest-objects as value to a dart map
  static Map<String, List<DriverTripsIdPingsPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdPingsPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdPingsPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'pings',
  };
}

