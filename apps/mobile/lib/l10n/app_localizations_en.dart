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
}
