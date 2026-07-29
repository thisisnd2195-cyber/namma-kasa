import 'dart:convert';

/// One GPS sample, in the shape the ingest endpoint expects.
class SpooledPing {
  const SpooledPing({
    required this.lat,
    required this.lng,
    required this.recordedAt,
    required this.seq,
    this.speed,
    this.heading,
    this.accuracy,
  });

  final double lat;
  final double lng;
  final DateTime recordedAt;
  final int seq;
  final double? speed;
  final double? heading;
  final double? accuracy;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'seq': seq,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        if (accuracy != null) 'accuracy': accuracy,
      };

  static SpooledPing fromJson(Map<String, dynamic> json) => SpooledPing(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        seq: (json['seq'] as num).toInt(),
        speed: (json['speed'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
      );
}

/// Holds pings a device could not deliver yet.
///
/// The spool is unbounded for the duration of a trip: a driver can spend twenty
/// minutes in a dead zone, and dropping that stretch would leave a hole in the
/// very trail that proves the street was served. Batches are capped only on the
/// way out, because the ingest endpoint accepts at most 20 at a time.
class PingSpool {
  PingSpool({this.maxBatch = 20});

  final int maxBatch;
  final List<SpooledPing> _pending = [];
  int _nextSeq = 0;

  int get pendingCount => _pending.length;
  int get nextSeq => _nextSeq;

  /// Assigns the per-trip sequence number used to drop duplicate redeliveries.
  SpooledPing add({
    required double lat,
    required double lng,
    required DateTime recordedAt,
    double? speed,
    double? heading,
    double? accuracy,
  }) {
    final ping = SpooledPing(
      lat: lat,
      lng: lng,
      recordedAt: recordedAt,
      seq: _nextSeq++,
      speed: speed,
      heading: heading,
      accuracy: accuracy,
    );
    _pending.add(ping);
    return ping;
  }

  /// Oldest-first, so a reconnect replays the dead zone in the order it happened.
  List<SpooledPing> takeBatch() {
    if (_pending.isEmpty) return const [];
    final count = _pending.length < maxBatch ? _pending.length : maxBatch;
    return _pending.sublist(0, count);
  }

  /// Called only after the server has accepted them.
  void acknowledge(List<SpooledPing> delivered) {
    if (delivered.isEmpty) return;
    final highest = delivered.map((p) => p.seq).reduce((a, b) => a > b ? a : b);
    _pending.removeWhere((ping) => ping.seq <= highest);
  }

  void clear() {
    _pending.clear();
    _nextSeq = 0;
  }

  String encode() => jsonEncode(_pending.map((p) => p.toJson()).toList());

  void restore(String encoded) {
    final decoded = jsonDecode(encoded) as List<dynamic>;
    _pending
      ..clear()
      ..addAll(decoded.map((item) => SpooledPing.fromJson(item as Map<String, dynamic>)));
    _nextSeq = _pending.isEmpty
        ? 0
        : _pending.map((p) => p.seq).reduce((a, b) => a > b ? a : b) + 1;
  }
}

/// Rolling quality check: sustained bad GPS is worth telling the driver about,
/// because it means their trail — and their proof of service — has holes.
class GpsQuality {
  GpsQuality({this.window = 60, this.badRatioThreshold = 0.2, this.maxAccuracyM = 100});

  final int window;
  final double badRatioThreshold;
  final double maxAccuracyM;
  final List<bool> _recent = [];

  void record(double? accuracy) {
    _recent.add((accuracy ?? 0) > maxAccuracyM);
    if (_recent.length > window) _recent.removeAt(0);
  }

  /// Needs a full window before complaining, so one bad fix stays quiet.
  bool get isPoor {
    if (_recent.length < window) return false;
    final bad = _recent.where((isBad) => isBad).length;
    return bad / _recent.length > badRatioThreshold;
  }

  void reset() => _recent.clear();
}
