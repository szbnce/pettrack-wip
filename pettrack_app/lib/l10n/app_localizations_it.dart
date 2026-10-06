// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get uploadProfilePicture => 'Carica immagine del profilo';

  @override
  String get serverIp => 'IP del server';

  @override
  String get serverIpHint => 'es. 192.168.1.100';

  @override
  String get secretToken => 'Token segreto';

  @override
  String get petName => 'Nome dell\'animale';

  @override
  String get petNameHint => 'Inserisci il nome';

  @override
  String get save => 'Salva';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navZones => 'Zone';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get liveVideo => 'Video dal vivo';

  @override
  String get activities => 'Attività';

  @override
  String get noRecentEvents => 'Nessun evento recente';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petName è entrato in $zone';
  }

  @override
  String get zoneVisits => 'Visite alle zone';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petName ha lasciato $zone';
  }

  @override
  String get cameraDetectedMovement =>
      'La telecamera ha rilevato un movimento.';

  @override
  String get editZones => 'Modifica zone';

  @override
  String get addNewZone => 'Aggiungi nuova zona';

  @override
  String get cancel => 'Annulla';

  @override
  String get existingZones => 'Zone esistenti';

  @override
  String get safeZone => 'Zona sicura';

  @override
  String get today => 'Oggi';

  @override
  String get language => 'Lingua';

  @override
  String get lastUpdated => 'Ultimo aggiornamento';

  @override
  String get justNow => 'Proprio ora';

  @override
  String minsAgo(int mins) {
    return '$mins min fa';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours ore fa';
  }

  @override
  String daysAgo(int days) {
    return '$days giorni fa';
  }

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get leftTheZone => 'Ha lasciato la zona.';

  @override
  String get greetingsList =>
      'Ciao capo!|Bentornato!|Buona giornata!|Ehi!|Come stai?|Ciao!|Che succede?|Felice di rivederti!|Pronti?|Vediamo cosa sta facendo!';

  @override
  String get subGreetingsList =>
      'Qui va tutto bene.|Sembra che stia dormendo.|Pieno di energia!|Sta sorvegliando la zona.|Aspetta la cena.|Sta annusando qualcosa.|Sta riposando tranquillo.|Nel posto preferito.|Vuole giocare.|Tutto tranquillo.';

  @override
  String get petTypeTitle => 'Tipo di animale';

  @override
  String get petTypeDog => 'Cane';

  @override
  String get petTypeCat => 'Gatto';

  @override
  String get petTypeRabbit => 'Coniglio';

  @override
  String get petTypeGuineaPig => 'Cavia';

  @override
  String get petTypeBird => 'Uccello';

  @override
  String get petTypeOther => 'Altro';

  @override
  String get alertsTitle => 'Notifiche';

  @override
  String get alertsZone => 'Avvisi di zona (Ingresso/Uscita)';

  @override
  String get alertsBattery => 'Avviso batteria scarica';

  @override
  String batteryThreshold(int level) {
    return 'Soglia batteria: $level%';
  }

  @override
  String get testNotification => 'Notifica di prova';

  @override
  String get testNotifTitle => 'Notifica di prova';

  @override
  String get testNotifBody =>
      'Le notifiche sono state configurate con successo!';

  @override
  String secondsAgo(int seconds) {
    return '$seconds secondi fa';
  }

  @override
  String get toiletZone => 'Lettiera / WC';

  @override
  String get bedZone => 'Zona riposo / sonno';

  @override
  String get waterZone => 'Ciotola dell\'acqua';

  @override
  String get foodZone => 'Ciotola del cibo';

  @override
  String get playZone => 'Zona gioco';

  @override
  String get appearance => 'Aspetto (Tema)';

  @override
  String get themeSystem => 'Predefinito di sistema';

  @override
  String get themeLight => 'Modalità chiara';

  @override
  String get themeDark => 'Modalità scura';

  @override
  String failedToLoadPetProfile(String e) {
    return 'Impossibile caricare il profilo dell\'animale: $e';
  }

  @override
  String get invalidSecretToken => 'Token segreto non valido!';

  @override
  String decodingError(String e) {
    return 'Errore di decodifica: $e';
  }

  @override
  String get setupWelcomeTitle => 'Benvenuto in PetTrack!';

  @override
  String get setupWelcomeDesc =>
      'Il modo migliore per tenere d\'occhio il tuo animale.\n\nPrima di tutto, connettiamoci al server.';

  @override
  String get setupScanBtn => 'Leggi codice QR';

  @override
  String get setupSuccessTitle => 'Fatto!';

  @override
  String get setupSuccessDesc =>
      'La connessione è cifrata.\nOra registriamo il tuo animale.';

  @override
  String get setupNextBtn => 'Passo successivo';

  @override
  String get setupErrConnect =>
      'Connessione al server non riuscita! Controlla la rete.';

  @override
  String get setupErrSave => 'Impossibile salvare il profilo.';

  @override
  String get setupErrEmpty => 'Inserisci un nome!';

  @override
  String get setupMonitorTitle => 'Configurazione monitor';

  @override
  String get setupMonitorDesc =>
      'Apri l\'app Monitor sull\'altro telefono e scansiona questo codice QR per connetterti!';

  @override
  String get settingsShowQrBtn => 'Mostra codice QR';

  @override
  String get settingsQrDialogDesc => 'Scansiona con il vecchio telefono:';

  @override
  String get settingsQrDialogDone => 'Fatto';

  @override
  String get settingsResetApp => 'Reimposta app e riavvia configurazione';

  @override
  String get settingsResetConfirmTitle => 'Sei sicuro?';

  @override
  String get settingsResetConfirmDesc =>
      'Questo eliminerà tutti i dati salvati e riavvierà la procedura di configurazione.';

  @override
  String get serverUnreachableTitle => 'Server non raggiungibile';

  @override
  String get serverUnreachableDesc =>
      'Impossibile connettersi al server PetTrack.\nControlla la rete o se il server è in esecuzione.';

  @override
  String get profileAndSystem => 'Profilo e sistema';

  @override
  String get monitorAndConnection => 'Monitor e connessione';

  @override
  String get offlineStatus => 'OFFLINE!';

  @override
  String get liveStatus => 'Dal vivo';

  @override
  String get searchingStatus => 'Ricerca...';

  @override
  String get navMedical => 'Salute';

  @override
  String get medications => 'Farmaci';

  @override
  String get vaccines => 'Vaccini';

  @override
  String get addMedication => 'Aggiungi farmaco';

  @override
  String get addVaccine => 'Aggiungi vaccino';

  @override
  String get dose => 'Dose';

  @override
  String get time => 'Ora';

  @override
  String get dateGiven => 'Data di somministrazione';

  @override
  String get nextDue => 'Prossima scadenza';

  @override
  String get enableAlert => 'Abilita avviso';

  @override
  String get medName => 'Nome del farmaco';

  @override
  String get vacName => 'Nome del vaccino';

  @override
  String get noMedications => 'Nessun farmaco aggiunto.';

  @override
  String get noVaccines => 'Nessun vaccino aggiunto.';

  @override
  String get saveMedication => 'Salva farmaco';

  @override
  String get saveVaccine => 'Salva vaccino';

  @override
  String get cardColor => 'Colore scheda:';

  @override
  String get alertFrequency => 'Frequenza avvisi (in ore)';

  @override
  String get alertFrequencyHint => 'es. 12 o 24';

  @override
  String get medTimeTitle => 'Ora del farmaco!';

  @override
  String medTimeBody(String name, String dose) {
    return 'Ora di somministrare: $name ($dose)';
  }

  @override
  String everyXHours(int hours) {
    return 'Ogni $hours ore';
  }

  @override
  String get setupTitle => 'Configurazione PetTrack Monitor';

  @override
  String get monitorTitle => 'PetTrack Monitor';

  @override
  String get monitorSleepMode => 'Modalità riposo (scurisci schermo)';

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutDescription =>
      'Questa app trasmette in modo sicuro il video della telecamera al backend PetTrack.';

  @override
  String get monitorStreamingLive => 'Trasmissione video dal vivo...';

  @override
  String get monitorWaitingForStart => 'In attesa del comando START...';

  @override
  String get monitorReconnecting => 'Riconnessione...';

  @override
  String get start => 'Avvia';

  @override
  String get stop => 'Ferma';

  @override
  String monitorServer(String ip) {
    return 'Server:\n$ip';
  }

  @override
  String get monitorSleeping => 'In riposo... Tocca due volte per svegliare';

  @override
  String errorConnectionFailed(String error) {
    return 'Connessione al server non riuscita! Controlla IP e token.\nErrore: $error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => 'Scansiona il codice QR dell\'app PetTrack';

  @override
  String get lightMode => '☀️ Modalità chiara';

  @override
  String get darkMode => '🌙 Modalità scura';

  @override
  String get welcomeTitle => 'Benvenuto in PetTrack';

  @override
  String get chooseMode => 'Scegli la modalità';

  @override
  String get modeClient => 'Client (Visualizzatore)';

  @override
  String get modeClientDesc => 'Questo dispositivo guarderà lo streaming.';

  @override
  String get modeMonitor => 'Monitor (Telecamera)';

  @override
  String get modeMonitorDesc => 'Questo dispositivo trasmetterà il video.';

  @override
  String get enterPin => 'Inserisci PIN';

  @override
  String get demoModeTitle => 'Modalità demo';

  @override
  String get demoModePrompt => 'Vuoi entrare nella modalità demo?';

  @override
  String get exit => 'Esci';

  @override
  String get demoLivePreview => 'MODALITÀ DEMO, ANTEPRIMA DAL VIVO QUI!';

  @override
  String get zoneSaved => 'Zona salvata!';

  @override
  String zoneSaveError(String e) {
    return 'Errore: $e';
  }

  @override
  String get newZoneTitle => 'Aggiunta di una nuova zona';

  @override
  String get zoneNameHint => 'Nome della zona...';

  @override
  String get noZonesYet => 'Nessuna zona ancora.';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get submitPin => 'Invia PIN';

  @override
  String get demoModeBtn => 'Modalità demo';

  @override
  String get orSeparator => 'OPPURE';

  @override
  String get setupErrPin => 'Connessione non riuscita o PIN non valido!';

  @override
  String get saveSuccess => 'Impostazioni salvate!';

  @override
  String get navReplays => 'Registrazioni';

  @override
  String get replaysTitle => 'Registrazioni';

  @override
  String get logOut => 'Esci';

  @override
  String replaysLoadError(int code) {
    return 'Impossibile caricare le registrazioni (Errore $code)';
  }

  @override
  String replaysNetworkError(String e) {
    return 'Errore di rete: $e';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get openDownload => 'Apri / Scarica';

  @override
  String get retry => 'Riprova';

  @override
  String get noReplays => 'Nessuna registrazione ancora.';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => 'Scansiona codice QR';

  @override
  String get qrScannerHint =>
      'Scansiona il codice QR mostrato nel terminale del server!';

  @override
  String get notifChannelAlertsName => 'Avvisi PetTrack';

  @override
  String get notifChannelAlertsDesc =>
      'Notifiche sui cambi di zona e sulla batteria';

  @override
  String get notifChannelMedicalName => 'Promemoria medici';

  @override
  String get notifChannelMedicalDesc =>
      'Notifiche sulla somministrazione dei farmaci';

  @override
  String get syncToWatch => 'Sincronizza con lo smartwatch';

  @override
  String get syncStarting => 'Avvio della sincronizzazione...';

  @override
  String get syncSuccess => 'Inviato con successo all\'orologio!';

  @override
  String get syncNoWatch => 'Nessun orologio connesso trovato.';

  @override
  String get onlineStatus => 'Online';

  @override
  String get eventLog => 'Registro eventi';

  @override
  String get shareInviteText => 'Guarda cosa sta facendo il mio animale!';

  @override
  String get chooseLanguageTitle => 'Scegli la lingua';

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
  String get aiGeneratedMarker => '(GENERATO DALL\'IA)';

  @override
  String get wearSynced => 'Sincronizzato!';

  @override
  String get wearOpenAppOnPhone => 'Apri l\'app sul telefono.';

  @override
  String get wearManual => 'Manuale';

  @override
  String get wearSetupTitle => 'Configurazione';

  @override
  String get pinHint => 'PIN a 4 cifre';

  @override
  String get errInvalidPin => 'PIN non valido!';

  @override
  String get errNetwork => 'Errore di rete!';

  @override
  String get defaultPetName => 'Animale';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => 'Trova il server in rete';

  @override
  String get discoveryTitle => 'Server nella tua rete';

  @override
  String get discoverySearching => 'Ricerca nella rete locale…';

  @override
  String get discoveryEmpty => 'Nessun server PetTrack trovato.';

  @override
  String get discoveryHint =>
      'Assicurati che il server sia in esecuzione e che tu sia sulla stessa Wi-Fi.';

  @override
  String get discoveryNotSupported =>
      'La ricerca automatica non è disponibile su questo dispositivo. Inserisci l\'indirizzo del server manualmente.';

  @override
  String get discoveryTapToUse => 'Tocca per connetterti';

  @override
  String get tooltipRefresh => 'Aggiorna';

  @override
  String get tooltipAdd => 'Aggiungi';

  @override
  String get tooltipDelete => 'Elimina';

  @override
  String get highlightTitle => 'Riassunto di oggi';

  @override
  String get highlightSubtitle => 'Ogni momento di oggi in un unico clip';

  @override
  String highlightMoments(Object count) {
    return '$count momenti';
  }

  @override
  String get highlightShare => 'Condividi';

  @override
  String get quietHoursTitle => 'Ore di quiete';

  @override
  String get quietHoursSubtitle =>
      'Nessun avviso di zona o batteria in questo intervallo';

  @override
  String get quietHoursFrom => 'Dalle';

  @override
  String get quietHoursTo => 'Fino alle';

  @override
  String get batteryLowTitle => 'Batteria scarica';

  @override
  String batteryLowBody(int level) {
    return 'Batteria al $level%';
  }
}
