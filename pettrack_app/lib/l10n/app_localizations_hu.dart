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
}
