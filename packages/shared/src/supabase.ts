import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { newReportSchema, reportSchema, type NewReport, type Report } from "./schemas";

export interface SupabaseConfig {
  url: string;
  anonKey: string;
}

export function createSupabase({ url, anonKey }: SupabaseConfig): SupabaseClient {
  return createClient(url, anonKey);
}

interface ReportRow {
  id: string;
  reporter_id: string | null;
  category: string;
  description: string | null;
  lat: number;
  lng: number;
  ward_id: number | null;
  status: string;
  created_at: string;
  resolved_at: string | null;
  resolution_note: string | null;
}

function rowToReport(row: ReportRow): Report {
  return reportSchema.parse({
    id: row.id,
    reporterId: row.reporter_id,
    category: row.category,
    description: row.description ?? undefined,
    location: { lat: row.lat, lng: row.lng },
    wardId: row.ward_id,
    status: row.status,
    createdAt: row.created_at,
    resolvedAt: row.resolved_at,
    resolutionNote: row.resolution_note,
  });
}

export async function submitReport(supabase: SupabaseClient, input: NewReport): Promise<Report> {
  const report = newReportSchema.parse(input);
  const { data, error } = await supabase
    .from("reports")
    .insert({
      category: report.category,
      description: report.description ?? null,
      location: `SRID=4326;POINT(${report.location.lng} ${report.location.lat})`,
    })
    .select("*")
    .single();
  if (error) throw new Error(`Failed to submit report: ${error.message}`);
  return rowToReport(data as ReportRow);
}

export async function listOpenReports(supabase: SupabaseClient): Promise<Report[]> {
  const { data, error } = await supabase
    .from("reports_public")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(500);
  if (error) throw new Error(`Failed to load reports: ${error.message}`);
  return (data as ReportRow[]).map(rowToReport);
}
