// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get uploadProfilePicture => 'Profilbild hochladen';

  @override
  String get serverIp => 'Server-IP';

  @override
  String get serverIpHint => 'z. B. 192.168.1.100';

  @override
  String get secretToken => 'Geheimtoken';

  @override
  String get petName => 'Name des Haustiers';

  @override
  String get petNameHint => 'Namen eingeben';

  @override
  String get save => 'Speichern';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navZones => 'Zonen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get liveVideo => 'Live-Video';

  @override
  String get activities => 'Aktivitäten';

  @override
  String get noRecentEvents => 'Keine aktuellen Ereignisse';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petName hat $zone betreten';
  }

  @override
  String get zoneVisits => 'Zonenbesuche';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petName hat $zone verlassen';
  }

  @override
  String get cameraDetectedMovement => 'Die Kamera hat eine Bewegung erkannt.';

  @override
  String get editZones => 'Zonen bearbeiten';

  @override
  String get addNewZone => 'Neue Zone hinzufügen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get existingZones => 'Vorhandene Zonen';

  @override
  String get safeZone => 'Sichere Zone';

  @override
  String get today => 'Heute';

  @override
  String get language => 'Sprache';

  @override
  String get lastUpdated => 'Zuletzt aktualisiert';

  @override
  String get justNow => 'Gerade eben';

  @override
  String minsAgo(int mins) {
    return 'vor $mins Min.';
  }

  @override
  String hoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String daysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String get unknown => 'Unbekannt';

  @override
  String get leftTheZone => 'Zone verlassen.';

  @override
  String get greetingsList =>
      'Hi Boss!|Willkommen zurück!|Schönen Tag!|Hey!|Wie geht\'s?|Hallo!|Was gibt\'s Neues?|Schön, dich wiederzusehen!|Bereit?|Lass uns sehen, was los ist!';

  @override
  String get subGreetingsList =>
      'Alles in Ordnung hier.|Scheint zu schlafen.|Voller Energie!|Beobachtet die Umgebung.|Wartet auf das Futter.|Schnüffelt an etwas.|Ruhet sich aus.|Am Lieblingsplatz.|Will spielen.|Alles ruhig.';

  @override
  String get petTypeTitle => 'Haustiertyp';

  @override
  String get petTypeDog => 'Hund';

  @override
  String get petTypeCat => 'Katze';

  @override
  String get petTypeRabbit => 'Kaninchen';

  @override
  String get petTypeGuineaPig => 'Meerschweinchen';

  @override
  String get petTypeBird => 'Vogel';

  @override
  String get petTypeOther => 'Sonstiges';

  @override
  String get alertsTitle => 'Benachrichtigungen';

  @override
  String get alertsZone => 'Zonenwarnungen (Betreten/Verlassen)';

  @override
  String get alertsBattery => 'Warnung bei niedrigem Akku';

  @override
  String batteryThreshold(int level) {
    return 'Akkuschwelle: $level%';
  }

  @override
  String get testNotification => 'Testbenachrichtigung';

  @override
  String get testNotifTitle => 'Testbenachrichtigung';

  @override
  String get testNotifBody =>
      'Benachrichtigungen wurden erfolgreich eingerichtet!';

  @override
  String get alertsRemoteTitle => 'Warnungen, wenn ich weg bin';

  @override
  String get alertsRemoteDesc =>
      'Leitet Warnungen an ein ntfy-Thema weiter, damit sie überall ankommen — in der ntfy-App oder im Browser. Wähle einen schwer zu erratenden Themennamen; jeder mit dem Link kann abonnieren.';

  @override
  String get alertsRemoteUrlLabel => 'ntfy-Themen-URL';

  @override
  String get alertsRemoteUrlHint => 'https://ntfy.sh/dein-geheimes-thema';

  @override
  String get alertsRemoteTokenLabel => 'Zugriffstoken (optional)';

  @override
  String get alertsRemoteTest => 'Testbenachrichtigung senden';

  @override
  String get alertsRemoteTestSent =>
      'Testbenachrichtigung gesendet — schau auf dein Handy.';

  @override
  String get alertsRemoteTestFailed =>
      'Die Testbenachrichtigung konnte nicht gesendet werden. Prüfe die Themen-URL und den Server.';

  @override
  String get alertsRemoteUrlInvalid =>
      'Das sieht nicht nach einer gültigen ntfy-URL aus.';

  @override
  String secondsAgo(int seconds) {
    return 'vor $seconds Sek.';
  }

  @override
  String get toiletZone => 'Katzentoilette / WC';

  @override
  String get bedZone => 'Schlaf- / Ruhebereich';

  @override
  String get waterZone => 'Wasserschale';

  @override
  String get foodZone => 'Futternapf';

  @override
  String get playZone => 'Spielbereich';

  @override
  String get appearance => 'Erscheinungsbild (Design)';

  @override
  String get themeSystem => 'Systemstandard';

  @override
  String get themeLight => 'Heller Modus';

  @override
  String get themeDark => 'Dunkler Modus';

  @override
  String failedToLoadPetProfile(String e) {
    return 'Haustierprofil konnte nicht geladen werden: $e';
  }

  @override
  String get invalidSecretToken => 'Ungültiges Geheimtoken!';

  @override
  String decodingError(String e) {
    return 'Dekodierfehler: $e';
  }

  @override
  String get setupWelcomeTitle => 'Willkommen bei PetTrack!';

  @override
  String get setupWelcomeDesc =>
      'Die beste Möglichkeit, dein Haustier im Blick zu behalten.\n\nVerbinden wir uns zuerst mit dem Server.';

  @override
  String get setupScanBtn => 'QR-Code lesen';

  @override
  String get setupSuccessTitle => 'Geschafft!';

  @override
  String get setupSuccessDesc =>
      'Die Verbindung ist verschlüsselt.\nJetzt registrieren wir dein Haustier.';

  @override
  String get setupNextBtn => 'Nächster Schritt';

  @override
  String get setupErrConnect =>
      'Verbindung zum Server fehlgeschlagen! Netzwerk prüfen.';

  @override
  String get setupErrSave => 'Profil konnte nicht gespeichert werden.';

  @override
  String get setupErrEmpty => 'Bitte gib einen Namen ein!';

  @override
  String get setupMonitorTitle => 'Monitor-Einrichtung';

  @override
  String get setupMonitorDesc =>
      'Öffne die Monitor-App auf dem anderen Handy und scanne diesen QR-Code, um dich zu verbinden!';

  @override
  String get settingsShowQrBtn => 'QR-Code anzeigen';

  @override
  String get settingsQrDialogDesc => 'Mit dem alten Handy scannen:';

  @override
  String get settingsQrDialogDone => 'Fertig';

  @override
  String get settingsResetApp => 'App zurücksetzen & Einrichtung neu starten';

  @override
  String get settingsResetConfirmTitle => 'Bist du sicher?';

  @override
  String get settingsResetConfirmDesc =>
      'Dadurch werden alle gespeicherten Daten gelöscht und der Einrichtungsassistent neu gestartet.';

  @override
  String get serverUnreachableTitle => 'Server nicht erreichbar';

  @override
  String get serverUnreachableDesc =>
      'Keine Verbindung zum PetTrack-Server.\nBitte prüfe dein Netzwerk oder ob der Server läuft.';

  @override
  String get profileAndSystem => 'Profil & System';

  @override
  String get monitorAndConnection => 'Monitor & Verbindung';

  @override
  String get offlineStatus => 'OFFLINE!';

  @override
  String get liveStatus => 'Live';

  @override
  String get searchingStatus => 'Suche...';

  @override
  String get navMedical => 'Medizinisch';

  @override
  String get medications => 'Medikamente';

  @override
  String get vaccines => 'Impfungen';

  @override
  String get addMedication => 'Medikament hinzufügen';

  @override
  String get addVaccine => 'Impfung hinzufügen';

  @override
  String get dose => 'Dosis';

  @override
  String get time => 'Zeit';

  @override
  String get dateGiven => 'Verabreicht am';

  @override
  String get nextDue => 'Nächste Fälligkeit';

  @override
  String get enableAlert => 'Benachrichtigung aktivieren';

  @override
  String get medName => 'Name des Medikaments';

  @override
  String get vacName => 'Name des Impfstoffs';

  @override
  String get noMedications => 'Noch keine Medikamente hinzugefügt.';

  @override
  String get noVaccines => 'Noch keine Impfungen hinzugefügt.';

  @override
  String get saveMedication => 'Medikament speichern';

  @override
  String get saveVaccine => 'Impfung speichern';

  @override
  String get cardColor => 'Kartenfarbe:';

  @override
  String get alertFrequency => 'Benachrichtigungsintervall (in Stunden)';

  @override
  String get alertFrequencyHint => 'z. B. 12 oder 24';

  @override
  String get medTimeTitle => 'Medikamentenzeit!';

  @override
  String medTimeBody(String name, String dose) {
    return 'Zeit zu geben: $name ($dose)';
  }

  @override
  String everyXHours(int hours) {
    return 'Alle $hours Stunden';
  }

  @override
  String get setupTitle => 'PetTrack Monitor-Einrichtung';

  @override
  String get monitorTitle => 'PetTrack Monitor';

  @override
  String get monitorSleepMode => 'Ruhezustand (Bildschirm dimmen)';

  @override
  String get aboutTitle => 'Über';

  @override
  String get aboutDescription =>
      'Diese App streamt deinen Kamerastrom sicher an das PetTrack-Backend.';

  @override
  String get monitorStreamingLive => 'Live-Video wird gestreamt...';

  @override
  String get monitorWaitingForStart => 'Warte auf START-Befehl...';

  @override
  String get monitorReconnecting => 'Verbindung wird wiederhergestellt...';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stopp';

  @override
  String monitorServer(String ip) {
    return 'Server:\n$ip';
  }

  @override
  String get monitorSleeping => 'Schlafend... Zweimal tippen zum Aufwecken';

  @override
  String errorConnectionFailed(String error) {
    return 'Verbindung zum Server fehlgeschlagen! IP und Token prüfen.\nFehler: $error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => 'Scanne den QR-Code aus der PetTrack-App';

  @override
  String get lightMode => '☀️ Heller Modus';

  @override
  String get darkMode => '🌙 Dunkler Modus';

  @override
  String get welcomeTitle => 'Willkommen bei PetTrack';

  @override
  String get chooseMode => 'Wähle deinen Modus';

  @override
  String get modeClient => 'Client (Betrachter)';

  @override
  String get modeClientDesc => 'Dieses Gerät wird den Stream ansehen.';

  @override
  String get modeMonitor => 'Monitor (Kamera)';

  @override
  String get modeMonitorDesc => 'Dieses Gerät wird Video streamen.';

  @override
  String get enterPin => 'PIN eingeben';

  @override
  String get demoModeTitle => 'Demo-Modus';

  @override
  String get demoModePrompt => 'Möchtest du in den Demo-Modus wechseln?';

  @override
  String get exit => 'Beenden';

  @override
  String get demoLivePreview => 'DEMO-MODUS, LIVE-VORSCHAU HIER!';

  @override
  String get zoneSaved => 'Zone gespeichert!';

  @override
  String zoneSaveError(String e) {
    return 'Fehler: $e';
  }

  @override
  String get newZoneTitle => 'Neue Zone hinzufügen';

  @override
  String get zoneNameHint => 'Zonenname...';

  @override
  String get noZonesYet => 'Noch keine Zonen.';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get submitPin => 'PIN senden';

  @override
  String get demoModeBtn => 'Demo-Modus';

  @override
  String get demoNoPlayback =>
      'Demo-Modus — Videowiedergabe ist nicht verfügbar';

  @override
  String get insightsTitle => 'Aktivitäts-Insights';

  @override
  String get insightsEntrySubtitle =>
      'Aktivität, Zonen und Ruhe auf einen Blick';

  @override
  String insightsRangeDays(int n) {
    return '$n Tage';
  }

  @override
  String get insightsActiveToday => 'Heute aktiv';

  @override
  String get insightsAvgPerDay => 'Pro Tag (Durchschnitt)';

  @override
  String get insightsMostActiveZone => 'Meistgenutzte Zone';

  @override
  String get insightsActivityChart => 'Aktive Minuten pro Tag';

  @override
  String get insightsZoneChart => 'Zeit pro Zone';

  @override
  String get insightsZoneEmpty => 'In diesem Zeitraum keine Zonenaufenthalte';

  @override
  String get insightsActiveVsRest => 'Aktiv vs. Ruhe (Durchschnittstag)';

  @override
  String get insightsWordActive => 'Aktiv';

  @override
  String get insightsWordRest => 'Ruhe';

  @override
  String get insightsTableDay => 'Tag';

  @override
  String get tooltipInsightsList => 'Als Tabelle anzeigen';

  @override
  String get tooltipInsightsChart => 'Als Diagramm anzeigen';

  @override
  String insightsDurationH(int n) {
    return '$n Std.';
  }

  @override
  String insightsDurationHm(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String insightsDurationM(int minutes) {
    return '$minutes Min.';
  }

  @override
  String insightsDurationS(int seconds) {
    return '$seconds Sek.';
  }

  @override
  String insightsClips(int n) {
    return '$n Bewegungsclips';
  }

  @override
  String insightsSounds(int n) {
    return '$n Geräuschereignisse';
  }

  @override
  String get insightsLoadError => 'Insights konnten nicht geladen werden';

  @override
  String get demoZoneKitchen => 'Küche';

  @override
  String get demoZoneSofa => 'Sofa';

  @override
  String get demoZoneBed => 'Bett';

  @override
  String get demoZoneGarden => 'Garten';

  @override
  String get healthCardTitle => 'Systemzustand';

  @override
  String get healthCameraOnline => 'Kamera online';

  @override
  String get healthCameraOffline => 'Kamera offline';

  @override
  String healthLastSeen(String duration) {
    return 'Zuletzt gesehen: $duration';
  }

  @override
  String healthDiskFreeOf(String free, String total) {
    return '$free frei von $total';
  }

  @override
  String get healthDiskLow =>
      'Wenig Speicherplatz — alte Aufnahmen werden gelöscht';

  @override
  String healthReplaysStored(int count, String size) {
    return '$count Aufnahmen · $size';
  }

  @override
  String get healthKeepReplays => 'Aufnahmen behalten für';

  @override
  String get healthRetentionSaved => 'Aufbewahrungszeitraum aktualisiert';

  @override
  String get healthCleanupNow => 'Jetzt Speicher freigeben';

  @override
  String healthCleanupDone(String size, int count) {
    return '$size freigegeben — $count Elemente bereinigt.';
  }

  @override
  String get healthCleanupNone =>
      'Nichts zu bereinigen — alles liegt im Aufbewahrungsfenster.';

  @override
  String get healthCleanupFailed =>
      'Bereinigung fehlgeschlagen. Versuch es erneut.';

  @override
  String get healthLoadError => 'Systemzustand konnte nicht geladen werden';

  @override
  String get cameraOfflineTitle => 'Kamera offline';

  @override
  String get cameraOfflineBody => 'Seit 10 Minuten kein Bild von der Kamera';

  @override
  String get diskLowTitle => 'Wenig Speicherplatz';

  @override
  String get diskLowBody =>
      'Alte Aufnahmen werden gelöscht, um Speicher freizugeben';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsSignOutTitle => 'Von diesem Server abmelden?';

  @override
  String get settingsSignOutMessage =>
      'Dieses Gerät vergisst seine Token und die Sitzung auf dem Server wird widerrufen. Mit der Anmelde-PIN wieder anmelden.';

  @override
  String get orSeparator => 'ODER';

  @override
  String get setupErrPin => 'Verbindung fehlgeschlagen oder ungültige PIN!';

  @override
  String get saveSuccess => 'Einstellungen gespeichert!';

  @override
  String get navReplays => 'Aufnahmen';

  @override
  String get replaysTitle => 'Aufnahmen';

  @override
  String get logOut => 'Abmelden';

  @override
  String replaysLoadError(int code) {
    return 'Aufnahmen konnten nicht geladen werden (Fehler $code)';
  }

  @override
  String replaysNetworkError(String e) {
    return 'Netzwerkfehler: $e';
  }

  @override
  String get close => 'Schließen';

  @override
  String get openDownload => 'Öffnen / Herunterladen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noReplays => 'Noch keine Aufnahmen aufgezeichnet.';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => 'QR-Code scannen';

  @override
  String get qrScannerHint => 'Scanne den QR-Code im Server-Terminal!';

  @override
  String get notifChannelAlertsName => 'PetTrack-Warnungen';

  @override
  String get notifChannelAlertsDesc =>
      'Benachrichtigungen zu Zonenwechseln und Akku';

  @override
  String get notifChannelMedicalName => 'Medizinische Erinnerungen';

  @override
  String get notifChannelMedicalDesc =>
      'Benachrichtigungen zur Medikamentengabe';

  @override
  String get syncToWatch => 'Mit Smartwatch synchronisieren';

  @override
  String get syncStarting => 'Synchronisierung wird gestartet...';

  @override
  String get syncSuccess => 'Erfolgreich an die Uhr gesendet!';

  @override
  String get syncNoWatch => 'Keine verbundene Uhr gefunden.';

  @override
  String get onlineStatus => 'Online';

  @override
  String get eventLog => 'Ereignisprotokoll';

  @override
  String get shareInviteText => 'Schau mal, was mein Haustier macht!';

  @override
  String get chooseLanguageTitle => 'Sprache wählen';

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
  String get aiGeneratedMarker => '(KI-GENERIERT)';

  @override
  String get wearSynced => 'Synchronisiert!';

  @override
  String get wearOpenAppOnPhone => 'Öffne die App auf deinem Handy.';

  @override
  String get wearManual => 'Manuell';

  @override
  String get wearSetupTitle => 'Einrichtung';

  @override
  String get pinHint => '4-stellige PIN';

  @override
  String get errInvalidPin => 'Ungültige PIN!';

  @override
  String get errNetwork => 'Netzwerkfehler!';

  @override
  String get defaultPetName => 'Haustier';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => 'Server im Netzwerk finden';

  @override
  String get discoveryTitle => 'Server in deinem Netzwerk';

  @override
  String get discoverySearching => 'Lokales Netzwerk wird durchsucht…';

  @override
  String get discoveryEmpty => 'Noch kein PetTrack-Server gefunden.';

  @override
  String get discoveryHint =>
      'Stelle sicher, dass der Server läuft und du im selben WLAN bist.';

  @override
  String get discoveryNotSupported =>
      'Automatische Suche ist auf diesem Gerät nicht verfügbar. Gib die Serveradresse manuell ein.';

  @override
  String get discoveryTapToUse => 'Tippen zum Verbinden';

  @override
  String get tooltipRefresh => 'Aktualisieren';

  @override
  String get tooltipAdd => 'Hinzufügen';

  @override
  String get tooltipDelete => 'Löschen';

  @override
  String get highlightTitle => 'Zusammenfassung von heute';

  @override
  String get highlightSubtitle => 'Jeder Moment von heute in einem Clip';

  @override
  String highlightMoments(Object count) {
    return '$count Momente';
  }

  @override
  String get tooltipShare => 'Teilen';

  @override
  String get quietHoursTitle => 'Ruhezeiten';

  @override
  String get quietHoursSubtitle =>
      'Keine Zonen- oder Akku-Warnungen in dieser Zeit';

  @override
  String get quietHoursFrom => 'Von';

  @override
  String get quietHoursTo => 'Bis';

  @override
  String get snoozeTitle => 'Alarme stummschalten';

  @override
  String get snoozeChip => 'Stumm';

  @override
  String get snoozeChipActive => 'Stumm geschaltet';

  @override
  String get snooze30m => 'Für 30 Minuten';

  @override
  String get snooze1h => 'Für eine Stunde';

  @override
  String get snoozeTonight => 'Bis 23:00';

  @override
  String get snoozeEnd => 'Stummschaltung beenden';

  @override
  String snoozeActive(String time) {
    return 'Alarme auf diesem Handy stumm bis $time';
  }

  @override
  String get snoozeEnded => 'Alarme auf diesem Handy sind wieder aktiv.';

  @override
  String get batteryLowTitle => 'Niedriger Akkustand';

  @override
  String batteryLowBody(int level) {
    return 'Akku bei $level %';
  }

  @override
  String get aboutCardTitle => 'Über & Updates';

  @override
  String get versionAppLabel => 'App';

  @override
  String get versionServerLabel => 'Server';

  @override
  String get versionCheckButton => 'Jetzt prüfen';

  @override
  String get versionUnknown => 'Nicht verbunden';

  @override
  String get versionMatch => 'App und Server sind synchron';

  @override
  String get versionAppOlder =>
      'Der Server ist neuer — bitte die App aktualisieren';

  @override
  String get versionServerOlder =>
      'Die App ist neuer — bitte den Server aktualisieren';

  @override
  String updateAvailable(String version) {
    return 'Version $version ist bereit zur Installation';
  }

  @override
  String get updateInstallButton => 'Update installieren';

  @override
  String get updateDownloading => 'Wird heruntergeladen…';

  @override
  String get updateDownloadFailed =>
      'Das Update konnte nicht geladen werden. Prüfe den Server und versuche es erneut.';

  @override
  String get updateInstallFailed =>
      'Der Android-Installer konnte nicht geöffnet werden.';

  @override
  String get privacyButton => 'Datenschutz';

  @override
  String get privacyTitle => 'Datenschutz';

  @override
  String get privacyBody =>
      'PetTrack ist komplett selbst gehostet — Kamerabild, Aufnahmen und Tierdaten bleiben auf deinem eigenen Server.\n\n• Keine Cloud, nichts wird irgendwohin hochgeladen\n• Kein Konto — es gibt keinen Dienst, bei dem man sich anmeldet\n• Keine Analyse oder Nachverfolgung\n• Standardmäßig nur im LAN; Fernzugriff nur, wenn du ihn selbst einrichtest';

  @override
  String get whatsNewButton => 'Neuigkeiten';

  @override
  String get whatsNewTitle => 'Neuigkeiten';

  @override
  String get changelogBody =>
      '1.0.0\n• „Tagesrückblick“ auf dem Dashboard\n• Ruhezeiten für Benachrichtigungen\n• Home-Assistant-Integration\n• Material-3-Design';

  @override
  String get tooltipPlaySound => 'Ton abspielen';

  @override
  String get cameraGridLabel => 'Alle Kameras';

  @override
  String get widgetEmptyHint => 'Öffne PetTrack, um die Kamera zu laden';

  @override
  String get tooltipSnapshot => 'Snapshot aufnehmen';

  @override
  String get playSoundSent => 'Ton an den Monitor gesendet';

  @override
  String get tooltipTimelapse => 'Tages-Timelapse';

  @override
  String get tooltipRecap => 'Tages-Recap';

  @override
  String get recapBuilding => 'Der Tages-Recap wird erstellt…';

  @override
  String get recapEmpty => 'An diesem Tag keine Momente';

  @override
  String recapError(int code) {
    return 'Recap konnte nicht erstellt werden (Fehler $code)';
  }

  @override
  String get replayAllDays => 'Alle Tage';

  @override
  String get noReplaysForDay => 'An diesem Tag keine Aufnahmen';

  @override
  String get timelapseBuilding => 'Timelapse des Tages wird erstellt…';

  @override
  String get timelapseEmpty => 'Für diesen Tag nicht genug Bilder';

  @override
  String timelapseError(int code) {
    return 'Timelapse konnte nicht erstellt werden (Fehler $code)';
  }

  @override
  String get tooltipNightMode => 'Nachtmodus';

  @override
  String get nightModeOn => 'Nachtmodus aktiviert';

  @override
  String get nightModeOff => 'Nachtmodus deaktiviert';

  @override
  String get alertsSound => 'Geräuschalarme (Bellen / Miauen)';

  @override
  String get soundDetectedTitle => 'Geräusch erkannt';

  @override
  String get soundDetectedBody => 'Lautes Geräusch in der Nähe der Kamera.';

  @override
  String get demoZoneLitter => 'Katzentoilette';

  @override
  String get demoZonePlayground => 'Spielplatz';

  @override
  String get demoZoneFeeder => 'Futternapf';

  @override
  String get demoMedName => 'Verdauungshilfe';

  @override
  String get demoMedDose => '0,5 ml';

  @override
  String get demoVacName => 'Myxomatose-Impfung';

  @override
  String get activityLoadError => 'Aktivitäten konnten nicht geladen werden';

  @override
  String get zonesLoadError => 'Zonen konnten nicht geladen werden';

  @override
  String get cameraStartFailed => 'Die Kamera konnte nicht gestartet werden';

  @override
  String get videoLoadError => 'Das Video konnte nicht abgespielt werden';

  @override
  String get medicalCachedNotice =>
      'Server nicht erreichbar — gespeicherte Kopie wird angezeigt';

  @override
  String get tooltipPlayPause => 'Wiedergabe / Pause';

  @override
  String get settingsSaveError =>
      'Die Änderung konnte nicht gespeichert werden';

  @override
  String get shareFailed => 'Teilen nicht möglich';

  @override
  String get evidenceNoClip =>
      'Kein Clip in der Nähe dieses Moments aufgezeichnet';

  @override
  String get feedSearchHint => 'Ereignisse suchen';

  @override
  String get feedSearchClear => 'Löschen';

  @override
  String get feedFilterAll => 'Alle';

  @override
  String get feedFilterZones => 'Zonen';

  @override
  String get feedFilterSounds => 'Geräusche';

  @override
  String get feedFilterSystem => 'System';

  @override
  String get feedNoMatch => 'Keine passenden Ereignisse';

  @override
  String get feedExport => 'CSV exportieren';

  @override
  String get feedExportEmpty => 'Noch nichts zu exportieren.';

  @override
  String get feedExportFailed => 'Der Feed konnte nicht exportiert werden.';

  @override
  String recapBanner(String count) {
    return 'Letzte Nacht: $count Ereignisse';
  }

  @override
  String get recapDismiss => 'Alles klar';

  @override
  String get armingTitle => 'Überwachung';

  @override
  String get armingModeOn => 'Immer an';

  @override
  String get armingModeSchedule => 'Nach Zeitplan';

  @override
  String get armingModeOff => 'Aus';

  @override
  String get armingStatusArmed => 'Aktiv';

  @override
  String get armingStatusDisarmed => 'Inaktiv';

  @override
  String get armingAddWindow => 'Zeitfenster hinzufügen';

  @override
  String get armingRemoveWindow => 'Zeitfenster entfernen';

  @override
  String get armingFrom => 'Von';

  @override
  String get armingTo => 'Bis';

  @override
  String get armingDays => 'Tage';

  @override
  String get armingHelp =>
      'Aktiv zeichnet Bewegungen auf und löst Alarme aus; inaktiv speichert kein Material. Die Live-Ansicht funktioniert immer.';

  @override
  String get armingWindowRequired => 'Mindestens ein Zeitfenster hinzufügen';

  @override
  String get semanticCameraView => 'Kamerabild';

  @override
  String get semanticChangePhoto => 'Profilbild ändern';

  @override
  String get semanticZoneCanvas =>
      'Zonen-Editor — tippen, um einen Punkt zu setzen';

  @override
  String get semanticWakeMonitor => 'Doppeltippen, um den Monitor zu wecken';

  @override
  String get colorTeal => 'Türkis';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Lila';

  @override
  String get tooltipConfirm => 'Bestätigen';

  @override
  String get backupCardTitle => 'Backup & Wiederherstellung';

  @override
  String get backupHelp =>
      'Bewahre deine Einstellungen in einer Datei auf — stelle sie auf einem neuen Handy oder nach einer Neuinstallation wieder her. Die Datei enthält deinen Kopplungs-Secret; alle mit dieser Datei können auf deine Kameras zugreifen.';

  @override
  String get backupExport => 'Backup exportieren';

  @override
  String get backupRestore => 'Backup wiederherstellen';

  @override
  String get backupExportTitle => 'Backup exportieren?';

  @override
  String get backupExportBody =>
      'Die Backup-Datei enthält deinen Kopplungs-Secret. Teile sie nur mit dir selbst — alle mit dieser Datei können auf deine Kameras zugreifen.';

  @override
  String get backupRestoreTitle => 'Backup wiederherstellen?';

  @override
  String get backupRestoreBody =>
      'Damit werden die Einstellungen auf diesem Handy ersetzt und, wenn der Server erreichbar ist, auch die auf dem Server.';

  @override
  String get backupInvalid => 'Diese Datei ist kein PetTrack-Backup';

  @override
  String get backupRestored => 'Backup wiederhergestellt';

  @override
  String get backupRestoredOffline =>
      'Backup auf diesem Handy wiederhergestellt. Öffne die Einstellungen und speichere, um mit dem Server zu synchronisieren.';

  @override
  String get backupRestoreError =>
      'Das Backup konnte nicht wiederhergestellt werden';

  @override
  String get setupSkipMonitor => 'Erstmal überspringen';

  @override
  String get setupMissingFields => 'Gib Serveradresse und PIN ein';
}
