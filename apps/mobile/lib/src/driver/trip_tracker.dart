import 'dart:async';
import 'dart:convert';

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
  });

  final TrackingState state;
  final int pendingPings;
  final int sentPings;
  final bool poorGps;
  final String? message;

  TripTrackerStatus copyWith({
    TrackingState? state,
    int? pendingPings,
    int? sentPings,
    bool? poorGps,
    String? message,
  }) =>
      TripTrackerStatus(
        state: state ?? this.state,
        pendingPings: pendingPings ?? this.pendingPings,
        sentPings: sentPings ?? this.sentPings,
        poorGps: poorGps ?? this.poorGps,
        message: message,
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

  int get distanceCoveredM => _distanceM.round();

  Future<void> start(String tripId) async {
    if (state.state == TrackingState.running) return;
    _tripId = tripId;
    _spool.clear();
    _quality.reset();
    _distanceM = 0;
    _previous = null;

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
    state = TripTrackerStatus.initial;
  }

  void _onPosition(Position position) {
    if (_previous != null) {
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

    state = state.copyWith(
      pendingPings: _spool.pendingCount,
      poorGps: _quality.isPoor,
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
      await client.connect();
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
