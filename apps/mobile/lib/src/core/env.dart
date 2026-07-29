/// Build-time configuration. Supplied with --dart-define so the same binary
/// can point at local, staging, or production without a code change.
abstract final class Env {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000',
  );

  /// Broker for driver GPS. Empty disables MQTT and forces the HTTPS fallback.
  static const mqttUrl = String.fromEnvironment(
    'MQTT_URL',
    defaultValue: 'mqtt://10.0.2.2:1883',
  );

  /// Zero-cost tiles only — public osm.org servers are prohibited (D-2/DS-06).
  static const mapStyleUrl = String.fromEnvironment(
    'MAP_STYLE_URL',
    defaultValue: 'https://tiles.openfreemap.org/styles/positron',
  );
}
