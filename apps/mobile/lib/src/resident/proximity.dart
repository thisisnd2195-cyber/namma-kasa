import 'dart:math';

import '../../l10n/app_localizations.dart';

/// How far away the auto is, and how that gets phrased.
///
/// These live outside the widget because they are the numbers the resident
/// acts on, and because they have to agree with the server: the proximity push
/// is decided by `ST_DWithin` on a geography, so the app must not compute a
/// distance of its own that says something different.

/// Metres per degree of latitude. Longitude degrees shorten by cos(latitude);
/// 0.97 is Bengaluru's ~13°N, which is the only city this ships to.
const _metresPerDegree = 111_320.0;
const _lngScaleAtBengaluru = 0.97;

/// Below this the auto is effectively here, and a number would be false
/// precision against GPS error.
const atStreetThresholdM = 50;

/// Working pace of an auto on its round, in metres per second.
///
/// Derived from the spec's own two numbers rather than invented: the default
/// alert radius is 300 m (FR-RES-05) and the illustrative hint at that radius
/// is "~6 min away" (FR-RES-03) — 300 m over 360 s. It is slow because a
/// door-to-door auto stops at every house; this is progress along the street,
/// not road speed.
const workingPaceMps = 300 / 360;

/// Straight-line metres between the house pin and the auto.
///
/// Over the few hundred metres that matter here an equirectangular
/// approximation sits within a metre of the great-circle distance the server
/// uses — but only if the hypotenuse is actually taken. Summing the two legs
/// gives the Manhattan distance, which overstates a diagonal by 41% and makes
/// the map disagree with the push notification.
int distanceMetres(double pinLat, double pinLng, double lat, double lng) {
  final dLat = (lat - pinLat) * _metresPerDegree;
  final dLng = (lng - pinLng) * _metresPerDegree * _lngScaleAtBengaluru;
  return sqrt(dLat * dLat + dLng * dLng).round();
}

/// Coarse minutes, or null when the auto is close enough that a countdown
/// would be noise rather than information (FR-RES-03).
int? minutesAway(int metres) {
  if (metres < atStreetThresholdM) return null;
  final minutes = (metres / workingPaceMps / 60).round();
  return minutes < 1 ? 1 : minutes;
}

/// Rounded to 50 m, matching the notification copy, so the map and the push
/// never disagree about how far away the auto is.
String distanceLabel(int metres, L10n l10n) {
  if (metres < atStreetThresholdM) return l10n.atYourStreet;
  final rounded = (metres / 50).round() * 50;
  return rounded >= 1000
      ? '${(rounded / 1000).toStringAsFixed(1)} km away'
      : '$rounded m away';
}
