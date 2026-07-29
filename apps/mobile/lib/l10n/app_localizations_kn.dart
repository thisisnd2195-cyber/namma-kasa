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

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKannada => 'ಕನ್ನಡ';

  @override
  String get yourName => 'ನಿಮ್ಮ ಹೆಸರು';

  @override
  String get address => 'ವಿಳಾಸ';

  @override
  String get landmarkOptional => 'ಗುರುತು (ಐಚ್ಛಿಕ)';

  @override
  String get setPassword => 'ಪಾಸ್‌ವರ್ಡ್ ಹೊಂದಿಸಿ';

  @override
  String get passwordHint => 'ಕನಿಷ್ಠ 8 ಅಕ್ಷರಗಳು';

  @override
  String get phoneNumber => 'ಫೋನ್ ಸಂಖ್ಯೆ';

  @override
  String get codeLabel => 'ಕೋಡ್';

  @override
  String get changeNumber => 'ಸಂಖ್ಯೆ ಬದಲಿಸಿ';

  @override
  String get weWillSendCode => 'ನಿಮ್ಮ ಸಂಖ್ಯೆ ದೃಢೀಕರಿಸಲು ಕೋಡ್ ಕಳುಹಿಸುತ್ತೇವೆ.';

  @override
  String enterCode(String phone) {
    return '$phone ಗೆ ಕಳುಹಿಸಿದ 6-ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ.';
  }

  @override
  String get residentSignIn => 'ನಿವಾಸಿ ಸೈನ್ ಇನ್';

  @override
  String get consentText =>
      'ಕಸದ ಆಟೋ ಹತ್ತಿರ ಬಂದಾಗ ತಿಳಿಸಲು ನನ್ನ ಫೋನ್ ಸಂಖ್ಯೆ ಮತ್ತು ಮನೆಯ ಸ್ಥಳವನ್ನು ಹಂಚಿಕೊಳ್ಳಲು ಒಪ್ಪುತ್ತೇನೆ.';

  @override
  String get dragPin => 'ನಿಮ್ಮ ಮನೆಯ ಮೇಲೆ ಪಿನ್ ಬರುವಂತೆ ನಕ್ಷೆಯನ್ನು ಸರಿಸಿ.';

  @override
  String pinSet(String lat, String lng) {
    return 'ಪಿನ್ $lat, $lng ಗೆ ಹೊಂದಿಸಲಾಗಿದೆ';
  }

  @override
  String get finish => 'ಮುಗಿಸಿ';

  @override
  String get finishing => 'ಮುಗಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get alertMeWhen => 'ಆಟೋ ಈ ದೂರದಲ್ಲಿದ್ದಾಗ ತಿಳಿಸಿ';

  @override
  String alertDistance(int metres) {
    return '$metres ಮೀ ದೂರ';
  }

  @override
  String get alertRadiusHelp =>
      'ಹೆಚ್ಚು ದೂರ ಎಂದರೆ ಹೆಚ್ಚು ಸಮಯ; ಕಡಿಮೆ ದೂರ ಎಂದರೆ ಆಟೋ ಪಕ್ಕದಲ್ಲಿ ಹಾದುಹೋದಾಗ ಕಡಿಮೆ ಸೂಚನೆಗಳು.';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get saving => 'ಉಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get whatWentWrong => 'ಏನು ತಪ್ಪಾಯಿತು?';

  @override
  String get anythingElse => 'ಬೇರೆ ಏನಾದರೂ? (ಐಚ್ಛಿಕ)';

  @override
  String get thanksForRating => 'ರೇಟಿಂಗ್‌ಗೆ ಧನ್ಯವಾದಗಳು.';

  @override
  String get missedTodayBanner =>
      'ಸಂಗ್ರಹಣೆ ಸಮಯ ಮುಗಿಯುವ ಮೊದಲು ಯಾವ ಆಟೋ ಕೂಡ ನಿಮ್ಮ ಮನೆಗೆ ಬರಲಿಲ್ಲ.';

  @override
  String get todayLabel => 'ಇಂದು';

  @override
  String kmAway(String km) {
    return '$km ಕಿಮೀ ದೂರ';
  }

  @override
  String metresAway(int metres) {
    return '$metres ಮೀ ದೂರ';
  }

  @override
  String get alertSettings => 'ಸೂಚನೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get missedComplaintPrefill =>
      'ಇಂದು ಸಂಗ್ರಹಣೆ ಸಮಯ ಮುಗಿಯುವ ಮೊದಲು ಯಾವ ಆಟೋ ಕೂಡ ನನ್ನ ಮನೆಗೆ ಬರಲಿಲ್ಲ.';

  @override
  String get continueWithGoogle => 'Google ಮೂಲಕ ಮುಂದುವರಿಯಿರಿ';

  @override
  String get googleConnected => 'Google ಖಾತೆ ಸಂಪರ್ಕಗೊಂಡಿದೆ';
}
