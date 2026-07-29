//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentHomeServingAutosInner {
  /// Returns a new [ResidentHomeServingAutosInner] instance.
  ResidentHomeServingAutosInner({
    required this.tripId,
    required this.registrationNumber,
    required this.passNumber,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.at,
    required this.distanceM,
  });

  String tripId;

  String registrationNumber;

  int passNumber;

  num lat;

  num lng;

  num? heading;

  String at;

  int distanceM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentHomeServingAutosInner &&
    other.tripId == tripId &&
    other.registrationNumber == registrationNumber &&
    other.passNumber == passNumber &&
    other.lat == lat &&
    other.lng == lng &&
    other.heading == heading &&
    other.at == at &&
    other.distanceM == distanceM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tripId.hashCode) +
    (registrationNumber.hashCode) +
    (passNumber.hashCode) +
    (lat.hashCode) +
    (lng.hashCode) +
    (heading == null ? 0 : heading!.hashCode) +
    (at.hashCode) +
    (distanceM.hashCode);

  @override
  String toString() => 'ResidentHomeServingAutosInner[tripId=$tripId, registrationNumber=$registrationNumber, passNumber=$passNumber, lat=$lat, lng=$lng, heading=$heading, at=$at, distanceM=$distanceM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'tripId'] = this.tripId;
      json[r'registrationNumber'] = this.registrationNumber;
      json[r'passNumber'] = this.passNumber;
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    if (this.heading != null) {
      json[r'heading'] = this.heading;
    } else {
      json[r'heading'] = null;
    }
      json[r'at'] = this.at;
      json[r'distanceM'] = this.distanceM;
    return json;
  }

  /// Returns a new [ResidentHomeServingAutosInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentHomeServingAutosInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'tripId'), 'Required key "ResidentHomeServingAutosInner[tripId]" is missing from JSON.');
        assert(json[r'tripId'] != null, 'Required key "ResidentHomeServingAutosInner[tripId]" has a null value in JSON.');
        assert(json.containsKey(r'registrationNumber'), 'Required key "ResidentHomeServingAutosInner[registrationNumber]" is missing from JSON.');
        assert(json[r'registrationNumber'] != null, 'Required key "ResidentHomeServingAutosInner[registrationNumber]" has a null value in JSON.');
        assert(json.containsKey(r'passNumber'), 'Required key "ResidentHomeServingAutosInner[passNumber]" is missing from JSON.');
        assert(json[r'passNumber'] != null, 'Required key "ResidentHomeServingAutosInner[passNumber]" has a null value in JSON.');
        assert(json.containsKey(r'lat'), 'Required key "ResidentHomeServingAutosInner[lat]" is missing from JSON.');
        assert(json[r'lat'] != null, 'Required key "ResidentHomeServingAutosInner[lat]" has a null value in JSON.');
        assert(json.containsKey(r'lng'), 'Required key "ResidentHomeServingAutosInner[lng]" is missing from JSON.');
        assert(json[r'lng'] != null, 'Required key "ResidentHomeServingAutosInner[lng]" has a null value in JSON.');
        assert(json.containsKey(r'heading'), 'Required key "ResidentHomeServingAutosInner[heading]" is missing from JSON.');
        assert(json.containsKey(r'at'), 'Required key "ResidentHomeServingAutosInner[at]" is missing from JSON.');
        assert(json[r'at'] != null, 'Required key "ResidentHomeServingAutosInner[at]" has a null value in JSON.');
        assert(json.containsKey(r'distanceM'), 'Required key "ResidentHomeServingAutosInner[distanceM]" is missing from JSON.');
        assert(json[r'distanceM'] != null, 'Required key "ResidentHomeServingAutosInner[distanceM]" has a null value in JSON.');
        return true;
      }());

      return ResidentHomeServingAutosInner(
        tripId: mapValueOfType<String>(json, r'tripId')!,
        registrationNumber: mapValueOfType<String>(json, r'registrationNumber')!,
        passNumber: mapValueOfType<int>(json, r'passNumber')!,
        lat: num.parse('${json[r'lat']}'),
        lng: num.parse('${json[r'lng']}'),
        heading: json[r'heading'] == null
            ? null
            : num.parse('${json[r'heading']}'),
        at: mapValueOfType<String>(json, r'at')!,
        distanceM: mapValueOfType<int>(json, r'distanceM')!,
      );
    }
    return null;
  }

  static List<ResidentHomeServingAutosInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentHomeServingAutosInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentHomeServingAutosInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentHomeServingAutosInner> mapFromJson(dynamic json) {
    final map = <String, ResidentHomeServingAutosInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentHomeServingAutosInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentHomeServingAutosInner-objects as value to a dart map
  static Map<String, List<ResidentHomeServingAutosInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentHomeServingAutosInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentHomeServingAutosInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tripId',
    'registrationNumber',
    'passNumber',
    'lat',
    'lng',
    'heading',
    'at',
    'distanceM',
  };
}

