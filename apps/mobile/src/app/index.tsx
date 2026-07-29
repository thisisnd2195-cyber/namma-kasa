import { Link } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>ನಮ್ಮ ಕಸ</Text>
      <Text style={styles.subtitle}>Spot garbage? Report it in 30 seconds.</Text>

      <Link href="/report" asChild>
        <Pressable style={[styles.button, styles.primary]}>
          <Text style={styles.primaryText}>📸 Report a black spot</Text>
        </Pressable>
      </Link>

      <Link href="/my-reports" asChild>
        <Pressable style={styles.button}>
          <Text style={styles.buttonText}>🗂 Recent reports</Text>
        </Pressable>
      </Link>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: "center", padding: 24, gap: 12 },
  title: { fontSize: 40, fontWeight: "700", textAlign: "center" },
  subtitle: { fontSize: 16, textAlign: "center", opacity: 0.7, marginBottom: 24 },
  button: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#71717a",
    padding: 16,
    alignItems: "center",
  },
  primary: { backgroundColor: "#16a34a", borderColor: "#16a34a" },
  primaryText: { color: "white", fontSize: 18, fontWeight: "600" },
  buttonText: { fontSize: 18 },
});
