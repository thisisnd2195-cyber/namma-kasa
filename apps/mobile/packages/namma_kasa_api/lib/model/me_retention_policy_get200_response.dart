//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MeRetentionPolicyGet200Response {
  /// Returns a new [MeRetentionPolicyGet200Response] instance.
  MeRetentionPolicyGet200Response({
    required this.deletionGraceDays,
    required this.mediaRetentionDays,
    required this.pingRetentionDays,
  });

  int deletionGraceDays;

  int mediaRetentionDays;

  int pingRetentionDays;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MeRetentionPolicyGet200Response &&
    other.deletionGraceDays == deletionGraceDays &&
    other.mediaRetentionDays == mediaRetentionDays &&
    other.pingRetentionDays == pingRetentionDays;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deletionGraceDays.hashCode) +
    (mediaRetentionDays.hashCode) +
    (pingRetentionDays.hashCode);

  @override
  String toString() => 'MeRetentionPolicyGet200Response[deletionGraceDays=$deletionGraceDays, mediaRetentionDays=$mediaRetentionDays, pingRetentionDays=$pingRetentionDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'deletionGraceDays'] = this.deletionGraceDays;
      json[r'mediaRetentionDays'] = this.mediaRetentionDays;
      json[r'pingRetentionDays'] = this.pingRetentionDays;
    return json;
  }

  /// Returns a new [MeRetentionPolicyGet200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeRetentionPolicyGet200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'deletionGraceDays'), 'Required key "MeRetentionPolicyGet200Response[deletionGraceDays]" is missing from JSON.');
        assert(json[r'deletionGraceDays'] != null, 'Required key "MeRetentionPolicyGet200Response[deletionGraceDays]" has a null value in JSON.');
        assert(json.containsKey(r'mediaRetentionDays'), 'Required key "MeRetentionPolicyGet200Response[mediaRetentionDays]" is missing from JSON.');
        assert(json[r'mediaRetentionDays'] != null, 'Required key "MeRetentionPolicyGet200Response[mediaRetentionDays]" has a null value in JSON.');
        assert(json.containsKey(r'pingRetentionDays'), 'Required key "MeRetentionPolicyGet200Response[pingRetentionDays]" is missing from JSON.');
        assert(json[r'pingRetentionDays'] != null, 'Required key "MeRetentionPolicyGet200Response[pingRetentionDays]" has a null value in JSON.');
        return true;
      }());

      return MeRetentionPolicyGet200Response(
        deletionGraceDays: mapValueOfType<int>(json, r'deletionGraceDays')!,
        mediaRetentionDays: mapValueOfType<int>(json, r'mediaRetentionDays')!,
        pingRetentionDays: mapValueOfType<int>(json, r'pingRetentionDays')!,
      );
    }
    return null;
  }

  static List<MeRetentionPolicyGet200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeRetentionPolicyGet200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeRetentionPolicyGet200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeRetentionPolicyGet200Response> mapFromJson(dynamic json) {
    final map = <String, MeRetentionPolicyGet200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeRetentionPolicyGet200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeRetentionPolicyGet200Response-objects as value to a dart map
  static Map<String, List<MeRetentionPolicyGet200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MeRetentionPolicyGet200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeRetentionPolicyGet200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deletionGraceDays',
    'mediaRetentionDays',
    'pingRetentionDays',
  };
}

