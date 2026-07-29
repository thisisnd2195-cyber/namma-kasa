//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationsDevicesPostRequest {
  /// Returns a new [NotificationsDevicesPostRequest] instance.
  NotificationsDevicesPostRequest({
    required this.fcmToken,
  });

  String fcmToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationsDevicesPostRequest &&
    other.fcmToken == fcmToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fcmToken.hashCode);

  @override
  String toString() => 'NotificationsDevicesPostRequest[fcmToken=$fcmToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fcmToken'] = this.fcmToken;
    return json;
  }

  /// Returns a new [NotificationsDevicesPostRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationsDevicesPostRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fcmToken'), 'Required key "NotificationsDevicesPostRequest[fcmToken]" is missing from JSON.');
        assert(json[r'fcmToken'] != null, 'Required key "NotificationsDevicesPostRequest[fcmToken]" has a null value in JSON.');
        return true;
      }());

      return NotificationsDevicesPostRequest(
        fcmToken: mapValueOfType<String>(json, r'fcmToken')!,
      );
    }
    return null;
  }

  static List<NotificationsDevicesPostRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationsDevicesPostRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationsDevicesPostRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationsDevicesPostRequest> mapFromJson(dynamic json) {
    final map = <String, NotificationsDevicesPostRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationsDevicesPostRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationsDevicesPostRequest-objects as value to a dart map
  static Map<String, List<NotificationsDevicesPostRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationsDevicesPostRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationsDevicesPostRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fcmToken',
  };
}

