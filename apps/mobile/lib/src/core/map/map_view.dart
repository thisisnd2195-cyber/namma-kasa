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
    this.onCentreChanged,
    this.area,
  });

  final LatLng centre;
  final double zoom;
  final List<MapMarker> markers;
  final ValueChanged<MapController>? onMapReady;

  /// Fires as the map settles. Pin-drop uses a fixed crosshair over a moving
  /// map, so the "pin" is simply wherever the camera has come to rest.
  final ValueChanged<LatLng>? onCentreChanged;

  /// An area to shade — a route's serviceable polygon (FR-DRV-01, DS-06).
  /// Drawn as a soft accent fill with a stronger outline.
  final List<LatLng>? area;

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

  Future<void> _drawArea() async {
    final controller = _controller;
    final area = widget.area;
    if (controller == null || area == null || area.length < 3) return;
    await controller.addFill(
      FillOptions(geometry: [area], fillColor: '#EA580C', fillOpacity: 0.10),
    );
    await controller.addLine(
      LineOptions(geometry: area, lineColor: '#EA580C', lineWidth: 2.5),
    );
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
      onStyleLoadedCallback: () {
        unawaited(_drawArea());
        unawaited(_syncMarkers());
      },
      onCameraIdle: () {
        final centre = _controller?.cameraPosition?.target;
        if (centre != null) widget.onCentreChanged?.call(centre);
      },
      myLocationEnabled: false,
      compassEnabled: false,
    );
  }
}
