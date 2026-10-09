import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('de'),
    Locale('en'),
    Locale('hu'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PetTrack'**
  String get appName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @uploadProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Upload profile picture'**
  String get uploadProfilePicture;

  /// No description provided for @serverIp.
  ///
  /// In en, this message translates to:
  /// **'Server IP'**
  String get serverIp;

  /// No description provided for @serverIpHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.100'**
  String get serverIpHint;

  /// No description provided for @secretToken.
  ///
  /// In en, this message translates to:
  /// **'Secret Token'**
  String get secretToken;

  /// No description provided for @petName.
  ///
  /// In en, this message translates to:
  /// **'Pet name'**
  String get petName;

  /// No description provided for @petNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name'**
  String get petNameHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get navZones;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @liveVideo.
  ///
  /// In en, this message translates to:
  /// **'Live Video'**
  String get liveVideo;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @noRecentEvents.
  ///
  /// In en, this message translates to:
  /// **'No recent events'**
  String get noRecentEvents;

  /// No description provided for @zoneEntered.
  ///
  /// In en, this message translates to:
  /// **'{petName} entered {zone}'**
  String zoneEntered(String petName, String zone);

  /// No description provided for @zoneVisits.
  ///
  /// In en, this message translates to:
  /// **'Zone Visits'**
  String get zoneVisits;

  /// No description provided for @zoneLeft.
  ///
  /// In en, this message translates to:
  /// **'{petName} left {zone}'**
  String zoneLeft(String petName, String zone);

  /// No description provided for @cameraDetectedMovement.
  ///
  /// In en, this message translates to:
  /// **'Camera detected movement.'**
  String get cameraDetectedMovement;

  /// No description provided for @editZones.
  ///
  /// In en, this message translates to:
  /// **'Edit Zones'**
  String get editZones;

  /// No description provided for @addNewZone.
  ///
  /// In en, this message translates to:
  /// **'Add new zone'**
  String get addNewZone;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @existingZones.
  ///
  /// In en, this message translates to:
  /// **'Existing zones'**
  String get existingZones;

  /// No description provided for @safeZone.
  ///
  /// In en, this message translates to:
  /// **'Safe zone'**
  String get safeZone;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'{mins} mins ago'**
  String minsAgo(int mins);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @leftTheZone.
  ///
  /// In en, this message translates to:
  /// **'Left the zone.'**
  String get leftTheZone;

  /// No description provided for @greetingsList.
  ///
  /// In en, this message translates to:
  /// **'Hi Boss!|Welcome back!|Have a nice day!|Hey!|How are you?|Hello!|What\'s up?|Good to see you again!|Ready?|Let\'s see what they are doing!'**
  String get greetingsList;

  /// No description provided for @subGreetingsList.
  ///
  /// In en, this message translates to:
  /// **'Everything is fine here.|Seems to be sleeping.|Full of energy!|Watching the area.|Waiting for dinner.|Sniffing something.|Resting peacefully.|At the favorite spot.|Wants to play.|Everything is quiet.'**
  String get subGreetingsList;

  /// No description provided for @petTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Type'**
  String get petTypeTitle;

  /// No description provided for @petTypeDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get petTypeDog;

  /// No description provided for @petTypeCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get petTypeCat;

  /// No description provided for @petTypeRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get petTypeRabbit;

  /// No description provided for @petTypeGuineaPig.
  ///
  /// In en, this message translates to:
  /// **'Guinea Pig'**
  String get petTypeGuineaPig;

  /// No description provided for @petTypeBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get petTypeBird;

  /// No description provided for @petTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get petTypeOther;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get alertsTitle;

  /// No description provided for @alertsZone.
  ///
  /// In en, this message translates to:
  /// **'Zone alerts (Enter/Exit)'**
  String get alertsZone;

  /// No description provided for @alertsBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery alert'**
  String get alertsBattery;

  /// No description provided for @batteryThreshold.
  ///
  /// In en, this message translates to:
  /// **'Battery threshold: {level}%'**
  String batteryThreshold(int level);

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotifTitle;

  /// No description provided for @testNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You have successfully set up notifications!'**
  String get testNotifBody;

  /// No description provided for @alertsRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts when I\'m away'**
  String get alertsRemoteTitle;

  /// No description provided for @alertsRemoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Forwards alerts to an ntfy topic so they reach you anywhere — in the ntfy app or any browser. Pick a topic name that is hard to guess; anyone with the link can subscribe.'**
  String get alertsRemoteDesc;

  /// No description provided for @alertsRemoteUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'ntfy topic URL'**
  String get alertsRemoteUrlLabel;

  /// No description provided for @alertsRemoteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://ntfy.sh/your-secret-topic'**
  String get alertsRemoteUrlHint;

  /// No description provided for @alertsRemoteTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Access token (optional)'**
  String get alertsRemoteTokenLabel;

  /// No description provided for @alertsRemoteTest.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get alertsRemoteTest;

  /// No description provided for @alertsRemoteTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent — check your phone.'**
  String get alertsRemoteTestSent;

  /// No description provided for @alertsRemoteTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the test notification. Check the topic URL and the server.'**
  String get alertsRemoteTestFailed;

  /// No description provided for @alertsRemoteUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a valid ntfy URL.'**
  String get alertsRemoteUrlInvalid;

  /// No description provided for @secondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds ago'**
  String secondsAgo(int seconds);

  /// No description provided for @toiletZone.
  ///
  /// In en, this message translates to:
  /// **'Litter Box / Toilet'**
  String get toiletZone;

  /// No description provided for @bedZone.
  ///
  /// In en, this message translates to:
  /// **'Bed / Resting Area'**
  String get bedZone;

  /// No description provided for @waterZone.
  ///
  /// In en, this message translates to:
  /// **'Water Bowl'**
  String get waterZone;

  /// No description provided for @foodZone.
  ///
  /// In en, this message translates to:
  /// **'Food Bowl'**
  String get foodZone;

  /// No description provided for @playZone.
  ///
  /// In en, this message translates to:
  /// **'Play Area'**
  String get playZone;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance (Theme)'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// No description provided for @failedToLoadPetProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Pet Profile {e}'**
  String failedToLoadPetProfile(String e);

  /// No description provided for @invalidSecretToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid Secret Token!'**
  String get invalidSecretToken;

  /// No description provided for @decodingError.
  ///
  /// In en, this message translates to:
  /// **'Decoding error: {e}'**
  String decodingError(String e);

  /// No description provided for @setupWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PetTrack!'**
  String get setupWelcomeTitle;

  /// No description provided for @setupWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'The best way to keep track of your pet.\n\nFirst, let\'s connect to the server.'**
  String get setupWelcomeDesc;

  /// No description provided for @setupScanBtn.
  ///
  /// In en, this message translates to:
  /// **'Read QR Code'**
  String get setupScanBtn;

  /// No description provided for @setupSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get setupSuccessTitle;

  /// No description provided for @setupSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'The connection is encrypted.\nNow let\'s register your pet.'**
  String get setupSuccessDesc;

  /// No description provided for @setupNextBtn.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get setupNextBtn;

  /// No description provided for @setupErrConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the server! Check the network.'**
  String get setupErrConnect;

  /// No description provided for @setupErrSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile.'**
  String get setupErrSave;

  /// No description provided for @setupErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name!'**
  String get setupErrEmpty;

  /// No description provided for @setupMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor Setup'**
  String get setupMonitorTitle;

  /// No description provided for @setupMonitorDesc.
  ///
  /// In en, this message translates to:
  /// **'Open the Monitor app on the other phone and scan this QR code to connect!'**
  String get setupMonitorDesc;

  /// No description provided for @settingsShowQrBtn.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get settingsShowQrBtn;

  /// No description provided for @settingsQrDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan with the old phone:'**
  String get settingsQrDialogDesc;

  /// No description provided for @settingsQrDialogDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settingsQrDialogDone;

  /// No description provided for @settingsResetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset App & Restart Setup'**
  String get settingsResetApp;

  /// No description provided for @settingsResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get settingsResetConfirmTitle;

  /// No description provided for @settingsResetConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will delete all saved data and restart the setup wizard.'**
  String get settingsResetConfirmDesc;

  /// No description provided for @serverUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Unreachable'**
  String get serverUnreachableTitle;

  /// No description provided for @serverUnreachableDesc.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the PetTrack server.\nPlease check your network or if the server is running.'**
  String get serverUnreachableDesc;

  /// No description provided for @profileAndSystem.
  ///
  /// In en, this message translates to:
  /// **'Profile & System'**
  String get profileAndSystem;

  /// No description provided for @monitorAndConnection.
  ///
  /// In en, this message translates to:
  /// **'Monitor & Connection'**
  String get monitorAndConnection;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE!'**
  String get offlineStatus;

  /// No description provided for @liveStatus.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveStatus;

  /// No description provided for @searchingStatus.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingStatus;

  /// No description provided for @navMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get navMedical;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @vaccines.
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get vaccines;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @addVaccine.
  ///
  /// In en, this message translates to:
  /// **'Add Vaccine'**
  String get addVaccine;

  /// No description provided for @dose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get dose;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @dateGiven.
  ///
  /// In en, this message translates to:
  /// **'Date Given'**
  String get dateGiven;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next Due'**
  String get nextDue;

  /// No description provided for @enableAlert.
  ///
  /// In en, this message translates to:
  /// **'Enable Alert'**
  String get enableAlert;

  /// No description provided for @medName.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medName;

  /// No description provided for @vacName.
  ///
  /// In en, this message translates to:
  /// **'Vaccine name'**
  String get vacName;

  /// No description provided for @noMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications added yet.'**
  String get noMedications;

  /// No description provided for @noVaccines.
  ///
  /// In en, this message translates to:
  /// **'No vaccines added yet.'**
  String get noVaccines;

  /// No description provided for @saveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save Medication'**
  String get saveMedication;

  /// No description provided for @saveVaccine.
  ///
  /// In en, this message translates to:
  /// **'Save Vaccine'**
  String get saveVaccine;

  /// No description provided for @cardColor.
  ///
  /// In en, this message translates to:
  /// **'Card Color:'**
  String get cardColor;

  /// No description provided for @alertFrequency.
  ///
  /// In en, this message translates to:
  /// **'Alert frequency (in hours)'**
  String get alertFrequency;

  /// No description provided for @alertFrequencyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g, 12 or 24'**
  String get alertFrequencyHint;

  /// No description provided for @medTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication Time!'**
  String get medTimeTitle;

  /// No description provided for @medTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Time to give: {name} ({dose})'**
  String medTimeBody(String name, String dose);

  /// No description provided for @everyXHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} hours'**
  String everyXHours(int hours);

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'PetTrack Monitor Setup'**
  String get setupTitle;

  /// No description provided for @monitorTitle.
  ///
  /// In en, this message translates to:
  /// **'PetTrack Monitor'**
  String get monitorTitle;

  /// No description provided for @monitorSleepMode.
  ///
  /// In en, this message translates to:
  /// **'Sleep Mode (Dim Screen)'**
  String get monitorSleepMode;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'This app securely streams your camera feed to the PetTrack backend.'**
  String get aboutDescription;

  /// No description provided for @monitorStreamingLive.
  ///
  /// In en, this message translates to:
  /// **'Streaming live video...'**
  String get monitorStreamingLive;

  /// No description provided for @monitorWaitingForStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting for START command...'**
  String get monitorWaitingForStart;

  /// No description provided for @monitorReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get monitorReconnecting;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @monitorServer.
  ///
  /// In en, this message translates to:
  /// **'Server:\n{ip}'**
  String monitorServer(String ip);

  /// No description provided for @monitorSleeping.
  ///
  /// In en, this message translates to:
  /// **'Sleeping... Double tap to wake'**
  String get monitorSleeping;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to server! Check IP and Token.\nError: {error}'**
  String errorConnectionFailed(String error);

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHungarian.
  ///
  /// In en, this message translates to:
  /// **'Magyar'**
  String get languageHungarian;

  /// No description provided for @setupScanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code from the PetTrack App'**
  String get setupScanQrTitle;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'☀️ Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'🌙 Dark Mode'**
  String get darkMode;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PetTrack'**
  String get welcomeTitle;

  /// No description provided for @chooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose your mode'**
  String get chooseMode;

  /// No description provided for @modeClient.
  ///
  /// In en, this message translates to:
  /// **'Client (Viewer)'**
  String get modeClient;

  /// No description provided for @modeClientDesc.
  ///
  /// In en, this message translates to:
  /// **'This device will watch the stream.'**
  String get modeClientDesc;

  /// No description provided for @modeMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor (Camera)'**
  String get modeMonitor;

  /// No description provided for @modeMonitorDesc.
  ///
  /// In en, this message translates to:
  /// **'This device will stream video.'**
  String get modeMonitorDesc;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @demoModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoModeTitle;

  /// No description provided for @demoModePrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to enter Demo Mode?'**
  String get demoModePrompt;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @demoLivePreview.
  ///
  /// In en, this message translates to:
  /// **'DEMO MODE, LIVE PREVIEW HERE!'**
  String get demoLivePreview;

  /// No description provided for @zoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Zone saved!'**
  String get zoneSaved;

  /// No description provided for @zoneSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String zoneSaveError(String e);

  /// No description provided for @newZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Adding a new zone'**
  String get newZoneTitle;

  /// No description provided for @zoneNameHint.
  ///
  /// In en, this message translates to:
  /// **'Zone name...'**
  String get zoneNameHint;

  /// No description provided for @noZonesYet.
  ///
  /// In en, this message translates to:
  /// **'No zones yet.'**
  String get noZonesYet;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @submitPin.
  ///
  /// In en, this message translates to:
  /// **'Submit PIN'**
  String get submitPin;

  /// No description provided for @demoModeBtn.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoModeBtn;

  /// No description provided for @demoNoPlayback.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — video playback is not available'**
  String get demoNoPlayback;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity insights'**
  String get insightsTitle;

  /// No description provided for @insightsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Activity, zones and rest at a glance'**
  String get insightsEntrySubtitle;

  /// No description provided for @insightsRangeDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String insightsRangeDays(int n);

  /// No description provided for @insightsActiveToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get insightsActiveToday;

  /// No description provided for @insightsAvgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day (average)'**
  String get insightsAvgPerDay;

  /// No description provided for @insightsMostActiveZone.
  ///
  /// In en, this message translates to:
  /// **'Top zone'**
  String get insightsMostActiveZone;

  /// No description provided for @insightsActivityChart.
  ///
  /// In en, this message translates to:
  /// **'Active minutes per day'**
  String get insightsActivityChart;

  /// No description provided for @insightsZoneChart.
  ///
  /// In en, this message translates to:
  /// **'Time per zone'**
  String get insightsZoneChart;

  /// No description provided for @insightsZoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'No zone stays recorded in this range'**
  String get insightsZoneEmpty;

  /// No description provided for @insightsActiveVsRest.
  ///
  /// In en, this message translates to:
  /// **'Active vs rest (average day)'**
  String get insightsActiveVsRest;

  /// No description provided for @insightsWordActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get insightsWordActive;

  /// No description provided for @insightsWordRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get insightsWordRest;

  /// No description provided for @insightsTableDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get insightsTableDay;

  /// No description provided for @tooltipInsightsList.
  ///
  /// In en, this message translates to:
  /// **'Show as a table'**
  String get tooltipInsightsList;

  /// No description provided for @tooltipInsightsChart.
  ///
  /// In en, this message translates to:
  /// **'Show as a chart'**
  String get tooltipInsightsChart;

  /// No description provided for @insightsDurationH.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String insightsDurationH(int n);

  /// No description provided for @insightsDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String insightsDurationHm(int hours, int minutes);

  /// No description provided for @insightsDurationM.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String insightsDurationM(int minutes);

  /// No description provided for @insightsDurationS.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String insightsDurationS(int seconds);

  /// No description provided for @insightsClips.
  ///
  /// In en, this message translates to:
  /// **'{n} motion clips'**
  String insightsClips(int n);

  /// No description provided for @insightsSounds.
  ///
  /// In en, this message translates to:
  /// **'{n} sound events'**
  String insightsSounds(int n);

  /// No description provided for @insightsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load insights'**
  String get insightsLoadError;

  /// No description provided for @demoZoneKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get demoZoneKitchen;

  /// No description provided for @demoZoneSofa.
  ///
  /// In en, this message translates to:
  /// **'Sofa'**
  String get demoZoneSofa;

  /// No description provided for @demoZoneBed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get demoZoneBed;

  /// No description provided for @demoZoneGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get demoZoneGarden;

  /// No description provided for @healthCardTitle.
  ///
  /// In en, this message translates to:
  /// **'System health'**
  String get healthCardTitle;

  /// No description provided for @healthCameraOnline.
  ///
  /// In en, this message translates to:
  /// **'Camera online'**
  String get healthCameraOnline;

  /// No description provided for @healthCameraOffline.
  ///
  /// In en, this message translates to:
  /// **'Camera offline'**
  String get healthCameraOffline;

  /// No description provided for @healthLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {duration}'**
  String healthLastSeen(String duration);

  /// No description provided for @healthDiskFreeOf.
  ///
  /// In en, this message translates to:
  /// **'{free} free of {total}'**
  String healthDiskFreeOf(String free, String total);

  /// No description provided for @healthDiskLow.
  ///
  /// In en, this message translates to:
  /// **'Disk space is low — old replays will be pruned'**
  String get healthDiskLow;

  /// No description provided for @healthReplaysStored.
  ///
  /// In en, this message translates to:
  /// **'{count} replays · {size}'**
  String healthReplaysStored(int count, String size);

  /// No description provided for @healthKeepReplays.
  ///
  /// In en, this message translates to:
  /// **'Keep replays for'**
  String get healthKeepReplays;

  /// No description provided for @healthRetentionSaved.
  ///
  /// In en, this message translates to:
  /// **'Replay retention updated'**
  String get healthRetentionSaved;

  /// No description provided for @healthCleanupNow.
  ///
  /// In en, this message translates to:
  /// **'Free up space now'**
  String get healthCleanupNow;

  /// Storage cleanup result: {size} is the freed space, {count} how many files went away.
  ///
  /// In en, this message translates to:
  /// **'Freed {size} — {count} items cleaned up.'**
  String healthCleanupDone(String size, int count);

  /// No description provided for @healthCleanupNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clean up — everything is within the retention window.'**
  String get healthCleanupNone;

  /// No description provided for @healthCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed. Try again.'**
  String get healthCleanupFailed;

  /// No description provided for @healthLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load system health'**
  String get healthLoadError;

  /// No description provided for @cameraOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera offline'**
  String get cameraOfflineTitle;

  /// No description provided for @cameraOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'No video from the camera for 10 minutes'**
  String get cameraOfflineBody;

  /// No description provided for @diskLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Disk space low'**
  String get diskLowTitle;

  /// No description provided for @diskLowBody.
  ///
  /// In en, this message translates to:
  /// **'Old replays are being pruned to free up space'**
  String get diskLowBody;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this server?'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'This device forgets its tokens and its session on the server is revoked. Sign in again with the pairing PIN.'**
  String get settingsSignOutMessage;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orSeparator;

  /// No description provided for @setupErrPin.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect or invalid PIN!'**
  String get setupErrPin;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get saveSuccess;

  /// No description provided for @navReplays.
  ///
  /// In en, this message translates to:
  /// **'Replays'**
  String get navReplays;

  /// No description provided for @replaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Replays'**
  String get replaysTitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @replaysLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load replays (Error {code})'**
  String replaysLoadError(int code);

  /// No description provided for @replaysNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {e}'**
  String replaysNetworkError(String e);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @openDownload.
  ///
  /// In en, this message translates to:
  /// **'Open / Download'**
  String get openDownload;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noReplays.
  ///
  /// In en, this message translates to:
  /// **'No replays recorded yet.'**
  String get noReplays;

  /// No description provided for @replaySizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size}MB'**
  String replaySizeMb(String size);

  /// No description provided for @qrScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScannerTitle;

  /// No description provided for @qrScannerHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code shown in the server terminal!'**
  String get qrScannerHint;

  /// No description provided for @notifChannelAlertsName.
  ///
  /// In en, this message translates to:
  /// **'PetTrack Alerts'**
  String get notifChannelAlertsName;

  /// No description provided for @notifChannelAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications about zone changes and battery'**
  String get notifChannelAlertsDesc;

  /// No description provided for @notifChannelMedicalName.
  ///
  /// In en, this message translates to:
  /// **'Medical Alerts'**
  String get notifChannelMedicalName;

  /// No description provided for @notifChannelMedicalDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications about giving medication'**
  String get notifChannelMedicalDesc;

  /// No description provided for @syncToWatch.
  ///
  /// In en, this message translates to:
  /// **'Sync with Smartwatch'**
  String get syncToWatch;

  /// No description provided for @syncStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting sync...'**
  String get syncStarting;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully sent to the watch!'**
  String get syncSuccess;

  /// No description provided for @syncNoWatch.
  ///
  /// In en, this message translates to:
  /// **'No connected watch found.'**
  String get syncNoWatch;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @eventLog.
  ///
  /// In en, this message translates to:
  /// **'Event Log'**
  String get eventLog;

  /// No description provided for @shareInviteText.
  ///
  /// In en, this message translates to:
  /// **'Look what my pet is doing!'**
  String get shareInviteText;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguageTitle;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @aiGeneratedMarker.
  ///
  /// In en, this message translates to:
  /// **'(AI-GENERATED)'**
  String get aiGeneratedMarker;

  /// No description provided for @wearSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced!'**
  String get wearSynced;

  /// No description provided for @wearOpenAppOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Open the app on your phone.'**
  String get wearOpenAppOnPhone;

  /// No description provided for @wearManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get wearManual;

  /// No description provided for @wearSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get wearSetupTitle;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get pinHint;

  /// No description provided for @errInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN!'**
  String get errInvalidPin;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error!'**
  String get errNetwork;

  /// No description provided for @defaultPetName.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get defaultPetName;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'v1.0 Pre-Release'**
  String get appVersion;

  /// No description provided for @discoveryBtn.
  ///
  /// In en, this message translates to:
  /// **'Find server on network'**
  String get discoveryBtn;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers on your network'**
  String get discoveryTitle;

  /// No description provided for @discoverySearching.
  ///
  /// In en, this message translates to:
  /// **'Searching your local network…'**
  String get discoverySearching;

  /// No description provided for @discoveryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No PetTrack server found yet.'**
  String get discoveryEmpty;

  /// No description provided for @discoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the server is running and you are on the same Wi-Fi.'**
  String get discoveryHint;

  /// No description provided for @discoveryNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Automatic discovery is not available on this device. Enter the server address manually.'**
  String get discoveryNotSupported;

  /// No description provided for @discoveryTapToUse.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get discoveryTapToUse;

  /// No description provided for @tooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tooltipRefresh;

  /// No description provided for @tooltipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tooltipAdd;

  /// No description provided for @tooltipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltipDelete;

  /// No description provided for @highlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s recap'**
  String get highlightTitle;

  /// No description provided for @highlightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every moment from today in one clip'**
  String get highlightSubtitle;

  /// No description provided for @highlightMoments.
  ///
  /// In en, this message translates to:
  /// **'{count} moments'**
  String highlightMoments(Object count);

  /// No description provided for @tooltipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @quietHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHoursTitle;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No zone or battery alerts during this time'**
  String get quietHoursSubtitle;

  /// No description provided for @quietHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quietHoursFrom;

  /// No description provided for @quietHoursTo.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get quietHoursTo;

  /// No description provided for @snoozeTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze alerts'**
  String get snoozeTitle;

  /// No description provided for @snoozeChip.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snoozeChip;

  /// No description provided for @snoozeChipActive.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get snoozeChipActive;

  /// No description provided for @snooze30m.
  ///
  /// In en, this message translates to:
  /// **'For 30 minutes'**
  String get snooze30m;

  /// No description provided for @snooze1h.
  ///
  /// In en, this message translates to:
  /// **'For an hour'**
  String get snooze1h;

  /// No description provided for @snoozeTonight.
  ///
  /// In en, this message translates to:
  /// **'Until 23:00'**
  String get snoozeTonight;

  /// No description provided for @snoozeEnd.
  ///
  /// In en, this message translates to:
  /// **'End snooze'**
  String get snoozeEnd;

  /// No description provided for @snoozeActive.
  ///
  /// In en, this message translates to:
  /// **'Alerts snoozed on this phone until {time}'**
  String snoozeActive(String time);

  /// No description provided for @snoozeEnded.
  ///
  /// In en, this message translates to:
  /// **'Alerts are back on this phone.'**
  String get snoozeEnded;

  /// No description provided for @batteryLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Low battery'**
  String get batteryLowTitle;

  /// No description provided for @batteryLowBody.
  ///
  /// In en, this message translates to:
  /// **'Battery at {level}%'**
  String batteryLowBody(int level);

  /// No description provided for @aboutCardTitle.
  ///
  /// In en, this message translates to:
  /// **'About & updates'**
  String get aboutCardTitle;

  /// No description provided for @versionAppLabel.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get versionAppLabel;

  /// No description provided for @versionServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get versionServerLabel;

  /// No description provided for @versionCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get versionCheckButton;

  /// No description provided for @versionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get versionUnknown;

  /// No description provided for @versionMatch.
  ///
  /// In en, this message translates to:
  /// **'App and server versions match'**
  String get versionMatch;

  /// No description provided for @versionAppOlder.
  ///
  /// In en, this message translates to:
  /// **'The server is newer — update the app'**
  String get versionAppOlder;

  /// No description provided for @versionServerOlder.
  ///
  /// In en, this message translates to:
  /// **'The app is newer — update the server'**
  String get versionServerOlder;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready to install'**
  String updateAvailable(String version);

  /// No description provided for @updateInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get updateInstallButton;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get updateDownloading;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download the update. Check the server and try again.'**
  String get updateDownloadFailed;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the Android installer.'**
  String get updateInstallFailed;

  /// No description provided for @privacyButton.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyButton;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'PetTrack is fully self-hosted — your camera feed, recordings and pet data stay on your own server.\n\n• No cloud, nothing is uploaded anywhere\n• No account — there is no service to sign up for\n• No analytics or tracking\n• LAN-only by default; remote access is only what you set up yourself'**
  String get privacyBody;

  /// No description provided for @whatsNewButton.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewButton;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @changelogBody.
  ///
  /// In en, this message translates to:
  /// **'1.0.0\n• Today\'s recap on the dashboard\n• Quiet hours for alerts\n• Home Assistant integration\n• Material 3 redesign'**
  String get changelogBody;

  /// No description provided for @tooltipPlaySound.
  ///
  /// In en, this message translates to:
  /// **'Play a sound'**
  String get tooltipPlaySound;

  /// No description provided for @cameraGridLabel.
  ///
  /// In en, this message translates to:
  /// **'All cameras'**
  String get cameraGridLabel;

  /// No description provided for @widgetEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Open PetTrack to load the camera'**
  String get widgetEmptyHint;

  /// No description provided for @tooltipSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Take a snapshot'**
  String get tooltipSnapshot;

  /// No description provided for @playSoundSent.
  ///
  /// In en, this message translates to:
  /// **'Sound sent to the monitor'**
  String get playSoundSent;

  /// No description provided for @tooltipTimelapse.
  ///
  /// In en, this message translates to:
  /// **'Day timelapse'**
  String get tooltipTimelapse;

  /// No description provided for @tooltipRecap.
  ///
  /// In en, this message translates to:
  /// **'Day recap'**
  String get tooltipRecap;

  /// No description provided for @recapBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the day\'s recap…'**
  String get recapBuilding;

  /// No description provided for @recapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No moments for this day'**
  String get recapEmpty;

  /// No description provided for @recapError.
  ///
  /// In en, this message translates to:
  /// **'Could not build the recap (error {code})'**
  String recapError(int code);

  /// No description provided for @replayAllDays.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get replayAllDays;

  /// No description provided for @replaysHourStripTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity by hour'**
  String get replaysHourStripTitle;

  /// Hour-strip tooltip: {hour} is 00–23, {count} the events in that hour.
  ///
  /// In en, this message translates to:
  /// **'{hour}:00 — {count} events'**
  String replaysHourTooltip(String hour, int count);

  /// No description provided for @replaysHourClear.
  ///
  /// In en, this message translates to:
  /// **'Whole day'**
  String get replaysHourClear;

  /// No description provided for @noReplaysForDay.
  ///
  /// In en, this message translates to:
  /// **'No replays for this day'**
  String get noReplaysForDay;

  /// No description provided for @timelapseBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building the day\'s timelapse…'**
  String get timelapseBuilding;

  /// No description provided for @timelapseEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough frames for this day'**
  String get timelapseEmpty;

  /// No description provided for @timelapseError.
  ///
  /// In en, this message translates to:
  /// **'Could not build the timelapse (error {code})'**
  String timelapseError(int code);

  /// No description provided for @tooltipNightMode.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get tooltipNightMode;

  /// No description provided for @nightModeOn.
  ///
  /// In en, this message translates to:
  /// **'Night mode on'**
  String get nightModeOn;

  /// No description provided for @nightModeOff.
  ///
  /// In en, this message translates to:
  /// **'Night mode off'**
  String get nightModeOff;

  /// No description provided for @alertsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound alerts (bark / meow)'**
  String get alertsSound;

  /// No description provided for @soundDetectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound detected'**
  String get soundDetectedTitle;

  /// No description provided for @soundDetectedBody.
  ///
  /// In en, this message translates to:
  /// **'Loud noise near the camera.'**
  String get soundDetectedBody;

  /// No description provided for @demoZoneLitter.
  ///
  /// In en, this message translates to:
  /// **'Litter box'**
  String get demoZoneLitter;

  /// No description provided for @demoZonePlayground.
  ///
  /// In en, this message translates to:
  /// **'Playground'**
  String get demoZonePlayground;

  /// No description provided for @demoZoneFeeder.
  ///
  /// In en, this message translates to:
  /// **'Feeder'**
  String get demoZoneFeeder;

  /// No description provided for @demoMedName.
  ///
  /// In en, this message translates to:
  /// **'Digestive supplement'**
  String get demoMedName;

  /// No description provided for @demoMedDose.
  ///
  /// In en, this message translates to:
  /// **'0.5 ml'**
  String get demoMedDose;

  /// No description provided for @demoVacName.
  ///
  /// In en, this message translates to:
  /// **'Myxomatosis vaccine'**
  String get demoVacName;

  /// No description provided for @activityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent activity'**
  String get activityLoadError;

  /// No description provided for @zonesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load zones'**
  String get zonesLoadError;

  /// No description provided for @cameraStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera'**
  String get cameraStartFailed;

  /// No description provided for @videoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not play this clip'**
  String get videoLoadError;

  /// No description provided for @medicalCachedNotice.
  ///
  /// In en, this message translates to:
  /// **'The server is unreachable — showing your saved copy'**
  String get medicalCachedNotice;

  /// No description provided for @tooltipPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause'**
  String get tooltipPlayPause;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the change'**
  String get settingsSaveError;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share'**
  String get shareFailed;

  /// No description provided for @evidenceNoClip.
  ///
  /// In en, this message translates to:
  /// **'No clip recorded near that moment'**
  String get evidenceNoClip;

  /// No description provided for @feedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get feedSearchHint;

  /// No description provided for @feedSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get feedSearchClear;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @feedFilterZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get feedFilterZones;

  /// No description provided for @feedFilterSounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get feedFilterSounds;

  /// No description provided for @feedFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get feedFilterSystem;

  /// No description provided for @feedNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching events'**
  String get feedNoMatch;

  /// No description provided for @feedExport.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get feedExport;

  /// No description provided for @feedExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet.'**
  String get feedExportEmpty;

  /// No description provided for @feedExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the feed.'**
  String get feedExportFailed;

  /// Morning recap banner: {count} is how many events happened overnight (may be 50+ when the feed is capped).
  ///
  /// In en, this message translates to:
  /// **'Last night: {count} events'**
  String recapBanner(String count);

  /// No description provided for @recapDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get recapDismiss;

  /// No description provided for @armingTitle.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get armingTitle;

  /// No description provided for @armingModeOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get armingModeOn;

  /// No description provided for @armingModeSchedule.
  ///
  /// In en, this message translates to:
  /// **'On a schedule'**
  String get armingModeSchedule;

  /// No description provided for @armingModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get armingModeOff;

  /// No description provided for @armingStatusArmed.
  ///
  /// In en, this message translates to:
  /// **'Armed'**
  String get armingStatusArmed;

  /// No description provided for @armingStatusDisarmed.
  ///
  /// In en, this message translates to:
  /// **'Disarmed'**
  String get armingStatusDisarmed;

  /// No description provided for @armingAddWindow.
  ///
  /// In en, this message translates to:
  /// **'Add window'**
  String get armingAddWindow;

  /// No description provided for @armingRemoveWindow.
  ///
  /// In en, this message translates to:
  /// **'Remove window'**
  String get armingRemoveWindow;

  /// No description provided for @armingFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get armingFrom;

  /// No description provided for @armingTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get armingTo;

  /// No description provided for @armingDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get armingDays;

  /// No description provided for @armingHelp.
  ///
  /// In en, this message translates to:
  /// **'Armed records motion and raises alerts; disarmed keeps no footage. Live view always works.'**
  String get armingHelp;

  /// No description provided for @armingWindowRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one window'**
  String get armingWindowRequired;

  /// No description provided for @semanticCameraView.
  ///
  /// In en, this message translates to:
  /// **'Camera view'**
  String get semanticCameraView;

  /// No description provided for @semanticChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get semanticChangePhoto;

  /// No description provided for @semanticZoneCanvas.
  ///
  /// In en, this message translates to:
  /// **'Zone editor — tap to place a point'**
  String get semanticZoneCanvas;

  /// No description provided for @semanticWakeMonitor.
  ///
  /// In en, this message translates to:
  /// **'Double tap to wake the monitor'**
  String get semanticWakeMonitor;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @tooltipConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get tooltipConfirm;

  /// No description provided for @backupCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupCardTitle;

  /// No description provided for @backupHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep your setup in one file — restore it on a new phone or after a reinstall. The file contains your pairing secret, so anyone holding it can reach your cameras.'**
  String get backupHelp;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get backupRestore;

  /// No description provided for @backupExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export backup?'**
  String get backupExportTitle;

  /// No description provided for @backupExportBody.
  ///
  /// In en, this message translates to:
  /// **'The backup file contains your pairing secret. Share it only with yourself — anyone with this file can access your cameras.'**
  String get backupExportBody;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces the settings on this phone and, when the server is reachable, on the server too.'**
  String get backupRestoreBody;

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'That file is not a PetTrack backup'**
  String get backupInvalid;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestored;

  /// No description provided for @backupRestoredOffline.
  ///
  /// In en, this message translates to:
  /// **'Backup restored on this phone. Open Settings and save to sync with the server.'**
  String get backupRestoredOffline;

  /// No description provided for @backupRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not restore the backup'**
  String get backupRestoreError;

  /// No description provided for @setupSkipMonitor.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkipMonitor;

  /// No description provided for @setupMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Enter the server address and the PIN'**
  String get setupMissingFields;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'hu',
    'it',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
