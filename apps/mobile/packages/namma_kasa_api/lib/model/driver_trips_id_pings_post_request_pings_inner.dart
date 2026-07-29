//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverTripsIdPingsPostRequestPingsInner {
  /// Returns a new [DriverTripsIdPingsPostRequestPingsInner] instance.
  DriverTripsIdPingsPostRequestPingsInner({
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.accuracy,
    required this.recordedAt,
    required this.seq,
  });

  /// Minimum value: -90
  /// Maximum value: 90
  num lat;

  /// Minimum value: -180
  /// Maximum value: 180
  num lng;

  /// Minimum value: 0
  num? speed;

  /// Minimum value: 0
  /// Maximum value: 360
  num? heading;

  /// Minimum value: 0
  num? accuracy;

  String recordedAt;

  /// Minimum value: 0
  int seq;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverTripsIdPingsPostRequestPingsInner &&
    other.lat == lat &&
    other.lng == lng &&
    other.speed == speed &&
    other.heading == heading &&
    other.accuracy == accuracy &&
    other.recordedAt == recordedAt &&
    other.seq == seq;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lat.hashCode) +
    (lng.hashCode) +
    (speed == null ? 0 : speed!.hashCode) +
    (heading == null ? 0 : heading!.hashCode) +
    (accuracy == null ? 0 : accuracy!.hashCode) +
    (recordedAt.hashCode) +
    (seq.hashCode);

  @override
  String toString() => 'DriverTripsIdPingsPostRequestPingsInner[lat=$lat, lng=$lng, speed=$speed, heading=$heading, accuracy=$accuracy, recordedAt=$recordedAt, seq=$seq]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    if (this.speed != null) {
      json[r'speed'] = this.speed;
    } else {
      json[r'speed'] = null;
    }
    if (this.heading != null) {
      json[r'heading'] = this.heading;
    } else {
      json[r'heading'] = null;
    }
    if (this.accuracy != null) {
      json[r'accuracy'] = this.accuracy;
    } else {
      json[r'accuracy'] = null;
    }
      json[r'recordedAt'] = this.recordedAt;
      json[r'seq'] = this.seq;
    return json;
  }

  /// Returns a new [DriverTripsIdPingsPostRequestPingsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverTripsIdPingsPostRequestPingsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'lat'), 'Required key "DriverTripsIdPingsPostRequestPingsInner[lat]" is missing from JSON.');
        assert(json[r'lat'] != null, 'Required key "DriverTripsIdPingsPostRequestPingsInner[lat]" has a null value in JSON.');
        assert(json.containsKey(r'lng'), 'Required key "DriverTripsIdPingsPostRequestPingsInner[lng]" is missing from JSON.');
        assert(json[r'lng'] != null, 'Required key "DriverTripsIdPingsPostRequestPingsInner[lng]" has a null value in JSON.');
        assert(json.containsKey(r'recordedAt'), 'Required key "DriverTripsIdPingsPostRequestPingsInner[recordedAt]" is missing from JSON.');
        assert(json[r'recordedAt'] != null, 'Required key "DriverTripsIdPingsPostRequestPingsInner[recordedAt]" has a null value in JSON.');
        assert(json.containsKey(r'seq'), 'Required key "DriverTripsIdPingsPostRequestPingsInner[seq]" is missing from JSON.');
        assert(json[r'seq'] != null, 'Required key "DriverTripsIdPingsPostRequestPingsInner[seq]" has a null value in JSON.');
        return true;
      }());

      return DriverTripsIdPingsPostRequestPingsInner(
        lat: num.parse('${json[r'lat']}'),
        lng: num.parse('${json[r'lng']}'),
        speed: json[r'speed'] == null
            ? null
            : num.parse('${json[r'speed']}'),
        heading: json[r'heading'] == null
            ? null
            : num.parse('${json[r'heading']}'),
        accuracy: json[r'accuracy'] == null
            ? null
            : num.parse('${json[r'accuracy']}'),
        recordedAt: mapValueOfType<String>(json, r'recordedAt')!,
        seq: mapValueOfType<int>(json, r'seq')!,
      );
    }
    return null;
  }

  static List<DriverTripsIdPingsPostRequestPingsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverTripsIdPingsPostRequestPingsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverTripsIdPingsPostRequestPingsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverTripsIdPingsPostRequestPingsInner> mapFromJson(dynamic json) {
    final map = <String, DriverTripsIdPingsPostRequestPingsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverTripsIdPingsPostRequestPingsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverTripsIdPingsPostRequestPingsInner-objects as value to a dart map
  static Map<String, List<DriverTripsIdPingsPostRequestPingsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverTripsIdPingsPostRequestPingsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverTripsIdPingsPostRequestPingsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lat',
    'lng',
    'recordedAt',
    'seq',
  };
}

