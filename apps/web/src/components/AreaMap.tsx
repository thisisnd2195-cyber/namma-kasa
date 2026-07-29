"use client";

import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { useEffect, useRef } from "react";
import { TerraDraw, TerraDrawPolygonMode, TerraDrawSelectMode } from "terra-draw";
import { TerraDrawMapLibreGLAdapter } from "terra-draw-maplibre-gl-adapter";

export type Area = { type: "Polygon" | "MultiPolygon"; coordinates: unknown };

interface AreaMapProps {
  /** Read-only shapes drawn underneath, e.g. the ward a route must sit inside. */
  context?: { area: Area; color: string; label?: string }[];
  /** Shape currently being edited, if any. */
  value?: Area | null;
  onChange?: (area: Area | null) => void;
  /** Intersection geometry from a 409, drawn in red so the clash is visible. */
  conflict?: Area | null;
  editable?: boolean;
  className?: string;
}

const BENGALURU: [number, number] = [77.5946, 12.9716];

/** Neutral basemap so status colours carry the meaning (DS-06). */
const STYLE = "https://tiles.openfreemap.org/styles/positron";

export function AreaMap({
  context = [],
  value,
  onChange,
  conflict,
  editable = false,
  className = "h-[420px] w-full",
}: AreaMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const drawRef = useRef<TerraDraw | null>(null);
  // Held in a ref so the draw instance always calls the latest handler without
  // being torn down and rebuilt on every render.
  const onChangeRef = useRef(onChange);
  useEffect(() => {
    onChangeRef.current = onChange;
  }, [onChange]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: STYLE,
      center: BENGALURU,
      zoom: 11,
    });
    map.addControl(new maplibregl.NavigationControl(), "top-right");
    mapRef.current = map;

    map.on("load", () => {
      if (editable) {
        const draw = new TerraDraw({
          adapter: new TerraDrawMapLibreGLAdapter({ map }),
          modes: [new TerraDrawPolygonMode(), new TerraDrawSelectMode({
            flags: {
              polygon: {
                feature: {
                  draggable: true,
                  coordinates: { midpoints: true, draggable: true, deletable: true },
                },
              },
            },
          })],
        });
        draw.start();
        draw.setMode("polygon");
        draw.on("finish", () => {
          const features = draw.getSnapshot();
          const polygon = features.find((f) => f.geometry.type === "Polygon");
          onChangeRef.current?.(polygon ? (polygon.geometry as Area) : null);
          draw.setMode("select");
        });
        draw.on("change", () => {
          const features = draw.getSnapshot();
          const polygon = features.find((f) => f.geometry.type === "Polygon");
          if (polygon) onChangeRef.current?.(polygon.geometry as Area);
        });
        drawRef.current = draw;
      }
    });

    return () => {
      drawRef.current?.stop();
      drawRef.current = null;
      map.remove();
      mapRef.current = null;
    };
  }, [editable]);

  // Context shapes and the conflict overlay are plain layers, not draw state.
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    const render = () => {
      const layers: { id: string; area: Area; color: string; opacity: number }[] = [
        ...context.map((c, i) => ({
          id: `ctx-${i}`,
          area: c.area,
          color: c.color,
          opacity: 0.12,
        })),
        ...(conflict ? [{ id: "conflict", area: conflict, color: "#D93025", opacity: 0.45 }] : []),
      ];

      for (const layer of layers) {
        const sourceId = `src-${layer.id}`;
        const data = {
          type: "Feature" as const,
          properties: {},
          geometry: layer.area as never,
        };
        const existing = map.getSource(sourceId) as maplibregl.GeoJSONSource | undefined;
        if (existing) {
          existing.setData(data);
          continue;
        }
        map.addSource(sourceId, { type: "geojson", data });
        map.addLayer({
          id: `fill-${layer.id}`,
          type: "fill",
          source: sourceId,
          paint: { "fill-color": layer.color, "fill-opacity": layer.opacity },
        });
        map.addLayer({
          id: `line-${layer.id}`,
          type: "line",
          source: sourceId,
          paint: { "line-color": layer.color, "line-width": 2 },
        });
      }

      // Frame whatever is on screen.
      const target = conflict ?? context[0]?.area ?? value;
      if (target) {
        const bounds = boundsOf(target);
        if (bounds) map.fitBounds(bounds, { padding: 48, duration: 400, maxZoom: 15 });
      }
    };

    if (map.isStyleLoaded()) render();
    else map.once("load", render);
  }, [context, conflict, value]);

  return <div ref={containerRef} className={className} />;
}

function boundsOf(area: Area): maplibregl.LngLatBoundsLike | null {
  const coords = flatten(area.coordinates);
  if (coords.length === 0) return null;
  const lngs = coords.map((c) => c[0]);
  const lats = coords.map((c) => c[1]);
  return [
    [Math.min(...lngs), Math.min(...lats)],
    [Math.max(...lngs), Math.max(...lats)],
  ];
}

function flatten(input: unknown): [number, number][] {
  if (!Array.isArray(input)) return [];
  if (typeof input[0] === "number" && typeof input[1] === "number") {
    return [[input[0], input[1]]];
  }
  return input.flatMap((item) => flatten(item));
}
