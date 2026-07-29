import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/env.dart';
import '../core/session.dart';

class LiveAuto {
  const LiveAuto({
    required this.tripId,
    required this.registrationNumber,
    required this.passNumber,
    required this.lat,
    required this.lng,
    required this.at,
  });

  final String tripId;
  final String registrationNumber;
  final int passNumber;
  final double lat;
  final double lng;
  final DateTime at;
}

/// Live positions for the resident's own route.
///
/// The server throttles to one frame every two seconds and the marker
/// interpolates between them, which looks smooth without spending the battery
/// a faster stream would cost.
class LiveStream extends StateNotifier<Map<String, LiveAuto>> {
  LiveStream(this._ref) : super(const {});

  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnect;
  int _attempt = 0;
  String? _routeId;

  Future<void> connect(String routeId) async {
    _routeId = routeId;
    await _open();
  }

  Future<void> _open() async {
    final session = _ref.read(sessionProvider);
    final routeId = _routeId;
    if (session == null || routeId == null) return;

    await _close();

    final base = Env.apiBase.replaceFirst(RegExp(r'^http'), 'ws');
    final uri = Uri.parse('$base/v1/live?route_id=$routeId&token=${session.accessToken}');

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _attempt = 0;
      _sub = channel.stream.listen(
        _onFrame,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onFrame(dynamic raw) {
    final frame = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (frame['type']) {
      case 'position':
        final tripId = frame['tripId'] as String;
        state = {
          ...state,
          tripId: LiveAuto(
            tripId: tripId,
            registrationNumber: frame['registrationNumber'] as String,
            passNumber: frame['passNumber'] as int,
            lat: (frame['lat'] as num).toDouble(),
            lng: (frame['lng'] as num).toDouble(),
            at: DateTime.parse(frame['at'] as String),
          ),
        };
      case 'trip_status':
        // The pass is over; drop the marker rather than leaving it frozen.
        final next = {...state}..remove(frame['tripId'] as String);
        state = next;
      case 'reauth':
        // The socket has outlived the token that opened it. Dio has already
        // been refreshing in the background, so reopening picks up the new one.
        unawaited(_open());
    }
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    // Backoff caps at 30 s: a resident watching a map does not need us
    // hammering a server that is already struggling.
    final delay = Duration(seconds: (1 << _attempt).clamp(1, 30));
    _attempt = (_attempt + 1).clamp(0, 5);
    _reconnect = Timer(delay, () => unawaited(_open()));
  }

  Future<void> _close() async {
    _reconnect?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    unawaited(_close());
    super.dispose();
  }
}

final liveStreamProvider =
    StateNotifierProvider<LiveStream, Map<String, LiveAuto>>((ref) => LiveStream(ref));
