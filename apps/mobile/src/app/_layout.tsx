import { DarkTheme, DefaultTheme, ThemeProvider, Stack } from "expo-router";
import { useColorScheme } from "react-native";

export default function RootLayout() {
  const colorScheme = useColorScheme();
  return (
    <ThemeProvider value={colorScheme === "dark" ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="index" options={{ title: "Namma Kasa" }} />
        <Stack.Screen name="report" options={{ title: "Report a black spot" }} />
        <Stack.Screen name="my-reports" options={{ title: "Recent reports" }} />
      </Stack>
    </ThemeProvider>
  );
}
