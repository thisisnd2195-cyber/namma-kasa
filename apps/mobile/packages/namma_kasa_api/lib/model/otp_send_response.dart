//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OtpSendResponse {
  /// Returns a new [OtpSendResponse] instance.
  OtpSendResponse({
    required this.resendAfterSec,
  });

  int resendAfterSec;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OtpSendResponse &&
    other.resendAfterSec == resendAfterSec;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (resendAfterSec.hashCode);

  @override
  String toString() => 'OtpSendResponse[resendAfterSec=$resendAfterSec]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'resendAfterSec'] = this.resendAfterSec;
    return json;
  }

  /// Returns a new [OtpSendResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OtpSendResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'resendAfterSec'), 'Required key "OtpSendResponse[resendAfterSec]" is missing from JSON.');
        assert(json[r'resendAfterSec'] != null, 'Required key "OtpSendResponse[resendAfterSec]" has a null value in JSON.');
        return true;
      }());

      return OtpSendResponse(
        resendAfterSec: mapValueOfType<int>(json, r'resendAfterSec')!,
      );
    }
    return null;
  }

  static List<OtpSendResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OtpSendResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OtpSendResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OtpSendResponse> mapFromJson(dynamic json) {
    final map = <String, OtpSendResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OtpSendResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OtpSendResponse-objects as value to a dart map
  static Map<String, List<OtpSendResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OtpSendResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OtpSendResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'resendAfterSec',
  };
}

