/// Per-manufacturer instructions for keeping background tracking alive
/// (FR-DRV-04).
///
/// Android's standard battery-optimization exemption is not enough on most
/// phones sold in India: Xiaomi, Oppo, Vivo and their sub-brands each add a
/// separate "Autostart" or "background permission" screen, buried somewhere
/// different in every skin. A driver told to "find the setting" will not find
/// it, and the trip stops reporting the moment the screen goes off — which the
/// spec names as the top delivery risk.
///
/// Kept as data, and matched on the manufacturer string Android reports, so
/// adding a brand is a one-line change and needs no new code path.
library;

class OemGuidance {
  const OemGuidance({required this.brand, required this.steps});

  /// Display name, as a driver would recognise it.
  final String brand;

  /// Ordered, each one an action on this phone. Deliberately short.
  final List<String> steps;
}

/// Anything not listed gets Android's own wording, which is accurate even if
/// it is not specific.
const _generic = OemGuidance(
  brand: 'Android',
  steps: [
    'Allow notifications when asked.',
    'Choose "Allow" when asked to ignore battery optimisation.',
  ],
);

/// Keys are lowercase `Build.MANUFACTURER` values.
const _byManufacturer = <String, OemGuidance>{
  'xiaomi': OemGuidance(
    brand: 'Xiaomi / Redmi / POCO',
    steps: [
      'Settings → Apps → Namma Kasa → Autostart: turn on.',
      'Settings → Apps → Namma Kasa → Battery saver: choose "No restrictions".',
      'In Recents, pull the app card down and tap the lock icon.',
    ],
  ),
  'redmi': OemGuidance(
    brand: 'Redmi',
    steps: [
      'Settings → Apps → Namma Kasa → Autostart: turn on.',
      'Settings → Apps → Namma Kasa → Battery saver: choose "No restrictions".',
      'In Recents, pull the app card down and tap the lock icon.',
    ],
  ),
  'poco': OemGuidance(
    brand: 'POCO',
    steps: [
      'Settings → Apps → Namma Kasa → Autostart: turn on.',
      'Settings → Apps → Namma Kasa → Battery saver: choose "No restrictions".',
    ],
  ),
  'oppo': OemGuidance(
    brand: 'OPPO',
    steps: [
      'Settings → Battery → App Battery Management → Namma Kasa: turn on "Allow background activity".',
      'Settings → Apps → Namma Kasa → Auto-launch: turn on.',
    ],
  ),
  'realme': OemGuidance(
    brand: 'realme',
    steps: [
      'Settings → Battery → App Battery Management → Namma Kasa: turn on "Allow background activity".',
      'Settings → Apps → Namma Kasa → Auto-launch: turn on.',
    ],
  ),
  'oneplus': OemGuidance(
    brand: 'OnePlus',
    steps: [
      'Settings → Battery → Battery optimisation → Namma Kasa: choose "Don\'t optimise".',
      'Settings → Apps → Namma Kasa → Allow auto-launch: turn on.',
    ],
  ),
  'vivo': OemGuidance(
    brand: 'vivo',
    steps: [
      'Settings → Battery → High background power consumption: allow Namma Kasa.',
      'Settings → Apps → Autostart: turn on for Namma Kasa.',
    ],
  ),
  'iqoo': OemGuidance(
    brand: 'iQOO',
    steps: [
      'Settings → Battery → High background power consumption: allow Namma Kasa.',
      'Settings → Apps → Autostart: turn on for Namma Kasa.',
    ],
  ),
  'samsung': OemGuidance(
    brand: 'Samsung',
    steps: [
      'Settings → Battery → Background usage limits: remove Namma Kasa from "Sleeping apps".',
      'Settings → Apps → Namma Kasa → Battery: choose "Unrestricted".',
    ],
  ),
  'motorola': OemGuidance(
    brand: 'Motorola',
    steps: [
      'Settings → Battery → Battery optimisation → Namma Kasa: choose "Don\'t optimise".',
    ],
  ),
  'transsion': OemGuidance(
    brand: 'Tecno / Infinix / itel',
    steps: [
      'Settings → Apps → Namma Kasa → Auto-start: turn on.',
      'Phone Master → App Freezer: remove Namma Kasa.',
    ],
  ),
};

/// Steps for a manufacturer string, falling back to generic Android wording.
///
/// Matched on a prefix so sub-brands reported as `xiaomi-redmi` and similar
/// still resolve, rather than silently dropping to the generic text.
OemGuidance oemGuidanceFor(String? manufacturer) {
  if (manufacturer == null || manufacturer.trim().isEmpty) return _generic;
  final key = manufacturer.trim().toLowerCase();

  final exact = _byManufacturer[key];
  if (exact != null) return exact;

  for (final entry in _byManufacturer.entries) {
    if (key.startsWith(entry.key) || key.contains(entry.key)) return entry.value;
  }
  return _generic;
}
