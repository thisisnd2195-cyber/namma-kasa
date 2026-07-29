import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Namma Kasa'**
  String get appTitle;

  /// No description provided for @roleChooserPrompt.
  ///
  /// In en, this message translates to:
  /// **'How do you want to sign in?'**
  String get roleChooserPrompt;

  /// No description provided for @loginAsResident.
  ///
  /// In en, this message translates to:
  /// **'Login as Resident'**
  String get loginAsResident;

  /// No description provided for @loginAsDriver.
  ///
  /// In en, this message translates to:
  /// **'Login as Driver'**
  String get loginAsDriver;

  /// No description provided for @residentHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your collection'**
  String get residentHomeTitle;

  /// No description provided for @driverHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your route'**
  String get driverHomeTitle;

  /// No description provided for @noActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'No auto on your route right now'**
  String get noActiveTrip;

  /// No description provided for @nextCollection.
  ///
  /// In en, this message translates to:
  /// **'Next collection: {window}'**
  String nextCollection(String window);

  /// No description provided for @passProgress.
  ///
  /// In en, this message translates to:
  /// **'Pass {current} of {total}'**
  String passProgress(int current, int total);

  /// No description provided for @lastCollected.
  ///
  /// In en, this message translates to:
  /// **'Last collected {when}'**
  String lastCollected(String when);

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Sharing location'**
  String get trackingActive;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'We are confirming your route'**
  String get pendingReview;

  /// No description provided for @backendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live tracking unavailable. Retrying…'**
  String get backendUnavailable;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @rateToday.
  ///
  /// In en, this message translates to:
  /// **'Rate today\'s collection'**
  String get rateToday;

  /// No description provided for @sendComplaint.
  ///
  /// In en, this message translates to:
  /// **'Send complaint'**
  String get sendComplaint;

  /// No description provided for @complaintSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to your Ward Admin.'**
  String get complaintSent;

  /// No description provided for @yourComplaints.
  ///
  /// In en, this message translates to:
  /// **'Your complaints'**
  String get yourComplaints;

  /// No description provided for @offlineSaving.
  ///
  /// In en, this message translates to:
  /// **'Offline — updates are saved'**
  String get offlineSaving;

  /// No description provided for @weakGps.
  ///
  /// In en, this message translates to:
  /// **'Weak GPS signal. Keep the phone where it can see the sky.'**
  String get weakGps;

  /// No description provided for @noAssignment.
  ///
  /// In en, this message translates to:
  /// **'No assignment yet. Contact your Ward Admin.'**
  String get noAssignment;

  /// No description provided for @allPassesDone.
  ///
  /// In en, this message translates to:
  /// **'All passes for today are done.'**
  String get allPassesDone;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked. Enable it in Settings to start a trip.'**
  String get locationBlocked;

  /// No description provided for @minutesAway.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min away'**
  String minutesAway(int minutes);

  /// No description provided for @atYourStreet.
  ///
  /// In en, this message translates to:
  /// **'At your street'**
  String get atYourStreet;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssue;

  /// No description provided for @issueBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Auto broke down'**
  String get issueBreakdown;

  /// No description provided for @issueRoadBlocked.
  ///
  /// In en, this message translates to:
  /// **'Road blocked'**
  String get issueRoadBlocked;

  /// No description provided for @issueOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get issueOther;

  /// No description provided for @issueSent.
  ///
  /// In en, this message translates to:
  /// **'Your Ward Admin has been told.'**
  String get issueSent;

  /// No description provided for @rateThisCollection.
  ///
  /// In en, this message translates to:
  /// **'The auto has been past. How was it?'**
  String get rateThisCollection;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'kn':
      return L10nKn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
