//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResidentHouseholdPatchRequest {
  /// Returns a new [ResidentHouseholdPatchRequest] instance.
  ResidentHouseholdPatchRequest({
    this.fullName,
    this.addressLine,
    this.landmark,
    this.pin,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fullName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? addressLine;

  String? landmark;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ResidentHouseholdPatchRequestPin? pin;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResidentHouseholdPatchRequest &&
    other.fullName == fullName &&
    other.addressLine == addressLine &&
    other.landmark == landmark &&
    other.pin == pin;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fullName == null ? 0 : fullName!.hashCode) +
    (addressLine == null ? 0 : addressLine!.hashCode) +
    (landmark == null ? 0 : landmark!.hashCode) +
    (pin == null ? 0 : pin!.hashCode);

  @override
  String toString() => 'ResidentHouseholdPatchRequest[fullName=$fullName, addressLine=$addressLine, landmark=$landmark, pin=$pin]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.fullName != null) {
      json[r'fullName'] = this.fullName;
    } else {
      json[r'fullName'] = null;
    }
    if (this.addressLine != null) {
      json[r'addressLine'] = this.addressLine;
    } else {
      json[r'addressLine'] = null;
    }
    if (this.landmark != null) {
      json[r'landmark'] = this.landmark;
    } else {
      json[r'landmark'] = null;
    }
    if (this.pin != null) {
      json[r'pin'] = this.pin;
    } else {
      json[r'pin'] = null;
    }
    return json;
  }

  /// Returns a new [ResidentHouseholdPatchRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResidentHouseholdPatchRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ResidentHouseholdPatchRequest(
        fullName: mapValueOfType<String>(json, r'fullName'),
        addressLine: mapValueOfType<String>(json, r'addressLine'),
        landmark: mapValueOfType<String>(json, r'landmark'),
        pin: ResidentHouseholdPatchRequestPin.fromJson(json[r'pin']),
      );
    }
    return null;
  }

  static List<ResidentHouseholdPatchRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResidentHouseholdPatchRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResidentHouseholdPatchRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResidentHouseholdPatchRequest> mapFromJson(dynamic json) {
    final map = <String, ResidentHouseholdPatchRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResidentHouseholdPatchRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResidentHouseholdPatchRequest-objects as value to a dart map
  static Map<String, List<ResidentHouseholdPatchRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResidentHouseholdPatchRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResidentHouseholdPatchRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

