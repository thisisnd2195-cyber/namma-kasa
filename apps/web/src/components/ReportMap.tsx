"use client";

import { useEffect, useRef, useState } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { listOpenReports, type Report } from "@namma-kasa/shared";
import { getSupabase } from "@/lib/supabase";

const BENGALURU_CENTER: [number, number] = [77.5946, 12.9716];

const OSM_STYLE: maplibregl.StyleSpecification = {
  version: 8,
  sources: {
    osm: {
      type: "raster",
      tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      tileSize: 256,
      attribution: "© OpenStreetMap contributors",
    },
  },
  layers: [{ id: "osm", type: "raster", source: "osm" }],
};

const STATUS_COLORS: Record<Report["status"], string> = {
  open: "#dc2626",
  acknowledged: "#f59e0b",
  resolved: "#16a34a",
  verified: "#15803d",
};

export default function ReportMap() {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const [reportCount, setReportCount] = useState<number | null>(null);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: OSM_STYLE,
      center: BENGALURU_CENTER,
      zoom: 11,
    });
    map.addControl(new maplibregl.NavigationControl(), "top-right");
    mapRef.current = map;

    const supabase = getSupabase();
    if (supabase) {
      listOpenReports(supabase)
        .then((reports) => {
          setReportCount(reports.length);
          for (const report of reports) {
            new maplibregl.Marker({ color: STATUS_COLORS[report.status] })
              .setLngLat([report.location.lng, report.location.lat])
              .setPopup(
                new maplibregl.Popup().setHTML(
                  `<a href="/reports/${report.id}"><strong>${report.category.replace(/_/g, " ")}</strong></a><br/>${report.status}`,
                ),
              )
              .addTo(map);
          }
        })
        .catch((err) => console.error("Failed to load reports", err));
    }

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  return (
    <div className="relative h-full w-full">
      <div ref={containerRef} className="h-full w-full" />
      <div className="absolute bottom-4 left-4 rounded-lg bg-white/90 px-3 py-2 text-sm shadow dark:bg-zinc-900/90">
        {reportCount === null
          ? "Supabase not configured — showing empty map"
          : `${reportCount} recent reports`}
      </div>
    </div>
  );
}
