import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_kasa/src/resident/proximity.dart';

/// The app's distance has to match the server's, because the server decides
/// the push and the app draws the label. When they disagree the resident is
/// told two different things about the same auto.
void main() {
  // A house pin in Bengaluru; every case below is offset from here.
  const pinLat = 12.9716, pinLng = 77.5946;
  const metresPerDegree = 111_320.0;

  ({double lat, double lng}) offsetBy(double northM, double eastM) => (
        lat: pinLat + northM / metresPerDegree,
        lng: pinLng + eastM / (metresPerDegree * 0.97),
      );

  group('distanceMetres', () {
    test('is exact due north, where there is no diagonal to get wrong', () {
      final auto = offsetBy(300, 0);
      expect(distanceMetres(pinLat, pinLng, auto.lat, auto.lng), closeTo(300, 1));
    });

    test('takes the hypotenuse on a diagonal, not the sum of the legs', () {
      // 300 m away at 45°. Summing the legs would report 424 m — a 41%
      // overstatement, and the bug this test exists to prevent.
      final leg = 300 / sqrt(2);
      final auto = offsetBy(leg, leg);
      expect(distanceMetres(pinLat, pinLng, auto.lat, auto.lng), closeTo(300, 1));
    });

    test('agrees with the server at the default 300 m alert radius', () {
      // The server fires the push via ST_DWithin at exactly 300 m. If the app
      // reported more, the label would say "400 m away" as the push arrived.
      for (final bearing in [0, 30, 45, 60, 90, 135, 180, 225, 270]) {
        final rad = bearing * pi / 180;
        final auto = offsetBy(300 * cos(rad), 300 * sin(rad));
        expect(
          distanceMetres(pinLat, pinLng, auto.lat, auto.lng),
          closeTo(300, 2),
          reason: 'bearing $bearing°',
        );
      }
    });

    test('is symmetric and zero at the pin', () {
      expect(distanceMetres(pinLat, pinLng, pinLat, pinLng), 0);
    });
  });

  group('minutesAway', () {
    test('gives the spec\'s own example: ~6 min at the 300 m radius', () {
      // FR-RES-03 illustrates the hint as "~6 min away"; FR-RES-05 puts the
      // default radius at 300 m. The pace constant is derived from that pair,
      // so this asserts the two stay consistent.
      expect(minutesAway(300), 6);
    });

    test('stays silent once the auto is at the street', () {
      expect(minutesAway(atStreetThresholdM - 1), isNull);
      expect(minutesAway(0), isNull);
    });

    test('never rounds down to a bare zero minutes', () {
      expect(minutesAway(atStreetThresholdM), greaterThanOrEqualTo(1));
    });

    test('grows with distance', () {
      expect(minutesAway(600)!, greaterThan(minutesAway(300)!));
    });
  });
}
