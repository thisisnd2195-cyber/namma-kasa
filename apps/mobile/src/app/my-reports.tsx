import { useEffect, useState } from "react";
import { FlatList, StyleSheet, Text, View } from "react-native";
import { listOpenReports, type Report } from "@namma-kasa/shared";
import { getSupabase } from "@/lib/supabase";

export default function MyReportsScreen() {
  const [reports, setReports] = useState<Report[] | null>(null);
  const [error, setError] = useState<string | null>(() =>
    getSupabase() ? null : "Backend not configured — set EXPO_PUBLIC_SUPABASE_URL.",
  );

  useEffect(() => {
    const supabase = getSupabase();
    if (!supabase) return;
    listOpenReports(supabase)
      .then(setReports)
      .catch((err) => setError(err instanceof Error ? err.message : String(err)));
  }, []);

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.muted}>{error}</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={reports ?? []}
      keyExtractor={(item) => item.id}
      contentContainerStyle={styles.list}
      ListEmptyComponent={
        <View style={styles.center}>
          <Text style={styles.muted}>
            {reports === null ? "Loading…" : "No reports yet. Be the first!"}
          </Text>
        </View>
      }
      renderItem={({ item }) => (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>{item.category.replace(/_/g, " ")}</Text>
          <Text style={styles.muted}>
            {item.status} · {item.createdAt.toLocaleDateString()}
          </Text>
        </View>
      )}
    />
  );
}

const styles = StyleSheet.create({
  list: { padding: 16, gap: 10 },
  center: { flex: 1, alignItems: "center", justifyContent: "center", padding: 24 },
  muted: { opacity: 0.7 },
  card: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#71717a",
    padding: 14,
    gap: 4,
  },
  cardTitle: { fontSize: 16, fontWeight: "600", textTransform: "capitalize" },
});
