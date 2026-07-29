// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Namma Kasa';

  @override
  String get roleChooserPrompt => 'How do you want to sign in?';

  @override
  String get loginAsResident => 'Login as Resident';

  @override
  String get loginAsDriver => 'Login as Driver';

  @override
  String get residentHomeTitle => 'Your collection';

  @override
  String get driverHomeTitle => 'Your route';

  @override
  String get noActiveTrip => 'No auto on your route right now';

  @override
  String nextCollection(String window) {
    return 'Next collection: $window';
  }

  @override
  String passProgress(int current, int total) {
    return 'Pass $current of $total';
  }

  @override
  String lastCollected(String when) {
    return 'Last collected $when';
  }

  @override
  String get startTrip => 'Start trip';

  @override
  String get endTrip => 'End trip';

  @override
  String get trackingActive => 'Sharing location';

  @override
  String get pendingReview => 'We are confirming your route';

  @override
  String get backendUnavailable => 'Live tracking unavailable. Retrying…';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get rateToday => 'Rate today\'s collection';

  @override
  String get sendComplaint => 'Send complaint';

  @override
  String get complaintSent => 'Sent to your Ward Admin.';

  @override
  String get yourComplaints => 'Your complaints';

  @override
  String get offlineSaving => 'Offline — updates are saved';

  @override
  String get weakGps =>
      'Weak GPS signal. Keep the phone where it can see the sky.';

  @override
  String get noAssignment => 'No assignment yet. Contact your Ward Admin.';

  @override
  String get allPassesDone => 'All passes for today are done.';

  @override
  String get locationBlocked =>
      'Location is blocked. Enable it in Settings to start a trip.';

  @override
  String minutesAway(int minutes) {
    return '~$minutes min away';
  }

  @override
  String get atYourStreet => 'At your street';

  @override
  String get reportIssue => 'Report an issue';

  @override
  String get issueBreakdown => 'Auto broke down';

  @override
  String get issueRoadBlocked => 'Road blocked';

  @override
  String get issueOther => 'Something else';

  @override
  String get issueSent => 'Your Ward Admin has been told.';

  @override
  String get rateThisCollection => 'The auto has been past. How was it?';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKannada => 'ಕನ್ನಡ';

  @override
  String get yourName => 'Your name';

  @override
  String get address => 'Address';

  @override
  String get landmarkOptional => 'Landmark (optional)';

  @override
  String get setPassword => 'Set a password';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get codeLabel => 'Code';

  @override
  String get changeNumber => 'Change number';

  @override
  String get weWillSendCode =>
      'We will send you a code to confirm your number.';

  @override
  String enterCode(String phone) {
    return 'Enter the 6-digit code sent to $phone.';
  }

  @override
  String get residentSignIn => 'Resident sign in';

  @override
  String get consentText =>
      'I agree to share my phone number and house location so the app can tell me when the collection auto is near.';

  @override
  String get dragPin => 'Drag the map so the pin sits on your house.';

  @override
  String pinSet(String lat, String lng) {
    return 'Pin set to $lat, $lng';
  }

  @override
  String get finish => 'Finish';

  @override
  String get finishing => 'Finishing…';

  @override
  String get alertMeWhen => 'Alert me when the auto is';

  @override
  String alertDistance(int metres) {
    return '$metres m away';
  }

  @override
  String get alertRadiusHelp =>
      'A longer distance gives you more time; a shorter one means fewer alerts when the auto is only passing nearby.';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get whatWentWrong => 'What went wrong?';

  @override
  String get anythingElse => 'Anything else? (optional)';

  @override
  String get thanksForRating => 'Thanks for rating.';

  @override
  String get missedTodayBanner =>
      'No auto reached your house before the window closed.';

  @override
  String get todayLabel => 'Today';

  @override
  String kmAway(String km) {
    return '$km km away';
  }

  @override
  String metresAway(int metres) {
    return '$metres m away';
  }

  @override
  String get alertSettings => 'Alert settings';

  @override
  String get missedComplaintPrefill =>
      'No auto reached my house before the collection window closed today.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleConnected => 'Google account connected';
}
