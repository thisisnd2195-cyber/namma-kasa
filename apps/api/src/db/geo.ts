import { sql, type RawBuilder } from "kysely";
import type { GeoJsonArea, LatLng } from "@namma-kasa/shared";

/**
 * PostGIS helpers. Geometry never crosses the app boundary as WKB — areas go
 * in and out as GeoJSON, points as {lat, lng}.
 */

export function pointFromLatLng({ lat, lng }: LatLng): RawBuilder<string> {
  return sql`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`;
}

/** Accepts Polygon or MultiPolygon GeoJSON; always stores MultiPolygon. */
export function multiPolygonFromGeoJson(area: GeoJsonArea): RawBuilder<string> {
  return sql`ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(${JSON.stringify(area)}), 4326))`;
}

export function asGeoJson(column: string): RawBuilder<string> {
  return sql`ST_AsGeoJSON(${sql.ref(column)})`;
}

export function latOf(column: string): RawBuilder<number> {
  return sql`ST_Y(${sql.ref(column)})`;
}

export function lngOf(column: string): RawBuilder<number> {
  return sql`ST_X(${sql.ref(column)})`;
}

/** Metre distance between a geometry column and a point, via geography cast. */
export function distanceMeters(column: string, point: LatLng): RawBuilder<number> {
  return sql`ST_Distance(${sql.ref(column)}::geography, ${pointFromLatLng(point)}::geography)`;
}
