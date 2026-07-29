// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class L10nKn extends L10n {
  L10nKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ನಮ್ಮ ಕಸ';

  @override
  String get roleChooserPrompt => 'ನೀವು ಹೇಗೆ ಸೈನ್ ಇನ್ ಮಾಡಲು ಬಯಸುತ್ತೀರಿ?';

  @override
  String get loginAsResident => 'ನಿವಾಸಿಯಾಗಿ ಲಾಗಿನ್';

  @override
  String get loginAsDriver => 'ಚಾಲಕರಾಗಿ ಲಾಗಿನ್';

  @override
  String get residentHomeTitle => 'ನಿಮ್ಮ ಸಂಗ್ರಹಣೆ';

  @override
  String get driverHomeTitle => 'ನಿಮ್ಮ ಮಾರ್ಗ';

  @override
  String get noActiveTrip => 'ಸದ್ಯಕ್ಕೆ ನಿಮ್ಮ ಮಾರ್ಗದಲ್ಲಿ ಆಟೋ ಇಲ್ಲ';

  @override
  String nextCollection(String window) {
    return 'ಮುಂದಿನ ಸಂಗ್ರಹಣೆ: $window';
  }

  @override
  String passProgress(int current, int total) {
    return '$total ರಲ್ಲಿ $current ನೇ ಸುತ್ತು';
  }

  @override
  String lastCollected(String when) {
    return 'ಕೊನೆಯ ಸಂಗ್ರಹಣೆ $when';
  }

  @override
  String get startTrip => 'ಪ್ರಯಾಣ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get endTrip => 'ಪ್ರಯಾಣ ಮುಗಿಸಿ';

  @override
  String get trackingActive => 'ಸ್ಥಳ ಹಂಚಿಕೊಳ್ಳಲಾಗುತ್ತಿದೆ';

  @override
  String get pendingReview => 'ನಿಮ್ಮ ಮಾರ್ಗವನ್ನು ದೃಢೀಕರಿಸಲಾಗುತ್ತಿದೆ';

  @override
  String get backendUnavailable =>
      'ಲೈವ್ ಟ್ರ್ಯಾಕಿಂಗ್ ಲಭ್ಯವಿಲ್ಲ. ಮರುಪ್ರಯತ್ನಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get reportProblem => 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ';

  @override
  String get rateToday => 'ಇಂದಿನ ಸಂಗ್ರಹಣೆಗೆ ರೇಟಿಂಗ್ ನೀಡಿ';

  @override
  String get sendComplaint => 'ದೂರು ಕಳುಹಿಸಿ';

  @override
  String get complaintSent => 'ನಿಮ್ಮ ವಾರ್ಡ್ ಅಡ್ಮಿನ್‌ಗೆ ಕಳುಹಿಸಲಾಗಿದೆ.';

  @override
  String get yourComplaints => 'ನಿಮ್ಮ ದೂರುಗಳು';

  @override
  String get offlineSaving => 'ಆಫ್‌ಲೈನ್ — ಮಾಹಿತಿ ಉಳಿಸಲಾಗುತ್ತಿದೆ';

  @override
  String get weakGps =>
      'ಜಿಪಿಎಸ್ ಸಂಕೇತ ದುರ್ಬಲವಾಗಿದೆ. ಫೋನ್ ಅನ್ನು ಆಕಾಶ ಕಾಣುವಲ್ಲಿ ಇರಿಸಿ.';

  @override
  String get noAssignment =>
      'ಇನ್ನೂ ನಿಯೋಜನೆ ಇಲ್ಲ. ನಿಮ್ಮ ವಾರ್ಡ್ ಅಡ್ಮಿನ್ ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get allPassesDone => 'ಇಂದಿನ ಎಲ್ಲಾ ಸುತ್ತುಗಳು ಮುಗಿದಿವೆ.';

  @override
  String get locationBlocked =>
      'ಸ್ಥಳ ನಿರ್ಬಂಧಿಸಲಾಗಿದೆ. ಪ್ರಯಾಣ ಪ್ರಾರಂಭಿಸಲು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಸಕ್ರಿಯಗೊಳಿಸಿ.';

  @override
  String minutesAway(int minutes) {
    return '~$minutes ನಿಮಿಷದಲ್ಲಿ';
  }

  @override
  String get atYourStreet => 'ನಿಮ್ಮ ಬೀದಿಯಲ್ಲಿದೆ';

  @override
  String get reportIssue => 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ';

  @override
  String get issueBreakdown => 'ಆಟೋ ಕೆಟ್ಟುಹೋಗಿದೆ';

  @override
  String get issueRoadBlocked => 'ರಸ್ತೆ ಬಂದ್ ಆಗಿದೆ';

  @override
  String get issueOther => 'ಬೇರೆ ಏನೋ';

  @override
  String get issueSent => 'ನಿಮ್ಮ ವಾರ್ಡ್ ಆಡ್ಮಿನ್‌ಗೆ ತಿಳಿಸಲಾಗಿದೆ.';

  @override
  String get rateThisCollection => 'ಆಟೋ ಬಂದು ಹೋಗಿದೆ. ಹೇಗಿತ್ತು?';
}
