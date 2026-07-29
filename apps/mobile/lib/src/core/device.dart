import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A stable per-install identifier. Drivers are limited to one active device,
/// so this value decides whether a sign-in counts as "the same phone".
Future<String> deviceIdentifier() async {
  const storage = FlutterSecureStorage();
  const key = 'device-id';
  final existing = await storage.read(key: key);
  if (existing != null) return existing;

  final generated = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  await storage.write(key: key, value: generated);
  return generated;
}
