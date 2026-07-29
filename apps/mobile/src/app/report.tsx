import { useState } from "react";
import { Alert, Image, Pressable, ScrollView, StyleSheet, Text } from "react-native";
import * as ImagePicker from "expo-image-picker";
import * as Location from "expo-location";
import { router } from "expo-router";
import {
  REPORT_CATEGORIES,
  newReportSchema,
  submitReport,
  type ReportCategory,
} from "@namma-kasa/shared";
import { getSupabase } from "@/lib/supabase";

export default function ReportScreen() {
  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [category, setCategory] = useState<ReportCategory>("illegal_dumping");
  const [busy, setBusy] = useState(false);

  async function takePhoto() {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("Camera access is needed to photograph the spot.");
      return;
    }
    const result = await ImagePicker.launchCameraAsync({ quality: 0.5 });
    if (!result.canceled) {
      setPhotoUri(result.assets[0].uri);
      await captureLocation();
    }
  }

  async function captureLocation() {
    const permission = await Location.requestForegroundPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("Location access is needed to place the report on the map.");
      return;
    }
    const position = await Location.getCurrentPositionAsync({});
    setLocation({ lat: position.coords.latitude, lng: position.coords.longitude });
  }

  async function submit() {
    const supabase = getSupabase();
    if (!supabase) {
      Alert.alert("Backend not configured", "Set EXPO_PUBLIC_SUPABASE_URL and restart.");
      return;
    }
    const parsed = newReportSchema.safeParse({ category, location });
    if (!parsed.success) {
      Alert.alert("Missing details", parsed.error.issues[0]?.message ?? "Check the form");
      return;
    }
    setBusy(true);
    try {
      const report = await submitReport(supabase, parsed.data);
      if (photoUri) {
        const file = await fetch(photoUri).then((r) => r.arrayBuffer());
        const path = `${report.id}/evidence-${Date.now()}.jpg`;
        const { error } = await supabase.storage
          .from("report-photos")
          .upload(path, file, { contentType: "image/jpeg" });
        if (!error) {
          await supabase.from("report_photos").insert({
            report_id: report.id,
            url: supabase.storage.from("report-photos").getPublicUrl(path).data.publicUrl,
            kind: "evidence",
          });
        }
      }
      Alert.alert("Reported!", "Thank you for keeping Bengaluru clean.");
      router.back();
    } catch (err) {
      Alert.alert("Could not submit", err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Pressable style={styles.photoBox} onPress={takePhoto}>
        {photoUri ? (
          <Image source={{ uri: photoUri }} style={styles.photo} />
        ) : (
          <Text style={styles.photoHint}>📸 Tap to take a photo</Text>
        )}
      </Pressable>

      <Text style={styles.label}>
        {location
          ? `📍 ${location.lat.toFixed(5)}, ${location.lng.toFixed(5)}`
          : "📍 Location will be captured with the photo"}
      </Text>

      <Text style={styles.label}>What&apos;s the problem?</Text>
      {REPORT_CATEGORIES.map((option) => (
        <Pressable
          key={option}
          style={[styles.option, category === option && styles.optionSelected]}
          onPress={() => setCategory(option)}
        >
          <Text style={category === option ? styles.optionSelectedText : undefined}>
            {option.replace(/_/g, " ")}
          </Text>
        </Pressable>
      ))}

      <Pressable
        style={[styles.submit, busy && styles.submitDisabled]}
        onPress={submit}
        disabled={busy}
      >
        <Text style={styles.submitText}>{busy ? "Submitting…" : "Submit report"}</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, gap: 10 },
  photoBox: {
    height: 220,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#71717a",
    borderStyle: "dashed",
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
  },
  photo: { width: "100%", height: "100%" },
  photoHint: { fontSize: 16, opacity: 0.7 },
  label: { fontSize: 15, marginTop: 6 },
  option: {
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#71717a",
    padding: 12,
  },
  optionSelected: { backgroundColor: "#16a34a", borderColor: "#16a34a" },
  optionSelectedText: { color: "white", fontWeight: "600" },
  submit: {
    marginTop: 16,
    borderRadius: 12,
    backgroundColor: "#16a34a",
    padding: 16,
    alignItems: "center",
  },
  submitDisabled: { opacity: 0.6 },
  submitText: { color: "white", fontSize: 18, fontWeight: "600" },
});
