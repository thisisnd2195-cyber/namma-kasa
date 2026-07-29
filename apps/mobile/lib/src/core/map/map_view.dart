import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../env.dart';

// Re-exported so screens depend on this abstraction rather than on MapLibre
// directly — the point of keeping the SDK swappable (D-2).
export 'package:maplibre_gl/maplibre_gl.dart' show LatLng, LatLngBounds;

/// Bengaluru city centre, used until a real position is known.
const kBengaluruCentre = LatLng(12.9716, 77.5946);

/// Every map in the app goes through this widget. Keeping MapLibre behind one
/// abstraction is what makes the "swap the map provider without an app
/// rewrite" exit path in D-2 real rather than aspirational.
class MapView extends StatefulWidget {
  const MapView({
    super.key,
    this.centre = kBengaluruCentre,
    this.zoom = 14,
    this.markers = const [],
    this.onMapReady,
  });

  final LatLng centre;
  final double zoom;
  final List<MapMarker> markers;
  final ValueChanged<MapController>? onMapReady;

  @override
  State<MapView> createState() => _MapViewState();
}

class MapMarker {
  const MapMarker({
    required this.id,
    required this.position,
    required this.color,
    this.label,
  });

  final String id;
  final LatLng position;
  final Color color;
  final String? label;
}

/// The surface screens are allowed to drive. Deliberately narrow: anything
/// MapLibre-specific stays inside this file.
class MapController {
  MapController(this._map);

  final MapLibreMapController _map;

  Future<void> moveTo(LatLng position, {double? zoom}) => _map.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom ?? 15),
      );

  Future<void> fitBounds(LatLngBounds bounds) =>
      _map.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: 40, right: 40, top: 40, bottom: 40));
}

class _MapViewState extends State<MapView> {
  MapLibreMapController? _controller;

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) {
      unawaited(_syncMarkers());
    }
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearCircles();
    for (final marker in widget.markers) {
      await controller.addCircle(
        CircleOptions(
          geometry: marker.position,
          circleRadius: 8,
          circleColor:
              '#${marker.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      // Neutral, low-contrast basemap so status colours carry the meaning
      // (DS-06). Never a public osm.org tile server (D-2).
      styleString: Env.mapStyleUrl,
      initialCameraPosition: CameraPosition(target: widget.centre, zoom: widget.zoom),
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapReady?.call(MapController(controller));
      },
      onStyleLoadedCallback: _syncMarkers,
      myLocationEnabled: false,
      compassEnabled: false,
    );
  }
}
