import type { Locale, WasteType } from "@namma-kasa/shared";

/**
 * Notification copy lives server-side so both apps say the same thing and a
 * wording fix does not need a store release.
 *
 * Distances are rounded to 50 m — GPS is not accurate enough to justify
 * "at 237 m", and the resident's map rounds identically so the two never
 * disagree (Clarifications CHK026).
 */
export function roundDistance(metres: number): number {
  return Math.max(50, Math.round(metres / 50) * 50);
}

const WASTE_LABELS: Record<Locale, Record<WasteType, string>> = {
  en: {
    wet: "Wet",
    dry: "Dry",
    sanitary: "Sanitary",
    hazardous: "Hazardous",
    ewaste: "E-waste",
  },
  kn: {
    wet: "ಹಸಿ ಕಸ",
    dry: "ಒಣ ಕಸ",
    sanitary: "ಸ್ಯಾನಿಟರಿ",
    hazardous: "ಅಪಾಯಕಾರಿ",
    ewaste: "ಇ-ತ್ಯಾಜ್ಯ",
  },
};

export interface NotificationCopy {
  title: string;
  body: string;
}

export function proximityCopy(
  locale: Locale,
  distanceM: number,
  wasteTypes: WasteType[],
): NotificationCopy {
  const rounded = roundDistance(distanceM);
  const labels = wasteTypes.map((w) => WASTE_LABELS[locale][w]).join(" + ");

  if (locale === "kn") {
    return {
      title: `ಆಟೋ ಸುಮಾರು ${rounded} ಮೀ ದೂರದಲ್ಲಿದೆ`,
      body: labels ? `ಇಂದು: ${labels}` : "ಕಸ ಹೊರಗಿಡಿ",
    };
  }
  return {
    title: `Auto is ~${rounded} m away`,
    body: labels ? `Today: ${labels}` : "Please put your waste out",
  };
}

export function arrivalCopy(locale: Locale): NotificationCopy {
  return locale === "kn"
    ? { title: "ಆಟೋ ನಿಮ್ಮ ಬೀದಿಗೆ ಬಂದಿದೆ", body: "ಕಸ ಹೊರಗಿಡಿ" }
    : { title: "Auto has reached your street", body: "Please put your waste out" };
}

export function complaintStatusCopy(locale: Locale, status: string): NotificationCopy {
  const statuses: Record<Locale, Record<string, string>> = {
    en: {
      in_review: "Your complaint is being reviewed",
      resolved: "Your complaint was resolved",
      rejected: "Your complaint was closed",
    },
    kn: {
      in_review: "ನಿಮ್ಮ ದೂರು ಪರಿಶೀಲನೆಯಲ್ಲಿದೆ",
      resolved: "ನಿಮ್ಮ ದೂರು ಪರಿಹರಿಸಲಾಗಿದೆ",
      rejected: "ನಿಮ್ಮ ದೂರು ಮುಚ್ಚಲಾಗಿದೆ",
    },
  };
  return {
    title: statuses[locale][status] ?? statuses.en[status] ?? "Complaint updated",
    body: locale === "kn" ? "ವಿವರಗಳಿಗೆ ಆ್ಯಪ್ ತೆರೆಯಿರಿ" : "Open the app for details",
  };
}

export function scheduleChangeCopy(locale: Locale, note: string): NotificationCopy {
  return locale === "kn"
    ? { title: "ಸಂಗ್ರಹಣೆ ವೇಳಾಪಟ್ಟಿ ಬದಲಾವಣೆ", body: note }
    : { title: "Collection schedule update", body: note };
}
