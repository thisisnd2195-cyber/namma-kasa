import 'package:flutter_test/flutter_test.dart';
import 'package:namma_kasa/src/driver/ping_spool.dart';

void main() {
  group('PingSpool', () {
    late PingSpool spool;

    setUp(() => spool = PingSpool(maxBatch: 5));

    SpooledPing add(PingSpool s, {double lat = 12.96, double? accuracy}) => s.add(
          lat: lat,
          lng: 77.59,
          recordedAt: DateTime.now(),
          accuracy: accuracy,
        );

    test('assigns a monotonic sequence per trip', () {
      expect(add(spool).seq, 0);
      expect(add(spool).seq, 1);
      expect(add(spool).seq, 2);
      expect(spool.pendingCount, 3);
    });

    test('caps a batch at the ingest limit but keeps the rest spooled', () {
      for (var i = 0; i < 12; i++) {
        add(spool);
      }
      expect(spool.takeBatch().length, 5);
      expect(spool.pendingCount, 12);
    });

    test('only forgets pings the server acknowledged', () {
      for (var i = 0; i < 8; i++) {
        add(spool);
      }
      final batch = spool.takeBatch();
      expect(spool.pendingCount, 8);

      spool.acknowledge(batch);
      expect(spool.pendingCount, 3);
      // The survivors are the ones the server never saw.
      expect(spool.takeBatch().first.seq, 5);
    });

    test('a failed delivery leaves the spool intact', () {
      for (var i = 0; i < 4; i++) {
        add(spool);
      }
      spool.takeBatch(); // never acknowledged
      expect(spool.pendingCount, 4);
    });

    test('survives a restart with its sequence intact', () {
      for (var i = 0; i < 3; i++) {
        add(spool, lat: 12.96 + i / 1000);
      }
      final encoded = spool.encode();

      final restored = PingSpool()..restore(encoded);
      expect(restored.pendingCount, 3);
      // Continuing from the right number is what keeps duplicate detection
      // working across an app restart.
      expect(restored.nextSeq, 3);
      expect(restored.takeBatch().first.lat, closeTo(12.96, 0.0001));
    });

    test('replays oldest first so a dead zone is filled in order', () {
      final first = add(spool);
      final second = add(spool);
      final batch = spool.takeBatch();
      expect(batch.first.seq, first.seq);
      expect(batch[1].seq, second.seq);
    });
  });

  group('GpsQuality', () {
    test('stays quiet until it has seen a full window', () {
      final quality = GpsQuality(window: 10);
      for (var i = 0; i < 9; i++) {
        quality.record(500);
      }
      expect(quality.isPoor, isFalse);
    });

    test('flags sustained bad accuracy', () {
      final quality = GpsQuality(window: 10, badRatioThreshold: 0.2);
      for (var i = 0; i < 5; i++) {
        quality.record(500); // bad
      }
      for (var i = 0; i < 5; i++) {
        quality.record(8); // good
      }
      expect(quality.isPoor, isTrue);
    });

    test('tolerates the occasional bad fix', () {
      final quality = GpsQuality(window: 10, badRatioThreshold: 0.2);
      quality.record(500);
      for (var i = 0; i < 9; i++) {
        quality.record(8);
      }
      expect(quality.isPoor, isFalse);
    });
  });
}
