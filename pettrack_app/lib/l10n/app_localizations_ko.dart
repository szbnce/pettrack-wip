// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => '설정';

  @override
  String get uploadProfilePicture => '프로필 사진 업로드';

  @override
  String get serverIp => '서버 IP';

  @override
  String get serverIpHint => '예: 192.168.1.100';

  @override
  String get secretToken => '비밀 토큰';

  @override
  String get petName => '반려동물 이름';

  @override
  String get petNameHint => '이름을 입력하세요';

  @override
  String get save => '저장';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navZones => '구역';

  @override
  String get navSettings => '설정';

  @override
  String get liveVideo => '실시간 영상';

  @override
  String get activities => '활동';

  @override
  String get noRecentEvents => '최근 이벤트가 없습니다';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petName이(가) $zone에 들어갔습니다';
  }

  @override
  String get zoneVisits => '구역 방문';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petName이(가) $zone에서 나왔습니다';
  }

  @override
  String get cameraDetectedMovement => '카메라가 움직임을 감지했습니다.';

  @override
  String get editZones => '구역 편집';

  @override
  String get addNewZone => '새 구역 추가';

  @override
  String get cancel => '취소';

  @override
  String get existingZones => '기존 구역';

  @override
  String get safeZone => '안전 구역';

  @override
  String get today => '오늘';

  @override
  String get language => '언어';

  @override
  String get lastUpdated => '마지막 업데이트';

  @override
  String get justNow => '방금 전';

  @override
  String minsAgo(int mins) {
    return '$mins분 전';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String daysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get unknown => '알 수 없음';

  @override
  String get leftTheZone => '구역에서 나갔습니다.';

  @override
  String get greetingsList =>
      '안녕하세요, 보스!|다시 오신 것을 환영해요!|좋은 하루 보내세요!|안녕!|잘 지내요?|안녕하세요!|뭐 하고 있어요?|다시 만나서 반가워요!|준비됐나요?|무엇을 하는지 볼까요!';

  @override
  String get subGreetingsList =>
      '여기는 잘 지냅니다.|자는 것 같아요.|에너지가 넘쳐요!|주변을 살피고 있어요.|저녁을 기다리는 중이에요.|무엇인가를 냄새 맡고 있어요.|편안하게 쉬고 있어요.|좋아하는 자리에 있어요.|놀고 싶어 해요.|조용합니다.';

  @override
  String get petTypeTitle => '반려동물 종류';

  @override
  String get petTypeDog => '강아지';

  @override
  String get petTypeCat => '고양이';

  @override
  String get petTypeRabbit => '토끼';

  @override
  String get petTypeGuineaPig => '기니피그';

  @override
  String get petTypeBird => '새';

  @override
  String get petTypeOther => '기타';

  @override
  String get alertsTitle => '알림';

  @override
  String get alertsZone => '구역 알림(입장/퇴장)';

  @override
  String get alertsBattery => '배터리 부족 알림';

  @override
  String batteryThreshold(int level) {
    return '배터리 임계값: $level%';
  }

  @override
  String get testNotification => '테스트 알림';

  @override
  String get testNotifTitle => '테스트 알림';

  @override
  String get testNotifBody => '알림이 성공적으로 설정되었습니다!';

  @override
  String secondsAgo(int seconds) {
    return '$seconds초 전';
  }

  @override
  String get toiletZone => '화장실 / 배변 패드';

  @override
  String get bedZone => '침대 / 휴식 공간';

  @override
  String get waterZone => '물그릇';

  @override
  String get foodZone => '밥그릇';

  @override
  String get playZone => '놀이 공간';

  @override
  String get appearance => '화면 모드(테마)';

  @override
  String get themeSystem => '시스템 기본값';

  @override
  String get themeLight => '라이트 모드';

  @override
  String get themeDark => '다크 모드';

  @override
  String failedToLoadPetProfile(String e) {
    return '반려동물 프로필을 불러오지 못했습니다 $e';
  }

  @override
  String get invalidSecretToken => '잘못된 비밀 토큰입니다!';

  @override
  String decodingError(String e) {
    return '디코딩 오류: $e';
  }

  @override
  String get setupWelcomeTitle => 'PetTrack에 오신 것을 환영합니다!';

  @override
  String get setupWelcomeDesc => '반려동물을 지켜보는 가장 좋은 방법.\n\n먼저 서버에 연결해 볼까요.';

  @override
  String get setupScanBtn => 'QR 코드 읽기';

  @override
  String get setupSuccessTitle => '성공!';

  @override
  String get setupSuccessDesc => '연결이 암호화되었습니다.\n이제 반려동물을 등록해 볼까요.';

  @override
  String get setupNextBtn => '다음 단계';

  @override
  String get setupErrConnect => '서버에 연결하지 못했습니다! 네트워크를 확인하세요.';

  @override
  String get setupErrSave => '프로필을 저장하지 못했습니다.';

  @override
  String get setupErrEmpty => '이름을 입력하세요!';

  @override
  String get setupMonitorTitle => '모니터 설정';

  @override
  String get setupMonitorDesc => '다른 휴대폰에서 Monitor 앱을 열고 이 QR 코드를 스캔하여 연결하세요!';

  @override
  String get settingsShowQrBtn => 'QR 코드 보기';

  @override
  String get settingsQrDialogDesc => '이전 휴대폰으로 스캔하세요:';

  @override
  String get settingsQrDialogDone => '완료';

  @override
  String get settingsResetApp => '앱 초기화 및 설정 다시 시작';

  @override
  String get settingsResetConfirmTitle => '확실한가요?';

  @override
  String get settingsResetConfirmDesc => '저장된 모든 데이터가 삭제되고 설정 마법사가 다시 시작됩니다.';

  @override
  String get serverUnreachableTitle => '서버에 연결할 수 없음';

  @override
  String get serverUnreachableDesc =>
      'PetTrack 서버에 연결할 수 없습니다.\n네트워크나 서버 실행 여부를 확인하세요.';

  @override
  String get profileAndSystem => '프로필 및 시스템';

  @override
  String get monitorAndConnection => '모니터 및 연결';

  @override
  String get offlineStatus => '오프라인!';

  @override
  String get liveStatus => '실시간';

  @override
  String get searchingStatus => '검색 중...';

  @override
  String get navMedical => '건강';

  @override
  String get medications => '투약';

  @override
  String get vaccines => '예방접종';

  @override
  String get addMedication => '투약 추가';

  @override
  String get addVaccine => '예방접종 추가';

  @override
  String get dose => '용량';

  @override
  String get time => '시간';

  @override
  String get dateGiven => '투여 날짜';

  @override
  String get nextDue => '다음 예정일';

  @override
  String get enableAlert => '알림 사용';

  @override
  String get medName => '약 이름';

  @override
  String get vacName => '백신 이름';

  @override
  String get noMedications => '아직 등록된 투약이 없습니다.';

  @override
  String get noVaccines => '아직 등록된 예방접종이 없습니다.';

  @override
  String get saveMedication => '투약 저장';

  @override
  String get saveVaccine => '예방접종 저장';

  @override
  String get cardColor => '카드 색상:';

  @override
  String get alertFrequency => '알림 주기(시간)';

  @override
  String get alertFrequencyHint => '예: 12 또는 24';

  @override
  String get medTimeTitle => '투약 시간입니다!';

  @override
  String medTimeBody(String name, String dose) {
    return '투여할 시간: $name ($dose)';
  }

  @override
  String everyXHours(int hours) {
    return '$hours시간마다';
  }

  @override
  String get setupTitle => 'PetTrack 모니터 설정';

  @override
  String get monitorTitle => 'PetTrack 모니터';

  @override
  String get monitorSleepMode => '절전 모드(화면 어둡게)';

  @override
  String get aboutTitle => '정보';

  @override
  String get aboutDescription => '이 앱은 카메라 영상을 PetTrack 백엔드로 안전하게 전송합니다.';

  @override
  String get monitorStreamingLive => '실시간 영상 스트리밍 중...';

  @override
  String get monitorWaitingForStart => 'START 명령 대기 중...';

  @override
  String get monitorReconnecting => '다시 연결 중...';

  @override
  String get start => '시작';

  @override
  String get stop => '중지';

  @override
  String monitorServer(String ip) {
    return '서버:\n$ip';
  }

  @override
  String get monitorSleeping => '절전 중... 두 번 탭하여 깨우기';

  @override
  String errorConnectionFailed(String error) {
    return '서버에 연결하지 못했습니다! IP와 토큰을 확인하세요.\n오류: $error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => 'PetTrack 앱의 QR 코드를 스캔하세요';

  @override
  String get lightMode => '☀️ 라이트 모드';

  @override
  String get darkMode => '🌙 다크 모드';

  @override
  String get welcomeTitle => 'PetTrack에 오신 것을 환영합니다';

  @override
  String get chooseMode => '모드 선택';

  @override
  String get modeClient => '클라이언트(뷰어)';

  @override
  String get modeClientDesc => '이 기기에서 영상을 시청합니다.';

  @override
  String get modeMonitor => '모니터(카메라)';

  @override
  String get modeMonitorDesc => '이 기기에서 영상을 전송합니다.';

  @override
  String get enterPin => 'PIN 입력';

  @override
  String get demoModeTitle => '데모 모드';

  @override
  String get demoModePrompt => '데모 모드로 들어가시겠습니까?';

  @override
  String get exit => '나가기';

  @override
  String get demoLivePreview => '데모 모드, 라이브 미리보기!';

  @override
  String get zoneSaved => '구역이 저장되었습니다!';

  @override
  String zoneSaveError(String e) {
    return '오류: $e';
  }

  @override
  String get newZoneTitle => '새 구역 추가';

  @override
  String get zoneNameHint => '구역 이름...';

  @override
  String get noZonesYet => '아직 구역이 없습니다.';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';

  @override
  String get submitPin => 'PIN 전송';

  @override
  String get demoModeBtn => '데모 모드';

  @override
  String get orSeparator => '또는';

  @override
  String get setupErrPin => '연결에 실패했거나 PIN이 잘못되었습니다!';

  @override
  String get saveSuccess => '설정이 저장되었습니다!';

  @override
  String get navReplays => '다시보기';

  @override
  String get replaysTitle => '다시보기';

  @override
  String get logOut => '로그아웃';

  @override
  String replaysLoadError(int code) {
    return '다시보기를 불러오지 못했습니다(오류 $code)';
  }

  @override
  String replaysNetworkError(String e) {
    return '네트워크 오류: $e';
  }

  @override
  String get close => '닫기';

  @override
  String get openDownload => '열기 / 다운로드';

  @override
  String get retry => '다시 시도';

  @override
  String get noReplays => '아직 녹화된 다시보기가 없습니다.';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => 'QR 코드 스캔';

  @override
  String get qrScannerHint => '서버 터미널에 표시된 QR 코드를 스캔하세요!';

  @override
  String get notifChannelAlertsName => 'PetTrack 알림';

  @override
  String get notifChannelAlertsDesc => '구역 변경 및 배터리 관련 알림';

  @override
  String get notifChannelMedicalName => '건강 리마인더';

  @override
  String get notifChannelMedicalDesc => '투약 관련 알림';

  @override
  String get syncToWatch => '스마트워치와 동기화';

  @override
  String get syncStarting => '동기화를 시작합니다...';

  @override
  String get syncSuccess => '워치로 전송했습니다!';

  @override
  String get syncNoWatch => '연결된 워치를 찾을 수 없습니다.';

  @override
  String get onlineStatus => '온라인';

  @override
  String get eventLog => '이벤트 로그';

  @override
  String get shareInviteText => '우리 반려동물이 뭘 하는지 보세요!';

  @override
  String get chooseLanguageTitle => '언어 선택';

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
  String get aiGeneratedMarker => '(AI 생성)';

  @override
  String get wearSynced => '동기화됨!';

  @override
  String get wearOpenAppOnPhone => '휴대폰에서 앱을 여세요.';

  @override
  String get wearManual => '수동';

  @override
  String get wearSetupTitle => '설정';

  @override
  String get pinHint => '4자리 PIN';

  @override
  String get errInvalidPin => '잘못된 PIN입니다!';

  @override
  String get errNetwork => '네트워크 오류!';

  @override
  String get defaultPetName => '반려동물';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => '네트워크에서 서버 찾기';

  @override
  String get discoveryTitle => '네트워크의 서버';

  @override
  String get discoverySearching => '로컬 네트워크 검색 중…';

  @override
  String get discoveryEmpty => '아직 PetTrack 서버를 찾지 못했습니다.';

  @override
  String get discoveryHint => '서버가 실행 중이고 같은 Wi-Fi에 연결되어 있는지 확인하세요.';

  @override
  String get discoveryNotSupported =>
      '이 기기에서는 자동 검색을 사용할 수 없습니다. 서버 주소를 직접 입력하세요.';

  @override
  String get discoveryTapToUse => '탭하여 연결';

  @override
  String get tooltipRefresh => '새로 고침';

  @override
  String get tooltipAdd => '추가';

  @override
  String get tooltipDelete => '삭제';

  @override
  String get highlightTitle => '오늘의 하이라이트';

  @override
  String get highlightSubtitle => '오늘의 모든 순간을 한 클립에';

  @override
  String highlightMoments(Object count) {
    return '순간 $count개';
  }

  @override
  String get highlightShare => '공유';

  @override
  String get quietHoursTitle => '무음 시간';

  @override
  String get quietHoursSubtitle => '이 시간에는 구역·배터리 알림을 보내지 않습니다';

  @override
  String get quietHoursFrom => '시작';

  @override
  String get quietHoursTo => '종료';

  @override
  String get batteryLowTitle => '배터리 부족';

  @override
  String batteryLowBody(int level) {
    return '배터리 잔량 $level%';
  }

  @override
  String get aboutCardTitle => '정보 및 업데이트';

  @override
  String get versionAppLabel => '앱';

  @override
  String get versionServerLabel => '서버';

  @override
  String get versionCheckButton => '지금 확인';

  @override
  String get versionUnknown => '연결되지 않음';

  @override
  String get versionMatch => '앱과 서버 버전이 일치합니다';

  @override
  String get versionAppOlder => '서버가 더 최신입니다 — 앱을 업데이트하세요';

  @override
  String get versionServerOlder => '앱이 더 최신입니다 — 서버를 업데이트하세요';

  @override
  String get privacyButton => '개인정보 보호';

  @override
  String get privacyTitle => '개인정보 보호';

  @override
  String get privacyBody =>
      'PetTrack은 완전한 셀프 호스팅입니다 — 카메라 영상, 녹화, 반려동물 데이터는 모두 내 서버에만 있습니다.\n\n• 클라우드 없음, 어디에도 업로드되지 않음\n• 계정 없음 — 가입할 서비스가 없음\n• 분석 및 추적 없음\n• 기본은 로컬 네트워크 전용, 원격 접속은 직접 설정한 경우만';

  @override
  String get whatsNewButton => '새로운 기능';

  @override
  String get whatsNewTitle => '새로운 기능';

  @override
  String get changelogBody =>
      '1.0.0\n• 대시보드의 \'오늘의 요약\'\n• 알림 방해 금지 시간대\n• Home Assistant 연동\n• Material 3 디자인';
}
