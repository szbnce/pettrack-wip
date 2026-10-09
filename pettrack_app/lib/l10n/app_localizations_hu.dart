// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => 'Beállítások';

  @override
  String get uploadProfilePicture => 'Profilkép feltöltése';

  @override
  String get serverIp => 'Szerver IP';

  @override
  String get serverIpHint => 'pl. 192.168.1.100';

  @override
  String get secretToken => 'Titkos Token';

  @override
  String get petName => 'Kedvenc neve';

  @override
  String get petNameHint => 'Írd be a nevét';

  @override
  String get save => 'Mentés';

  @override
  String get navDashboard => 'Kezdőlap';

  @override
  String get navZones => 'Zónák';

  @override
  String get navSettings => 'Beállítások';

  @override
  String get liveVideo => 'Élő Videó';

  @override
  String get activities => 'Tevékenységek';

  @override
  String get noRecentEvents => 'Nincs friss esemény';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petName belépett a(z) $zone területre';
  }

  @override
  String get zoneVisits => 'Zónalátogatások';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petName kilépett a(z) $zone területről';
  }

  @override
  String get cameraDetectedMovement => 'Kamera érzékelte a mozgást.';

  @override
  String get editZones => 'Zónák Szerkesztése';

  @override
  String get addNewZone => 'Új zóna hozzáadása';

  @override
  String get cancel => 'Mégse';

  @override
  String get existingZones => 'Meglévő zónák';

  @override
  String get safeZone => 'Biztonságos zóna';

  @override
  String get today => 'Ma';

  @override
  String get language => 'Nyelv';

  @override
  String get lastUpdated => 'Utoljára frissítve';

  @override
  String get justNow => 'Épp most';

  @override
  String minsAgo(int mins) {
    return '$mins perce';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours órája';
  }

  @override
  String daysAgo(int days) {
    return '$days napja';
  }

  @override
  String get unknown => 'Ismeretlen';

  @override
  String get leftTheZone => 'Elhagyta a zónát.';

  @override
  String get greetingsList =>
      'Szia Gazda!|Üdv újra!|Szép napot!|Hali!|Hogy s mint?|Helló!|Mizu?|Jó újra látni!|Készen állsz?|Nézzük, mit csinál!';

  @override
  String get subGreetingsList =>
      'Itt minden rendben.|Úgy tűnik, alszik.|Tele van energiával!|Figyeli a terepet.|Várja a vacsorát.|Szimatol valamit.|Békésen pihen.|A kedvenc helyén van.|Játszani szeretne.|Minden csendes.';

  @override
  String get petTypeTitle => 'Állat fajtája';

  @override
  String get petTypeDog => 'Kutya';

  @override
  String get petTypeCat => 'Macska';

  @override
  String get petTypeRabbit => 'Nyúl';

  @override
  String get petTypeGuineaPig => 'Tengerimalac';

  @override
  String get petTypeBird => 'Madár';

  @override
  String get petTypeOther => 'Egyéb';

  @override
  String get alertsTitle => 'Értesítések';

  @override
  String get alertsZone => 'Zóna riasztások (Ki/Be lépés)';

  @override
  String get alertsBattery => 'Alacsony akkumlátor riasztás';

  @override
  String batteryThreshold(int level) {
    return 'Akkumlátor határ: $level%';
  }

  @override
  String get testNotification => 'Értesítés tesztelése';

  @override
  String get testNotifTitle => 'Teszt értesítés';

  @override
  String get testNotifBody => 'Sikeresen beállítottad az értesítéseket!';

  @override
  String get alertsRemoteTitle => 'Riasztások, amikor távol vagyok';

  @override
  String get alertsRemoteDesc =>
      'Továbbítja a riasztásokat egy ntfy témára, hogy bárhova elérjenek — az ntfy appban vagy akár böngészőben. Válassz nehezen kitalálható témanevet; a link birtokában bárki feliratkozhat.';

  @override
  String get alertsRemoteUrlLabel => 'ntfy téma URL';

  @override
  String get alertsRemoteUrlHint => 'https://ntfy.sh/a-titkos-temad';

  @override
  String get alertsRemoteTokenLabel => 'Hozzáférési token (opcionális)';

  @override
  String get alertsRemoteTest => 'Teszt értesítés küldése';

  @override
  String get alertsRemoteTestSent =>
      'Teszt értesítés elküldve — nézd meg a telefonod.';

  @override
  String get alertsRemoteTestFailed =>
      'A teszt értesítést nem sikerült elküldeni. Ellenőrizd a téma URL-t és a szervert.';

  @override
  String get alertsRemoteUrlInvalid => 'Ez nem tűnik érvényes ntfy URL-nek.';

  @override
  String secondsAgo(int seconds) {
    return '$seconds másodperce';
  }

  @override
  String get toiletZone => 'Alomtálca / WC';

  @override
  String get bedZone => 'Fekvőhely';

  @override
  String get waterZone => 'Itató';

  @override
  String get foodZone => 'Etető';

  @override
  String get playZone => 'Játszótér';

  @override
  String get appearance => 'Megjelenés (Téma)';

  @override
  String get themeSystem => 'Rendszer alapértelmezett';

  @override
  String get themeLight => 'Világos mód';

  @override
  String get themeDark => 'Sötét mód';

  @override
  String failedToLoadPetProfile(String e) {
    return 'Nem sikerült betölteni a profilt: $e';
  }

  @override
  String get invalidSecretToken => 'Hibás Secret Token!';

  @override
  String decodingError(String e) {
    return 'Dekódolási hiba: $e';
  }

  @override
  String get setupWelcomeTitle => 'Üdvözöl a PetTrack!';

  @override
  String get setupWelcomeDesc =>
      'A legbiztonságosabb kisállatfigyelő\n\nElső lépésként olvasd be a szerver QR kódját!';

  @override
  String get setupScanBtn => 'QR kód beolvasása';

  @override
  String get setupSuccessTitle => 'Sikeres csatlakozás!';

  @override
  String get setupSuccessDesc =>
      'A kapcsolat titkosítva.\nMost adjuk meg a kedvenced adatait.';

  @override
  String get setupNextBtn => 'Tovább';

  @override
  String get setupErrConnect =>
      'Hiba a szerverhez csatlakozáskor! Ellenőrizd a hálózatot.';

  @override
  String get setupErrSave => 'Hiba a profil mentésekor!';

  @override
  String get setupErrEmpty => 'Adj meg egy nevet!';

  @override
  String get setupMonitorTitle => 'Kamera beállítása';

  @override
  String get setupMonitorDesc =>
      'Nyisd meg a Monitor appot a régi telefonodon, és olvasd be ezt a QR kódot a csatlakozáshoz!';

  @override
  String get settingsShowQrBtn => 'QR kód megjelenítése';

  @override
  String get settingsQrDialogDesc => 'Olvasd be a régi telefonnal:';

  @override
  String get settingsQrDialogDone => 'Kész';

  @override
  String get settingsResetApp => 'App alaphelyzetbe állítása';

  @override
  String get settingsResetConfirmTitle => 'Biztos vagy benne?';

  @override
  String get settingsResetConfirmDesc =>
      'Ez minden adatot töröl és újraindítja a beállítási varázslót.';

  @override
  String get serverUnreachableTitle => 'Szerver nem elérhető';

  @override
  String get serverUnreachableDesc =>
      'Nem sikerült csatlakozni a PetTrack szerverhez.\nKérlek ellenőrizd a hálózatot, hogy fut-e a szerver.';

  @override
  String get profileAndSystem => 'Profil & Rendszer';

  @override
  String get monitorAndConnection => 'Monitor & Kapcsolat';

  @override
  String get offlineStatus => 'OFFLINE!';

  @override
  String get liveStatus => 'Élő';

  @override
  String get searchingStatus => 'Keresés...';

  @override
  String get navMedical => 'Egészségügy';

  @override
  String get medications => 'Gyógyszerek';

  @override
  String get vaccines => 'Oltások';

  @override
  String get addMedication => 'Gyógyszer felvétele';

  @override
  String get addVaccine => 'Oltás felvétele';

  @override
  String get dose => 'Dózis';

  @override
  String get time => 'Időpont';

  @override
  String get dateGiven => 'Beadás dátuma';

  @override
  String get nextDue => 'Következő esedékes';

  @override
  String get enableAlert => 'Riasztás bekapcsolása';

  @override
  String get medName => 'Gyógyszer neve';

  @override
  String get vacName => 'Oltás neve';

  @override
  String get noMedications => 'Még nincs gyógyszer rögzítve.';

  @override
  String get noVaccines => 'Még nincs oltás rögzítve.';

  @override
  String get saveMedication => 'Gyógyszer mentése';

  @override
  String get saveVaccine => 'Oltás mentése';

  @override
  String get cardColor => 'Kártya színe:';

  @override
  String get alertFrequency => 'Értesítés gyakorisága (órában)';

  @override
  String get alertFrequencyHint => 'pl. 12 vagy 24';

  @override
  String get medTimeTitle => 'Gyógyszer idő!';

  @override
  String medTimeBody(String name, String dose) {
    return 'Ideje beadni: $name ($dose)';
  }

  @override
  String everyXHours(int hours) {
    return 'Minden $hours órában';
  }

  @override
  String get setupTitle => 'PetTrack Monitor Beállítás';

  @override
  String get monitorTitle => 'PetTrack Monitor';

  @override
  String get monitorSleepMode => 'Alvó mód (Képernyő sötétítése)';

  @override
  String get aboutTitle => 'Névjegy';

  @override
  String get aboutDescription =>
      'Ez az alkalmazás közvetíti a kameraképet a PetTrack Serverre.';

  @override
  String get monitorStreamingLive => 'Élő közvetítés folyamatban...';

  @override
  String get monitorWaitingForStart => 'Várakozás a START parancsra...';

  @override
  String get monitorReconnecting => 'Újracsatlakozás...';

  @override
  String get start => 'Indítás';

  @override
  String get stop => 'Leállítás';

  @override
  String monitorServer(String ip) {
    return 'Szerver:\n$ip';
  }

  @override
  String get monitorSleeping => 'Alvó mód.... Dupla koppintás az ébresztéshez';

  @override
  String errorConnectionFailed(String error) {
    return 'Sikertelen csatlakozás a szerverhez! Ellenőrizd az IP-t és a Tokent.\nHiba: $error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => 'Olvasd be a QR kódot a PetTrack appból';

  @override
  String get lightMode => '☀️ Világos mód';

  @override
  String get darkMode => '🌙 Sötét mód';

  @override
  String get welcomeTitle => 'Üdvözöl a PetTrack';

  @override
  String get chooseMode => 'Válassz módot';

  @override
  String get modeClient => 'Kliens (Figyelő)';

  @override
  String get modeClientDesc => 'Ezen az eszközön nézheted a kamerát.';

  @override
  String get modeMonitor => 'Monitor (Kamera)';

  @override
  String get modeMonitorDesc => 'Ez az eszköz fogja közvetíteni a képet.';

  @override
  String get enterPin => 'PIN kód megadása';

  @override
  String get demoModeTitle => 'Demo Mód';

  @override
  String get demoModePrompt => 'Szeretnél belépni a Demo módba?';

  @override
  String get exit => 'Kilépés';

  @override
  String get demoLivePreview => 'DEMO MÓD, ÉLŐKÉP HELYE!';

  @override
  String get zoneSaved => 'Zóna elmentve!';

  @override
  String zoneSaveError(String e) {
    return 'Hiba: $e';
  }

  @override
  String get newZoneTitle => 'Új zóna felvétele';

  @override
  String get zoneNameHint => 'Zóna neve...';

  @override
  String get noZonesYet => 'Nincsenek még zónák.';

  @override
  String get yes => 'Igen';

  @override
  String get no => 'Nem';

  @override
  String get submitPin => 'PIN küldése';

  @override
  String get demoModeBtn => 'Demó mód';

  @override
  String get demoNoPlayback => 'Demó mód — a videólejátszás nem elérhető';

  @override
  String get insightsTitle => 'Aktivitási elemzés';

  @override
  String get insightsEntrySubtitle =>
      'Tevékenység, zónák és pihenés egy pillantásra';

  @override
  String insightsRangeDays(int n) {
    return '$n nap';
  }

  @override
  String get insightsActiveToday => 'Mai aktivitás';

  @override
  String get insightsAvgPerDay => 'Naponta (átlag)';

  @override
  String get insightsMostActiveZone => 'Legaktívabb zóna';

  @override
  String get insightsActivityChart => 'Aktív percek naponta';

  @override
  String get insightsZoneChart => 'Zónánkénti idő';

  @override
  String get insightsZoneEmpty =>
      'Ebben az időszakban nincs zónában töltött idő';

  @override
  String get insightsActiveVsRest => 'Aktivitás vs. pihenés (átlagos nap)';

  @override
  String get insightsWordActive => 'Aktív';

  @override
  String get insightsWordRest => 'Pihenés';

  @override
  String get insightsTableDay => 'Nap';

  @override
  String get tooltipInsightsList => 'Megjelenítés táblázatként';

  @override
  String get tooltipInsightsChart => 'Megjelenítés grafikonként';

  @override
  String insightsDurationH(int n) {
    return '$n ó';
  }

  @override
  String insightsDurationHm(int hours, int minutes) {
    return '$hours ó $minutes perc';
  }

  @override
  String insightsDurationM(int minutes) {
    return '$minutes perc';
  }

  @override
  String insightsDurationS(int seconds) {
    return '$seconds mp';
  }

  @override
  String insightsClips(int n) {
    return '$n mozgásfelvétel';
  }

  @override
  String insightsSounds(int n) {
    return '$n hangesemény';
  }

  @override
  String get insightsLoadError => 'Nem sikerült betölteni az elemzést';

  @override
  String get demoZoneKitchen => 'Konyha';

  @override
  String get demoZoneSofa => 'Kanapé';

  @override
  String get demoZoneBed => 'Ágy';

  @override
  String get demoZoneGarden => 'Kert';

  @override
  String get healthCardTitle => 'Rendszerállapot';

  @override
  String get healthCameraOnline => 'Kamera online';

  @override
  String get healthCameraOffline => 'Kamera offline';

  @override
  String healthLastSeen(String duration) {
    return 'Utoljára látva: $duration';
  }

  @override
  String healthDiskFreeOf(String free, String total) {
    return '$free szabad / $total';
  }

  @override
  String get healthDiskLow =>
      'Kevés a lemezterület — a régi visszajátszások törölve lesznek';

  @override
  String healthReplaysStored(int count, String size) {
    return '$count visszajátszás · $size';
  }

  @override
  String get healthKeepReplays => 'Visszajátszások megőrzése';

  @override
  String get healthRetentionSaved => 'Megőrzési idő frissítve';

  @override
  String get healthLoadError => 'A rendszerállapot nem tölthető be';

  @override
  String get cameraOfflineTitle => 'Kamera offline';

  @override
  String get cameraOfflineBody => '10 perce nincs videó a kameráról';

  @override
  String get diskLowTitle => 'Kevés a lemezterület';

  @override
  String get diskLowBody =>
      'A régi visszajátszások törlésre kerülnek, hogy hely szabaduljon fel';

  @override
  String get settingsSignOut => 'Kijelentkezés';

  @override
  String get settingsSignOutTitle => 'Kijelentkezés erről a szerverről?';

  @override
  String get settingsSignOutMessage =>
      'Ez az eszköz elfelejti a tokenjeit, és a munkamenet a szerveren visszavonásra kerül. A párosító PIN-kóddal újra bejelentkezhetsz.';

  @override
  String get orSeparator => 'VAGY';

  @override
  String get setupErrPin => 'Sikertelen csatlakozás vagy hibás PIN!';

  @override
  String get saveSuccess => 'Beállítások elmentve!';

  @override
  String get navReplays => 'Visszajátszások';

  @override
  String get replaysTitle => 'Visszajátszások';

  @override
  String get logOut => 'Kijelentkezés';

  @override
  String replaysLoadError(int code) {
    return 'Nem sikerült betölteni a visszajátszásokat (Hiba $code)';
  }

  @override
  String replaysNetworkError(String e) {
    return 'Hálózati hiba: $e';
  }

  @override
  String get close => 'Bezárás';

  @override
  String get openDownload => 'Megnyitás / Letöltés';

  @override
  String get retry => 'Újra';

  @override
  String get noReplays => 'Még nincsenek visszajátszások.';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => 'QR kód beolvasása';

  @override
  String get qrScannerHint => 'Olvassa be a terminálban lévő QR kódot!';

  @override
  String get notifChannelAlertsName => 'PetTrack Riasztások';

  @override
  String get notifChannelAlertsDesc =>
      'Értesítések zónaváltásról és akkumulátorról';

  @override
  String get notifChannelMedicalName => 'Gyógyszer emlékeztetők';

  @override
  String get notifChannelMedicalDesc => 'Értesítések a gyógyszerek beadásáról';

  @override
  String get syncToWatch => 'Szinkronizálás Okosórával';

  @override
  String get syncStarting => 'Szinkronizálás indítása...';

  @override
  String get syncSuccess => 'Sikeresen elküldve az órára!';

  @override
  String get syncNoWatch => 'Nem található csatlakoztatott óra.';

  @override
  String get onlineStatus => 'Online';

  @override
  String get eventLog => 'Eseménynapló';

  @override
  String get shareInviteText => 'Nézd, mit csinál a kedvencem!';

  @override
  String get chooseLanguageTitle => 'Válassz nyelvet';

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
  String get aiGeneratedMarker => '(AI-GENERÁLT)';

  @override
  String get wearSynced => 'Szinkronizálva!';

  @override
  String get wearOpenAppOnPhone => 'Nyisd meg az appot a telefonon.';

  @override
  String get wearManual => 'Manuális';

  @override
  String get wearSetupTitle => 'Beállítás';

  @override
  String get pinHint => '4-jegyű PIN';

  @override
  String get errInvalidPin => 'Hibás PIN!';

  @override
  String get errNetwork => 'Hálózati hiba!';

  @override
  String get defaultPetName => 'Kedvenc';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => 'Szerver keresése a hálózaton';

  @override
  String get discoveryTitle => 'Szerverek a hálózaton';

  @override
  String get discoverySearching => 'Keresés a helyi hálózaton…';

  @override
  String get discoveryEmpty => 'Még nem találtam PetTrack szervert.';

  @override
  String get discoveryHint =>
      'Győződj meg róla, hogy a szerver fut, és ugyanazon a Wi-Fi-n vagy.';

  @override
  String get discoveryNotSupported =>
      'Az automatikus keresés ezen az eszközön nem elérhető. Írd be a szerver címét kézzel.';

  @override
  String get discoveryTapToUse => 'Koppints a csatlakozáshoz';

  @override
  String get tooltipRefresh => 'Frissítés';

  @override
  String get tooltipAdd => 'Hozzáadás';

  @override
  String get tooltipDelete => 'Törlés';

  @override
  String get highlightTitle => 'Mai összefoglaló';

  @override
  String get highlightSubtitle => 'A mai összes pillanat egyetlen klipben';

  @override
  String highlightMoments(Object count) {
    return '$count pillanat';
  }

  @override
  String get tooltipShare => 'Megosztás';

  @override
  String get quietHoursTitle => 'Csendes órák';

  @override
  String get quietHoursSubtitle =>
      'Ebben az időben nincs zóna- vagy akkumulátor-riasztás';

  @override
  String get quietHoursFrom => 'Ettől';

  @override
  String get quietHoursTo => 'Eddig';

  @override
  String get snoozeTitle => 'Riasztások némítása';

  @override
  String get snoozeChip => 'Némítás';

  @override
  String get snoozeChipActive => 'Némítva';

  @override
  String get snooze30m => '30 percre';

  @override
  String get snooze1h => 'Egy órára';

  @override
  String get snoozeTonight => '23:00-ig';

  @override
  String get snoozeEnd => 'Némítás vége';

  @override
  String snoozeActive(String time) {
    return 'A riasztások némítva ezen a telefonon eddig: $time';
  }

  @override
  String get snoozeEnded => 'A riasztások újra szólnak ezen a telefonon.';

  @override
  String get batteryLowTitle => 'Alacsony akkumulátor';

  @override
  String batteryLowBody(int level) {
    return 'Akkumulátor: $level%';
  }

  @override
  String get aboutCardTitle => 'Névjegy és frissítések';

  @override
  String get versionAppLabel => 'App';

  @override
  String get versionServerLabel => 'Szerver';

  @override
  String get versionCheckButton => 'Ellenőrzés most';

  @override
  String get versionUnknown => 'Nincs kapcsolat';

  @override
  String get versionMatch => 'Az app és a szerver szinkronban van';

  @override
  String get versionAppOlder => 'A szerver újabb — frissítsd az appot';

  @override
  String get versionServerOlder => 'Az app újabb — frissítsd a szervert';

  @override
  String updateAvailable(String version) {
    return '$version verzió telepíthető';
  }

  @override
  String get updateInstallButton => 'Frissítés telepítése';

  @override
  String get updateDownloading => 'Letöltés…';

  @override
  String get updateDownloadFailed =>
      'A frissítés letöltése nem sikerült. Ellenőrizd a szervert, és próbáld újra.';

  @override
  String get updateInstallFailed => 'Az Android telepítő nem nyílt meg.';

  @override
  String get privacyButton => 'Adatvédelem';

  @override
  String get privacyTitle => 'Adatvédelem';

  @override
  String get privacyBody =>
      'A PetTrack teljesen saját üzemeltetésű — a kamera képe, a felvételek és a kedvenc adatai a te szervereden maradnak.\n\n• Nincs felhő, semmi nem megy sehova\n• Nincs fiók — nincs szolgáltatás, ahová regisztrálni kellene\n• Nincs analitika vagy követés\n• Alapból csak helyi hálózat; a távoli elérés csak az, amit te állítasz be';

  @override
  String get whatsNewButton => 'Újdonságok';

  @override
  String get whatsNewTitle => 'Újdonságok';

  @override
  String get changelogBody =>
      '1.0.0\n• „Mai összefoglaló” a kezdőképernyőn\n• Csendes órák a riasztásokhoz\n• Home Assistant integráció\n• Material 3 arculat';

  @override
  String get tooltipPlaySound => 'Hang lejátszása';

  @override
  String get cameraGridLabel => 'Összes kamera';

  @override
  String get widgetEmptyHint => 'Nyisd meg a PetTracket a kamera betöltéséhez';

  @override
  String get tooltipSnapshot => 'Pillanatkép készítése';

  @override
  String get playSoundSent => 'Hang elküldve a monitorra';

  @override
  String get tooltipTimelapse => 'Napi timelapse';

  @override
  String get tooltipRecap => 'Napi összefoglaló';

  @override
  String get recapBuilding => 'A nap összefoglalója készül…';

  @override
  String get recapEmpty => 'Erre a napra nincsenek pillanatok';

  @override
  String recapError(int code) {
    return 'Az összefoglaló nem készült el ($code hiba)';
  }

  @override
  String get replayAllDays => 'Összes nap';

  @override
  String get noReplaysForDay => 'Erre a napra nincsenek felvételek';

  @override
  String get timelapseBuilding => 'A nap timelapse-ének építése…';

  @override
  String get timelapseEmpty => 'Erre a napra nincs elég képkocka';

  @override
  String timelapseError(int code) {
    return 'A timelapse elkészítése nem sikerült ($code hiba)';
  }

  @override
  String get tooltipNightMode => 'Éjszakai mód';

  @override
  String get nightModeOn => 'Éjszakai mód bekapcsolva';

  @override
  String get nightModeOff => 'Éjszakai mód kikapcsolva';

  @override
  String get alertsSound => 'Hangjelzések (ugatás / nyávogás)';

  @override
  String get soundDetectedTitle => 'Hang észlelve';

  @override
  String get soundDetectedBody => 'Hangos zaj a kamera közelében.';

  @override
  String get demoZoneLitter => 'Alomtálca';

  @override
  String get demoZonePlayground => 'Játszótér';

  @override
  String get demoZoneFeeder => 'Etető';

  @override
  String get demoMedName => 'Emésztéskönnyítő';

  @override
  String get demoMedDose => '0,5 ml';

  @override
  String get demoVacName => 'Myxomatosis elleni védőoltás';

  @override
  String get activityLoadError => 'A tevékenységek betöltése nem sikerült';

  @override
  String get zonesLoadError => 'A zónák betöltése nem sikerült';

  @override
  String get cameraStartFailed => 'A kamera indítása nem sikerült';

  @override
  String get videoLoadError => 'A videó lejátszása nem sikerült';

  @override
  String get medicalCachedNotice =>
      'A szerver nem elérhető — a mentett másolat látható';

  @override
  String get tooltipPlayPause => 'Lejátszás / szünet';

  @override
  String get settingsSaveError => 'A módosítás mentése nem sikerült';

  @override
  String get shareFailed => 'A megosztás nem sikerült';

  @override
  String get evidenceNoClip => 'Nincs felvétel ehhez a pillanathoz';

  @override
  String get feedSearchHint => 'Események keresése';

  @override
  String get feedSearchClear => 'Törlés';

  @override
  String get feedFilterAll => 'Összes';

  @override
  String get feedFilterZones => 'Zónák';

  @override
  String get feedFilterSounds => 'Hangok';

  @override
  String get feedFilterSystem => 'Rendszer';

  @override
  String get feedNoMatch => 'Nincs találat';

  @override
  String get armingTitle => 'Megfigyelés';

  @override
  String get armingModeOn => 'Mindig bekapcsolva';

  @override
  String get armingModeSchedule => 'Időzítés szerint';

  @override
  String get armingModeOff => 'Kikapcsolva';

  @override
  String get armingStatusArmed => 'Élesítve';

  @override
  String get armingStatusDisarmed => 'Szünetel';

  @override
  String get armingAddWindow => 'Időablak hozzáadása';

  @override
  String get armingRemoveWindow => 'Időablak törlése';

  @override
  String get armingFrom => 'Kezdete';

  @override
  String get armingTo => 'Vége';

  @override
  String get armingDays => 'Napok';

  @override
  String get armingHelp =>
      'Élesítve rögzül a mozgás és riasztás érkezik; szüneteléskor nem készül felvétel. Az élő kép mindig működik.';

  @override
  String get armingWindowRequired => 'Legalább egy időablak szükséges';

  @override
  String get semanticCameraView => 'Kamerakép';

  @override
  String get semanticChangePhoto => 'Profilkép módosítása';

  @override
  String get semanticZoneCanvas =>
      'Zónaszerkesztés — koppintás pont elhelyezéséhez';

  @override
  String get semanticWakeMonitor => 'Dupla koppintás a monitor ébresztéséhez';

  @override
  String get colorTeal => 'Türkiz';

  @override
  String get colorRed => 'Piros';

  @override
  String get colorBlue => 'Kék';

  @override
  String get colorOrange => 'Narancs';

  @override
  String get colorPurple => 'Lila';

  @override
  String get tooltipConfirm => 'Megerősítés';

  @override
  String get backupCardTitle => 'Backup és visszaállítás';

  @override
  String get backupHelp =>
      'Mentsd a beállításaidat egy fájlba — állítsd vissza új telefont vagy újratelepítés után. A fájl a párosítási titkot is tartalmazza, bárki elérheti vele a kameráidat.';

  @override
  String get backupExport => 'Backup mentése';

  @override
  String get backupRestore => 'Visszaállítás backupból';

  @override
  String get backupExportTitle => 'Mentjük a backupot?';

  @override
  String get backupExportBody =>
      'A backup fájl a párosítási titkot is tartalmazza. Csak magaddal oszd meg — bárki, akié ez a fájl, eléri a kameráidat.';

  @override
  String get backupRestoreTitle => 'Visszaállítjuk a backupot?';

  @override
  String get backupRestoreBody =>
      'Ez lecseréli a telefon beállításait, és ha a szerver elérhető, a szerveren lévőket is.';

  @override
  String get backupInvalid => 'Ez a fájl nem PetTrack backup';

  @override
  String get backupRestored => 'Backup visszaállítva';

  @override
  String get backupRestoredOffline =>
      'A backup visszaállítva ezen a telefonon. Nyisd meg a Beállításokat és mentsd, hogy szinkronizálj a szerverrel.';

  @override
  String get backupRestoreError => 'A backupot nem sikerült visszaállítani';

  @override
  String get setupSkipMonitor => 'Most kihagyom';

  @override
  String get setupMissingFields => 'Add meg a szerver címét és a PIN-kódot';
}
