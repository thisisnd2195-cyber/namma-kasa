//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OtpVerifyRequest {
  /// Returns a new [OtpVerifyRequest] instance.
  OtpVerifyRequest({
    required this.phone,
    required this.code,
  });

  String phone;

  String code;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OtpVerifyRequest &&
    other.phone == phone &&
    other.code == code;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (phone.hashCode) +
    (code.hashCode);

  @override
  String toString() => 'OtpVerifyRequest[phone=$phone, code=$code]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'phone'] = this.phone;
      json[r'code'] = this.code;
    return json;
  }

  /// Returns a new [OtpVerifyRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OtpVerifyRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'phone'), 'Required key "OtpVerifyRequest[phone]" is missing from JSON.');
        assert(json[r'phone'] != null, 'Required key "OtpVerifyRequest[phone]" has a null value in JSON.');
        assert(json.containsKey(r'code'), 'Required key "OtpVerifyRequest[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "OtpVerifyRequest[code]" has a null value in JSON.');
        return true;
      }());

      return OtpVerifyRequest(
        phone: mapValueOfType<String>(json, r'phone')!,
        code: mapValueOfType<String>(json, r'code')!,
      );
    }
    return null;
  }

  static List<OtpVerifyRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OtpVerifyRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OtpVerifyRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OtpVerifyRequest> mapFromJson(dynamic json) {
    final map = <String, OtpVerifyRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OtpVerifyRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OtpVerifyRequest-objects as value to a dart map
  static Map<String, List<OtpVerifyRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OtpVerifyRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OtpVerifyRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'phone',
    'code',
  };
}

