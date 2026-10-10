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
  String get serverIp => 'Server address';

  @override
  String get serverIpHint => 'e.g. 192.168.1.100';

  @override
  String get secretToken => 'Pairing secret';

  @override
  String get petName => 'Your pet\'s name';

  @override
  String get petNameHint => 'e.g. Berci';

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
  String get petTypeTitle => 'What kind of pet?';

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
  String alertsZone(String petName) {
    return 'Tell me when $petName enters or leaves a zone';
  }

  @override
  String get alertsZoneGeneric => 'Tell me when my pet enters or leaves a zone';

  @override
  String get alertsBattery => 'Warn me when the camera phone is low on battery';

  @override
  String batteryThreshold(int level) {
    return 'Warn me at $level% or below';
  }

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotifTitle => 'Test Notification';

  @override
  String get testNotifBody => 'You have successfully set up notifications!';

  @override
  String get alertsRemoteTitle => 'Alerts when I\'m away';

  @override
  String get alertsRemoteDesc =>
      'Forwards alerts to an ntfy topic so they reach you anywhere — in the ntfy app or any browser. Pick a topic name that is hard to guess; anyone with the link can subscribe.';

  @override
  String get alertsRemoteUrlLabel => 'ntfy topic URL';

  @override
  String get alertsRemoteUrlHint => 'https://ntfy.sh/your-secret-topic';

  @override
  String get alertsRemoteTokenLabel => 'Access token (optional)';

  @override
  String get alertsRemoteTest => 'Send test notification';

  @override
  String get alertsRemoteTestSent =>
      'Test notification sent — check your phone.';

  @override
  String get alertsRemoteTestFailed =>
      'Could not send the test notification. Check the topic URL and the server.';

  @override
  String get alertsRemoteUrlInvalid =>
      'That does not look like a valid ntfy URL.';

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
  String get settingsShowQrBtn => 'Show pairing QR code';

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
  String get profileAndSystem => 'My pet';

  @override
  String get monitorAndConnection => 'Server & pairing';

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
  String get monitorBatterySaver => 'Battery saver — streaming slower';

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
  String get demoNoPlayback => 'Demo mode — video playback is not available';

  @override
  String get insightsTitle => 'Activity insights';

  @override
  String get insightsEntrySubtitle => 'Activity, zones and rest at a glance';

  @override
  String insightsRangeDays(int n) {
    return '$n days';
  }

  @override
  String get insightsActiveToday => 'Active today';

  @override
  String get insightsAvgPerDay => 'Per day (average)';

  @override
  String get insightsMostActiveZone => 'Top zone';

  @override
  String get insightsActivityChart => 'Active minutes per day';

  @override
  String get insightsZoneChart => 'Time per zone';

  @override
  String get insightsZoneEmpty => 'No zone stays recorded in this range';

  @override
  String get insightsActiveVsRest => 'Active vs rest (average day)';

  @override
  String get insightsWordActive => 'Active';

  @override
  String get insightsWordRest => 'Rest';

  @override
  String get insightsTableDay => 'Day';

  @override
  String get tooltipInsightsList => 'Show as a table';

  @override
  String get tooltipInsightsChart => 'Show as a chart';

  @override
  String insightsDurationH(int n) {
    return '$n h';
  }

  @override
  String insightsDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String insightsDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String insightsDurationS(int seconds) {
    return '$seconds s';
  }

  @override
  String insightsClips(int n) {
    return '$n motion clips';
  }

  @override
  String insightsSounds(int n) {
    return '$n sound events';
  }

  @override
  String get insightsLoadError => 'Could not load insights';

  @override
  String get demoZoneKitchen => 'Kitchen';

  @override
  String get demoZoneSofa => 'Sofa';

  @override
  String get demoZoneBed => 'Bed';

  @override
  String get demoZoneGarden => 'Garden';

  @override
  String get healthCardTitle => 'System health';

  @override
  String get healthCameraOnline => 'Camera online';

  @override
  String get healthCameraOffline => 'Camera offline';

  @override
  String healthLastSeen(String duration) {
    return 'Last seen: $duration';
  }

  @override
  String healthDiskFreeOf(String free, String total) {
    return '$free free of $total';
  }

  @override
  String get healthDiskLow => 'Disk space is low — old replays will be pruned';

  @override
  String healthReplaysStored(int count, String size) {
    return '$count replays · $size';
  }

  @override
  String get healthKeepReplays => 'Keep replays for';

  @override
  String get healthRetentionSaved => 'Replay retention updated';

  @override
  String get healthCleanupNow => 'Free up space now';

  @override
  String healthCleanupDone(String size, int count) {
    return 'Freed $size — $count items cleaned up.';
  }

  @override
  String get healthCleanupNone =>
      'Nothing to clean up — everything is within the retention window.';

  @override
  String get healthCleanupFailed => 'Cleanup failed. Try again.';

  @override
  String get healthLoadError => 'Could not load system health';

  @override
  String get cameraOfflineTitle => 'Camera offline';

  @override
  String get cameraOfflineBody => 'No video from the camera for 10 minutes';

  @override
  String get diskLowTitle => 'Disk space low';

  @override
  String get diskLowBody => 'Old replays are being pruned to free up space';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutTitle => 'Sign out of this server?';

  @override
  String get settingsSignOutMessage =>
      'This device forgets its tokens and its session on the server is revoked. Sign in again with the pairing PIN.';

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
  String get tooltipShare => 'Share';

  @override
  String get shareLink => 'Share link';

  @override
  String get quietHoursTitle => 'Quiet hours';

  @override
  String get quietHoursSubtitle =>
      'No alerts during this time — the camera keeps watching';

  @override
  String get quietHoursFrom => 'From';

  @override
  String get quietHoursTo => 'Until';

  @override
  String get snoozeTitle => 'Snooze alerts';

  @override
  String get snoozeChip => 'Snooze';

  @override
  String get snoozeChipActive => 'Snoozed';

  @override
  String get snooze30m => 'For 30 minutes';

  @override
  String get snooze1h => 'For an hour';

  @override
  String get snoozeTonight => 'Until 23:00';

  @override
  String get snoozeEnd => 'End snooze';

  @override
  String snoozeActive(String time) {
    return 'Alerts snoozed on this phone until $time';
  }

  @override
  String get snoozeEnded => 'Alerts are back on this phone.';

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

  @override
  String updateAvailable(String version) {
    return 'Version $version is ready to install';
  }

  @override
  String get updateInstallButton => 'Install update';

  @override
  String get updateDownloading => 'Downloading…';

  @override
  String get updateDownloadFailed =>
      'Could not download the update. Check the server and try again.';

  @override
  String get updateInstallFailed => 'Could not open the Android installer.';

  @override
  String get privacyButton => 'Privacy';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'PetTrack is fully self-hosted — your camera feed, recordings and pet data stay on your own server.\n\n• No cloud, nothing is uploaded anywhere\n• No account — there is no service to sign up for\n• No analytics or tracking\n• LAN-only by default; remote access is only what you set up yourself';

  @override
  String get whatsNewButton => 'What\'s new';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String get changelogBody =>
      '1.0.0\n• Today\'s recap on the dashboard\n• Quiet hours for alerts\n• Home Assistant integration\n• Material 3 redesign';

  @override
  String get tooltipPlaySound => 'Play a sound';

  @override
  String get cameraGridLabel => 'All cameras';

  @override
  String get widgetEmptyHint => 'Open PetTrack to load the camera';

  @override
  String get tooltipSnapshot => 'Take a snapshot';

  @override
  String get playSoundSent => 'Sound sent to the monitor';

  @override
  String get tooltipTimelapse => 'Day timelapse';

  @override
  String get tooltipRecap => 'Day recap';

  @override
  String get recapBuilding => 'Building the day\'s recap…';

  @override
  String get recapEmpty => 'No moments for this day';

  @override
  String recapError(int code) {
    return 'Could not build the recap (error $code)';
  }

  @override
  String get replayAllDays => 'All days';

  @override
  String get replaysHourStripTitle => 'Activity by hour';

  @override
  String replaysHourTooltip(String hour, int count) {
    return '$hour:00 — $count events';
  }

  @override
  String get replaysHourClear => 'Whole day';

  @override
  String get pinClip => 'Pin clip';

  @override
  String get unpinClip => 'Unpin';

  @override
  String get clipPinned => 'Pinned — this one stays.';

  @override
  String get clipUnpinned => 'Unpinned.';

  @override
  String get clipPinFailed => 'Could not update the pin.';

  @override
  String get deleteClip => 'Delete clip';

  @override
  String get deleteClipTitle => 'Delete this clip?';

  @override
  String get deleteClipBody =>
      'This removes the recording from the server for good — it can\'t be undone. A pinned clip loses its pin too.';

  @override
  String get deleteClipConfirm => 'Delete';

  @override
  String get clipDeleted => 'Clip deleted.';

  @override
  String get clipDeleteFailed => 'Could not delete the clip.';

  @override
  String get noReplaysForDay => 'No replays for this day';

  @override
  String get timelapseBuilding => 'Building the day\'s timelapse…';

  @override
  String get timelapseEmpty => 'Not enough frames for this day';

  @override
  String timelapseError(int code) {
    return 'Could not build the timelapse (error $code)';
  }

  @override
  String get tooltipNightMode => 'Night mode';

  @override
  String get nightModeOn => 'Night mode on';

  @override
  String get nightModeOff => 'Night mode off';

  @override
  String get alertsSound => 'Tell me when I hear barking or meowing';

  @override
  String get soundDetectedTitle => 'Sound detected';

  @override
  String get soundDetectedBody => 'Loud noise near the camera.';

  @override
  String get demoZoneLitter => 'Litter box';

  @override
  String get demoZonePlayground => 'Playground';

  @override
  String get demoZoneFeeder => 'Feeder';

  @override
  String get demoMedName => 'Digestive supplement';

  @override
  String get demoMedDose => '0.5 ml';

  @override
  String get demoVacName => 'Myxomatosis vaccine';

  @override
  String get activityLoadError => 'Could not load recent activity';

  @override
  String get zonesLoadError => 'Could not load zones';

  @override
  String get cameraStartFailed => 'Could not start the camera';

  @override
  String get videoLoadError => 'Could not play this clip';

  @override
  String get medicalCachedNotice =>
      'The server is unreachable — showing your saved copy';

  @override
  String get tooltipPlayPause => 'Play / pause';

  @override
  String get settingsSaveError => 'Could not save the change';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsAdvancedDesc =>
      'Server address, pairing and account — the wiring behind the app. You rarely need this.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get shareFailed => 'Could not share';

  @override
  String get evidenceNoClip => 'No clip recorded near that moment';

  @override
  String get feedSearchHint => 'Search events';

  @override
  String get feedSearchClear => 'Clear';

  @override
  String get feedFilterAll => 'All';

  @override
  String get feedFilterZones => 'Zones';

  @override
  String get feedFilterSounds => 'Sounds';

  @override
  String get feedFilterSystem => 'System';

  @override
  String get feedNoMatch => 'No matching events';

  @override
  String get feedExport => 'Export CSV';

  @override
  String get feedExportEmpty => 'Nothing to export yet.';

  @override
  String get feedExportFailed => 'Could not export the feed.';

  @override
  String recapBanner(String count) {
    return 'Last night: $count events';
  }

  @override
  String get recapDismiss => 'Got it';

  @override
  String get feedbackTitle => 'Teach PetTrack';

  @override
  String get feedbackBody =>
      'Was this your pet? Notes like this help PetTrack learn who belongs on camera.';

  @override
  String get feedbackNotMyPet => 'Not my pet';

  @override
  String get feedbackIsMyPet => 'That\'s my pet';

  @override
  String get feedbackThanks => 'Thanks — PetTrack will learn from that.';

  @override
  String get feedbackFailed => 'Could not send that note.';

  @override
  String feedAllQuiet(String duration) {
    return 'All quiet for $duration';
  }

  @override
  String get armingTitle => 'Watching';

  @override
  String get armingModeOn => 'Always on';

  @override
  String get armingModeSchedule => 'On a schedule';

  @override
  String get armingModeOff => 'Off';

  @override
  String get armingStatusArmed => 'Armed';

  @override
  String get armingStatusDisarmed => 'Disarmed';

  @override
  String get armingAddWindow => 'Add window';

  @override
  String get armingRemoveWindow => 'Remove window';

  @override
  String get armingFrom => 'From';

  @override
  String get armingTo => 'To';

  @override
  String get armingDays => 'Days';

  @override
  String get armingHelp =>
      'Armed records motion and raises alerts; disarmed keeps no footage. Live view always works.';

  @override
  String get armingWindowRequired => 'Add at least one window';

  @override
  String get semanticCameraView => 'Camera view';

  @override
  String get semanticChangePhoto => 'Change profile picture';

  @override
  String get semanticZoneCanvas => 'Zone editor — tap to place a point';

  @override
  String get semanticWakeMonitor => 'Double tap to wake the monitor';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Purple';

  @override
  String get tooltipConfirm => 'Confirm';

  @override
  String get backupCardTitle => 'Backup & restore';

  @override
  String get backupHelp =>
      'Keep your setup in one file — restore it on a new phone or after a reinstall. The file contains your pairing secret, so anyone holding it can reach your cameras.';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupRestore => 'Restore from backup';

  @override
  String get backupExportTitle => 'Export backup?';

  @override
  String get backupExportBody =>
      'The backup file contains your pairing secret. Share it only with yourself — anyone with this file can access your cameras.';

  @override
  String get backupRestoreTitle => 'Restore backup?';

  @override
  String get backupRestoreBody =>
      'This replaces the settings on this phone and, when the server is reachable, on the server too.';

  @override
  String get backupInvalid => 'That file is not a PetTrack backup';

  @override
  String get backupRestored => 'Backup restored';

  @override
  String get backupRestoredOffline =>
      'Backup restored on this phone. Open Settings and save to sync with the server.';

  @override
  String get backupRestoreError => 'Could not restore the backup';

  @override
  String get setupSkipMonitor => 'Skip for now';

  @override
  String get setupMissingFields => 'Enter the server address and the PIN';
}
