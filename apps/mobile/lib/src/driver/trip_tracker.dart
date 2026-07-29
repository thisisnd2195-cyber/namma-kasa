import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../core/api.dart';
import '../core/env.dart';
import 'ping_spool.dart';

/// Emit cadence from FR-DRV-03: whichever of these comes first.
const _intervalSeconds = 5;
const _distanceFilterM = 25;

enum TrackingState { idle, running, degraded }

class TripTrackerStatus {
  const TripTrackerStatus({
    required this.state,
    required this.pendingPings,
    required this.sentPings,
    this.poorGps = false,
    this.message,
    this.idleMinutes = 0,
  });

  final TrackingState state;
  final int pendingPings;
  final int sentPings;
  final bool poorGps;
  final String? message;

  /// Minutes since the auto last actually moved, used to prompt the driver.
  final int idleMinutes;

  TripTrackerStatus copyWith({
    TrackingState? state,
    int? pendingPings,
    int? sentPings,
    bool? poorGps,
    String? message,
    int? idleMinutes,
  }) =>
      TripTrackerStatus(
        state: state ?? this.state,
        pendingPings: pendingPings ?? this.pendingPings,
        sentPings: sentPings ?? this.sentPings,
        poorGps: poorGps ?? this.poorGps,
        message: message,
        idleMinutes: idleMinutes ?? this.idleMinutes,
      );

  static const initial = TripTrackerStatus(
    state: TrackingState.idle,
    pendingPings: 0,
    sentPings: 0,
  );
}

/// Streams the auto's position while a trip is active.
///
/// MQTT is the primary path; when the broker is unreachable the spool grows and
/// drains over HTTPS instead. Either way nothing is discarded until the server
/// has acknowledged it.
class TripTracker extends StateNotifier<TripTrackerStatus> {
  TripTracker(this._api) : super(TripTrackerStatus.initial);

  final Api _api;
  final PingSpool _spool = PingSpool();
  final GpsQuality _quality = GpsQuality();

  StreamSubscription<Position>? _positions;
  Timer? _flushTimer;
  MqttServerClient? _mqtt;
  String? _tripId;
  double _distanceM = 0;
  Position? _previous;
  DateTime? _lastMovedAt;

  int get distanceCoveredM => _distanceM.round();

  /// Android stops background location for an app without a foreground
  /// service, and a collection round is mostly spent with the phone in a
  /// pocket. Without this the trail has holes exactly where the work happened
  /// (FR-DRV-03, FR-DRV-04).
  Future<void> _startForegroundService(String registration) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'namma_kasa_tracking',
        channelName: 'Collection trip',
        channelDescription: 'Shown while your location is being shared.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_intervalSeconds * 1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Sharing location',
      notificationText: 'Trip in progress · $registration',
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Asks for the exemptions OEM battery managers need, in the order that
  /// produces the fewest dialogs (Xiaomi, Oppo and Vivo kill unexempted apps).
  Future<void> requestTrackingPermissions() async {
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    final notifications = await FlutterForegroundTask.checkNotificationPermission();
    if (notifications != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> start(String tripId, {String registration = ''}) async {
    if (state.state == TrackingState.running) return;
    _tripId = tripId;
    _spool.clear();
    _quality.reset();
    _distanceM = 0;
    _previous = null;
    _lastMovedAt = null;

    await _startForegroundService(registration);
    await _connectMqtt(tripId);

    _positions = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterM,
      ),
    ).listen(_onPosition, onError: (Object error) {
      state = state.copyWith(message: 'Location error: $error');
    });

    // The distance filter alone goes silent when the auto is stopped, which
    // reads as a tracking gap; this keeps the heartbeat going.
    _flushTimer = Timer.periodic(const Duration(seconds: _intervalSeconds), (_) {
      unawaited(_flush());
    });

    state = state.copyWith(state: TrackingState.running, message: null);
  }

  Future<void> stop() async {
    await _positions?.cancel();
    _positions = null;
    _flushTimer?.cancel();
    _flushTimer = null;

    await _flush();
    _mqtt?.disconnect();
    _mqtt = null;
    _tripId = null;
    await _stopForegroundService();
    state = TripTrackerStatus.initial;
  }

  void _onPosition(Position position) {
    if (_previous != null) {
      final moved = Geolocator.distanceBetween(
        _previous!.latitude,
        _previous!.longitude,
        position.latitude,
        position.longitude,
      );
      if (moved > _distanceFilterM) _lastMovedAt = DateTime.now();
      _distanceM += Geolocator.distanceBetween(
        _previous!.latitude,
        _previous!.longitude,
        position.latitude,
        position.longitude,
      );
    }
    _previous = position;

    _quality.record(position.accuracy);
    _spool.add(
      lat: position.latitude,
      lng: position.longitude,
      recordedAt: position.timestamp,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
    );

    _lastMovedAt ??= DateTime.now();
    state = state.copyWith(
      pendingPings: _spool.pendingCount,
      poorGps: _quality.isPoor,
      idleMinutes: DateTime.now().difference(_lastMovedAt!).inMinutes,
    );
  }

  Future<void> _flush() async {
    final tripId = _tripId;
    if (tripId == null) return;

    final batch = _spool.takeBatch();
    if (batch.isEmpty) return;

    final payload = batch.map((p) => p.toJson()).toList();
    try {
      final client = _mqtt;
      if (client != null && client.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
        client.publishMessage('trips/$tripId/pings', MqttQos.atLeastOnce, builder.payload!);
      } else {
        await _api.postPings(tripId, payload);
      }

      _spool.acknowledge(batch);
      state = state.copyWith(
        state: TrackingState.running,
        pendingPings: _spool.pendingCount,
        sentPings: state.sentPings + batch.length,
        message: null,
      );
    } catch (_) {
      // Keep everything spooled; a dead zone must not cost us the trail.
      state = state.copyWith(
        state: TrackingState.degraded,
        pendingPings: _spool.pendingCount,
        message: 'Offline — ${_spool.pendingCount} updates waiting',
      );
    }
  }

  Future<void> _connectMqtt(String tripId) async {
    if (Env.mqttUrl.isEmpty) return;
    final uri = Uri.parse(Env.mqttUrl);
    final client = MqttServerClient.withPort(uri.host, 'driver-$tripId', uri.port)
      ..logging(on: false)
      ..keepAlivePeriod = 30
      ..autoReconnect = true;

    try {
      // The broker denies anything without a per-trip token whose ACL grants
      // publish to exactly this trip's topic.
      final credentials = await _api.mqttToken(tripId);
      await client.connect(
        credentials['username'] as String,
        credentials['password'] as String,
      );
      _mqtt = client;
    } catch (_) {
      // HTTPS fallback covers this; not worth failing the trip over.
      client.disconnect();
      _mqtt = null;
    }
  }

  @override
  void dispose() {
    _positions?.cancel();
    _flushTimer?.cancel();
    _mqtt?.disconnect();
    super.dispose();
  }
}

final tripTrackerProvider =
    StateNotifierProvider<TripTracker, TripTrackerStatus>((ref) => TripTracker(ref.watch(apiProvider)));
