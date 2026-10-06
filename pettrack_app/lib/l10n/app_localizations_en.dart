// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get uploadProfilePicture => 'Upload profile picture';

  @override
  String get serverIp => 'Server IP';

  @override
  String get serverIpHint => 'e.g. 192.168.1.100';

  @override
  String get secretToken => 'Secret Token';

  @override
  String get petName => 'Pet name';

  @override
  String get petNameHint => 'Enter the name';

  @override
  String get save => 'Save';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navZones => 'Zones';

  @override
  String get navSettings => 'Settings';

  @override
  String get liveVideo => 'Live Video';

  @override
  String get activities => 'Activities';

  @override
  String get noRecentEvents => 'No recent events';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petName entered $zone';
  }

  @override
  String get zoneVisits => 'Zone Visits';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petName left $zone';
  }

  @override
  String get cameraDetectedMovement => 'Camera detected movement.';

  @override
  String get editZones => 'Edit Zones';

  @override
  String get addNewZone => 'Add new zone';

  @override
  String get cancel => 'Cancel';

  @override
  String get existingZones => 'Existing zones';

  @override
  String get safeZone => 'Safe zone';

  @override
  String get today => 'Today';

  @override
  String get language => 'Language';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get justNow => 'Just now';

  @override
  String minsAgo(int mins) {
    return '$mins mins ago';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get leftTheZone => 'Left the zone.';

  @override
  String get greetingsList =>
      'Hi Boss!|Welcome back!|Have a nice day!|Hey!|How are you?|Hello!|What\'s up?|Good to see you again!|Ready?|Let\'s see what they are doing!';

  @override
  String get subGreetingsList =>
      'Everything is fine here.|Seems to be sleeping.|Full of energy!|Watching the area.|Waiting for dinner.|Sniffing something.|Resting peacefully.|At the favorite spot.|Wants to play.|Everything is quiet.';

  @override
  String get petTypeTitle => 'Pet Type';

  @override
  String get petTypeDog => 'Dog';

  @override
  String get petTypeCat => 'Cat';

  @override
  String get petTypeRabbit => 'Rabbit';

  @override
  String get petTypeGuineaPig => 'Guinea Pig';

  @override
  String get petTypeBird => 'Bird';

  @override
  String get petTypeOther => 'Other';

  @override
  String get alertsTitle => 'Notifications';

  @override
  String get alertsZone => 'Zone alerts (Enter/Exit)';

  @override
  String get alertsBattery => 'Low battery alert';

  @override
  String batteryThreshold(int level) {
    return 'Battery threshold: $level%';
  }

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotifTitle => 'Test Notification';

  @override
  String get testNotifBody => 'You have successfully set up notifications!';

  @override
  String secondsAgo(int seconds) {
    return '$seconds seconds ago';
  }

  @override
  String get toiletZone => 'Litter Box / Toilet';

  @override
  String get bedZone => 'Bed / Resting Area';

  @override
  String get waterZone => 'Water Bowl';

  @override
  String get foodZone => 'Food Bowl';

  @override
  String get playZone => 'Play Area';

  @override
  String get appearance => 'Appearance (Theme)';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String failedToLoadPetProfile(String e) {
    return 'Failed to load Pet Profile $e';
  }

  @override
  String get invalidSecretToken => 'Invalid Secret Token!';

  @override
  String decodingError(String e) {
    return 'Decoding error: $e';
  }

  @override
  String get setupWelcomeTitle => 'Welcome to PetTrack!';

  @override
  String get setupWelcomeDesc =>
      'The best way to keep track of your pet.\n\nFirst, let\'s connect to the server.';

  @override
  String get setupScanBtn => 'Read QR Code';

  @override
  String get setupSuccessTitle => 'Success!';

  @override
  String get setupSuccessDesc =>
      'The connection is encrypted.\nNow let\'s register your pet.';

  @override
  String get setupNextBtn => 'Next Step';

  @override
  String get setupErrConnect =>
      'Failed to connect to the server! Check the network.';

  @override
  String get setupErrSave => 'Failed to save profile.';

  @override
  String get setupErrEmpty => 'Please enter a name!';

  @override
  String get setupMonitorTitle => 'Monitor Setup';

  @override
  String get setupMonitorDesc =>
      'Open the Monitor app on the other phone and scan this QR code to connect!';

  @override
  String get settingsShowQrBtn => 'Show QR Code';

  @override
  String get settingsQrDialogDesc => 'Scan with the old phone:';

  @override
  String get settingsQrDialogDone => 'Done';

  @override
  String get settingsResetApp => 'Reset App & Restart Setup';

  @override
  String get settingsResetConfirmTitle => 'Are you sure?';

  @override
  String get settingsResetConfirmDesc =>
      'This will delete all saved data and restart the setup wizard.';

  @override
  String get serverUnreachableTitle => 'Server Unreachable';

  @override
  String get serverUnreachableDesc =>
      'Cannot connect to the PetTrack server.\nPlease check your network or if the server is running.';

  @override
  String get profileAndSystem => 'Profile & System';

  @override
  String get monitorAndConnection => 'Monitor & Connection';

  @override
  String get offlineStatus => 'OFFLINE!';

  @override
  String get liveStatus => 'Live';

  @override
  String get searchingStatus => 'Searching...';

  @override
  String get navMedical => 'Medical';

  @override
  String get medications => 'Medications';

  @override
  String get vaccines => 'Vaccines';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get addVaccine => 'Add Vaccine';

  @override
  String get dose => 'Dose';

  @override
  String get time => 'Time';

  @override
  String get dateGiven => 'Date Given';

  @override
  String get nextDue => 'Next Due';

  @override
  String get enableAlert => 'Enable Alert';

  @override
  String get medName => 'Medication name';

  @override
  String get vacName => 'Vaccine name';

  @override
  String get noMedications => 'No medications added yet.';

  @override
  String get noVaccines => 'No vaccines added yet.';

  @override
  String get saveMedication => 'Save Medication';

  @override
  String get saveVaccine => 'Save Vaccine';

  @override
  String get cardColor => 'Card Color:';

  @override
  String get alertFrequency => 'Alert frequency (in hours)';

  @override
  String get alertFrequencyHint => 'e.g, 12 or 24';

  @override
  String get medTimeTitle => 'Medication Time!';

  @override
  String medTimeBody(String name, String dose) {
    return 'Time to give: $name ($dose)';
  }

  @override
  String everyXHours(int hours) {
    return 'Every $hours hours';
  }

  @override
  String get setupTitle => 'PetTrack Monitor Setup';

  @override
  String get monitorTitle => 'PetTrack Monitor';

  @override
  String get monitorSleepMode => 'Sleep Mode (Dim Screen)';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDescription =>
      'This app securely streams your camera feed to the PetTrack backend.';

  @override
  String get monitorStreamingLive => 'Streaming live video...';

  @override
  String get monitorWaitingForStart => 'Waiting for START command...';

  @override
  String get monitorReconnecting => 'Reconnecting...';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String monitorServer(String ip) {
    return 'Server:\n$ip';
  }

  @override
  String get monitorSleeping => 'Sleeping... Double tap to wake';

  @override
  String errorConnectionFailed(String error) {
    return 'Failed to connect to server! Check IP and Token.\nError: $error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => 'Scan the QR code from the PetTrack App';

  @override
  String get lightMode => '☀️ Light Mode';

  @override
  String get darkMode => '🌙 Dark Mode';

  @override
  String get welcomeTitle => 'Welcome to PetTrack';

  @override
  String get chooseMode => 'Choose your mode';

  @override
  String get modeClient => 'Client (Viewer)';

  @override
  String get modeClientDesc => 'This device will watch the stream.';

  @override
  String get modeMonitor => 'Monitor (Camera)';

  @override
  String get modeMonitorDesc => 'This device will stream video.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get demoModeTitle => 'Demo Mode';

  @override
  String get demoModePrompt => 'Would you like to enter Demo Mode?';

  @override
  String get exit => 'Exit';

  @override
  String get demoLivePreview => 'DEMO MODE, LIVE PREVIEW HERE!';

  @override
  String get zoneSaved => 'Zone saved!';

  @override
  String zoneSaveError(String e) {
    return 'Error: $e';
  }

  @override
  String get newZoneTitle => 'Adding a new zone';

  @override
  String get zoneNameHint => 'Zone name...';

  @override
  String get noZonesYet => 'No zones yet.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get submitPin => 'Submit PIN';

  @override
  String get demoModeBtn => 'Demo Mode';

  @override
  String get orSeparator => 'OR';

  @override
  String get setupErrPin => 'Failed to connect or invalid PIN!';

  @override
  String get saveSuccess => 'Settings saved!';

  @override
  String get navReplays => 'Replays';

  @override
  String get replaysTitle => 'Replays';

  @override
  String get logOut => 'Log Out';

  @override
  String replaysLoadError(int code) {
    return 'Failed to load replays (Error $code)';
  }

  @override
  String replaysNetworkError(String e) {
    return 'Network error: $e';
  }

  @override
  String get close => 'Close';

  @override
  String get openDownload => 'Open / Download';

  @override
  String get retry => 'Retry';

  @override
  String get noReplays => 'No replays recorded yet.';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => 'Scan QR Code';

  @override
  String get qrScannerHint => 'Scan the QR code shown in the server terminal!';

  @override
  String get notifChannelAlertsName => 'PetTrack Alerts';

  @override
  String get notifChannelAlertsDesc =>
      'Notifications about zone changes and battery';

  @override
  String get notifChannelMedicalName => 'Medical Alerts';

  @override
  String get notifChannelMedicalDesc => 'Notifications about giving medication';

  @override
  String get syncToWatch => 'Sync with Smartwatch';

  @override
  String get syncStarting => 'Starting sync...';

  @override
  String get syncSuccess => 'Successfully sent to the watch!';

  @override
  String get syncNoWatch => 'No connected watch found.';

  @override
  String get onlineStatus => 'Online';

  @override
  String get eventLog => 'Event Log';

  @override
  String get shareInviteText => 'Look what my pet is doing!';

  @override
  String get chooseLanguageTitle => 'Choose Language';

  @override
  String get languageChinese => '中文';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get aiGeneratedMarker => '(AI-GENERATED)';

  @override
  String get wearSynced => 'Synced!';

  @override
  String get wearOpenAppOnPhone => 'Open the app on your phone.';

  @override
  String get wearManual => 'Manual';

  @override
  String get wearSetupTitle => 'Setup';

  @override
  String get pinHint => '4-digit PIN';

  @override
  String get errInvalidPin => 'Invalid PIN!';

  @override
  String get errNetwork => 'Network error!';

  @override
  String get defaultPetName => 'Pet';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => 'Find server on network';

  @override
  String get discoveryTitle => 'Servers on your network';

  @override
  String get discoverySearching => 'Searching your local network…';

  @override
  String get discoveryEmpty => 'No PetTrack server found yet.';

  @override
  String get discoveryHint =>
      'Make sure the server is running and you are on the same Wi-Fi.';

  @override
  String get discoveryNotSupported =>
      'Automatic discovery is not available on this device. Enter the server address manually.';

  @override
  String get discoveryTapToUse => 'Tap to connect';

  @override
  String get tooltipRefresh => 'Refresh';

  @override
  String get tooltipAdd => 'Add';

  @override
  String get tooltipDelete => 'Delete';

  @override
  String get highlightTitle => 'Today\'s recap';

  @override
  String get highlightSubtitle => 'Every moment from today in one clip';

  @override
  String highlightMoments(Object count) {
    return '$count moments';
  }

  @override
  String get highlightShare => 'Share';

  @override
  String get quietHoursTitle => 'Quiet hours';

  @override
  String get quietHoursSubtitle => 'No zone or battery alerts during this time';

  @override
  String get quietHoursFrom => 'From';

  @override
  String get quietHoursTo => 'Until';

  @override
  String get batteryLowTitle => 'Low battery';

  @override
  String batteryLowBody(int level) {
    return 'Battery at $level%';
  }

  @override
  String get aboutCardTitle => 'About & updates';

  @override
  String get versionAppLabel => 'App';

  @override
  String get versionServerLabel => 'Server';

  @override
  String get versionCheckButton => 'Check now';

  @override
  String get versionUnknown => 'Not connected';

  @override
  String get versionMatch => 'App and server versions match';

  @override
  String get versionAppOlder => 'The server is newer — update the app';

  @override
  String get versionServerOlder => 'The app is newer — update the server';
}
