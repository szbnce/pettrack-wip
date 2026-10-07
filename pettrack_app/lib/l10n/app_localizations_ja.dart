// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => '設定';

  @override
  String get uploadProfilePicture => 'プロフィール画像をアップロード';

  @override
  String get serverIp => 'サーバーIP';

  @override
  String get serverIpHint => '例: 192.168.1.100';

  @override
  String get secretToken => 'シークレットトークン';

  @override
  String get petName => 'ペットの名前';

  @override
  String get petNameHint => '名前を入力';

  @override
  String get save => '保存';

  @override
  String get navDashboard => 'ダッシュボード';

  @override
  String get navZones => 'ゾーン';

  @override
  String get navSettings => '設定';

  @override
  String get liveVideo => 'ライブ映像';

  @override
  String get activities => 'アクティビティ';

  @override
  String get noRecentEvents => '最近のイベントはありません';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petNameが$zoneに入りました';
  }

  @override
  String get zoneVisits => 'ゾーン訪問';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petNameが$zoneを出ました';
  }

  @override
  String get cameraDetectedMovement => 'カメラが動きを検出しました。';

  @override
  String get editZones => 'ゾーンを編集';

  @override
  String get addNewZone => '新しいゾーンを追加';

  @override
  String get cancel => 'キャンセル';

  @override
  String get existingZones => '既存のゾーン';

  @override
  String get safeZone => 'セーフゾーン';

  @override
  String get today => '今日';

  @override
  String get language => '言語';

  @override
  String get lastUpdated => '最終更新';

  @override
  String get justNow => 'たった今';

  @override
  String minsAgo(int mins) {
    return '$mins分前';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String daysAgo(int days) {
    return '$days日前';
  }

  @override
  String get unknown => '不明';

  @override
  String get leftTheZone => 'ゾーンを出ました。';

  @override
  String get greetingsList =>
      'やあ、ボス！|おかえり！|いい一日を！|やあ！|元気？|こんにちは！|調子はどう？|また会えて嬉しいよ！|準備はいい？|何をしているか見てみよう！';

  @override
  String get subGreetingsList =>
      'ここは順調です。|眠っているようです。|元気いっぱい！|あたりを見張っています。|夕食を待っています。|何かを嗅いでいます。|落ち着いて休んでいます。|お気に入りの場所です。|遊びたがっています。|静かです。';

  @override
  String get petTypeTitle => 'ペットの種類';

  @override
  String get petTypeDog => '犬';

  @override
  String get petTypeCat => '猫';

  @override
  String get petTypeRabbit => 'うさぎ';

  @override
  String get petTypeGuineaPig => 'モルモット';

  @override
  String get petTypeBird => '鳥';

  @override
  String get petTypeOther => 'その他';

  @override
  String get alertsTitle => '通知';

  @override
  String get alertsZone => 'ゾーン通知（入退場）';

  @override
  String get alertsBattery => 'バッテリー低下アラート';

  @override
  String batteryThreshold(int level) {
    return 'バッテリーしきい値: $level%';
  }

  @override
  String get testNotification => 'テスト通知';

  @override
  String get testNotifTitle => 'テスト通知';

  @override
  String get testNotifBody => '通知の設定が完了しました！';

  @override
  String secondsAgo(int seconds) {
    return '$seconds秒前';
  }

  @override
  String get toiletZone => 'トイレ／猫砂';

  @override
  String get bedZone => 'ベッド／休憩エリア';

  @override
  String get waterZone => '水入れ';

  @override
  String get foodZone => 'フード皿';

  @override
  String get playZone => '遊びエリア';

  @override
  String get appearance => '外観（テーマ）';

  @override
  String get themeSystem => 'システムデフォルト';

  @override
  String get themeLight => 'ライトモード';

  @override
  String get themeDark => 'ダークモード';

  @override
  String failedToLoadPetProfile(String e) {
    return 'ペットプロフィールの読み込みに失敗しました $e';
  }

  @override
  String get invalidSecretToken => '無効なシークレットトークンです！';

  @override
  String decodingError(String e) {
    return 'デコードエラー: $e';
  }

  @override
  String get setupWelcomeTitle => 'PetTrackへようこそ！';

  @override
  String get setupWelcomeDesc => 'ペットを見守る最良の方法。\n\nまず、サーバーに接続しましょう。';

  @override
  String get setupScanBtn => 'QRコードを読み取る';

  @override
  String get setupSuccessTitle => '成功！';

  @override
  String get setupSuccessDesc => '接続は暗号化されています。\n次にペットを登録しましょう。';

  @override
  String get setupNextBtn => '次のステップ';

  @override
  String get setupErrConnect => 'サーバーへの接続に失敗しました！ネットワークを確認してください。';

  @override
  String get setupErrSave => 'プロフィールの保存に失敗しました。';

  @override
  String get setupErrEmpty => '名前を入力してください！';

  @override
  String get setupMonitorTitle => 'モニター設定';

  @override
  String get setupMonitorDesc =>
      'もう一方のスマホでMonitorアプリを開き、このQRコードをスキャンして接続してください！';

  @override
  String get settingsShowQrBtn => 'QRコードを表示';

  @override
  String get settingsQrDialogDesc => '古いスマホでスキャンしてください：';

  @override
  String get settingsQrDialogDone => '完了';

  @override
  String get settingsResetApp => 'アプリをリセットして設定をやり直す';

  @override
  String get settingsResetConfirmTitle => '本当によろしいですか？';

  @override
  String get settingsResetConfirmDesc =>
      '保存されたすべてのデータが削除され、セットアップウィザードが再起動します。';

  @override
  String get serverUnreachableTitle => 'サーバーに接続できません';

  @override
  String get serverUnreachableDesc =>
      'PetTrackサーバーに接続できません。\nネットワークやサーバーの起動状態を確認してください。';

  @override
  String get profileAndSystem => 'プロフィールとシステム';

  @override
  String get monitorAndConnection => 'モニターと接続';

  @override
  String get offlineStatus => 'オフライン！';

  @override
  String get liveStatus => 'ライブ';

  @override
  String get searchingStatus => '検索中...';

  @override
  String get navMedical => '医療';

  @override
  String get medications => '投薬';

  @override
  String get vaccines => 'ワクチン';

  @override
  String get addMedication => '投薬を追加';

  @override
  String get addVaccine => 'ワクチンを追加';

  @override
  String get dose => '用量';

  @override
  String get time => '時刻';

  @override
  String get dateGiven => '投与日';

  @override
  String get nextDue => '次回予定';

  @override
  String get enableAlert => 'アラートを有効にする';

  @override
  String get medName => '薬の名前';

  @override
  String get vacName => 'ワクチン名';

  @override
  String get noMedications => '投薬はまだ追加されていません。';

  @override
  String get noVaccines => 'ワクチンはまだ追加されていません。';

  @override
  String get saveMedication => '投薬を保存';

  @override
  String get saveVaccine => 'ワクチンを保存';

  @override
  String get cardColor => 'カードの色:';

  @override
  String get alertFrequency => 'アラート間隔（時間）';

  @override
  String get alertFrequencyHint => '例: 12 または 24';

  @override
  String get medTimeTitle => '投薬の時間です！';

  @override
  String medTimeBody(String name, String dose) {
    return '投与する時間: $name（$dose）';
  }

  @override
  String everyXHours(int hours) {
    return '$hours時間ごと';
  }

  @override
  String get setupTitle => 'PetTrackモニター設定';

  @override
  String get monitorTitle => 'PetTrackモニター';

  @override
  String get monitorSleepMode => 'スリープモード（画面を暗くする）';

  @override
  String get aboutTitle => 'このアプリについて';

  @override
  String get aboutDescription => 'このアプリはカメラ映像を安全にPetTrackバックエンドへ配信します。';

  @override
  String get monitorStreamingLive => 'ライブ映像を配信中...';

  @override
  String get monitorWaitingForStart => 'STARTコマンドを待機中...';

  @override
  String get monitorReconnecting => '再接続中...';

  @override
  String get start => '開始';

  @override
  String get stop => '停止';

  @override
  String monitorServer(String ip) {
    return 'サーバー:\n$ip';
  }

  @override
  String get monitorSleeping => 'スリープ中... ダブルタップで起動';

  @override
  String errorConnectionFailed(String error) {
    return 'サーバーへの接続に失敗しました！IPとトークンを確認してください。\nエラー: $error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => 'PetTrackアプリのQRコードをスキャンしてください';

  @override
  String get lightMode => '☀️ ライトモード';

  @override
  String get darkMode => '🌙 ダークモード';

  @override
  String get welcomeTitle => 'PetTrackへようこそ';

  @override
  String get chooseMode => 'モードを選択';

  @override
  String get modeClient => 'クライアント（閲覧）';

  @override
  String get modeClientDesc => 'このデバイスは映像を視聴します。';

  @override
  String get modeMonitor => 'モニター（カメラ）';

  @override
  String get modeMonitorDesc => 'このデバイスは映像を配信します。';

  @override
  String get enterPin => 'PINを入力';

  @override
  String get demoModeTitle => 'デモモード';

  @override
  String get demoModePrompt => 'デモモードに入りますか？';

  @override
  String get exit => '終了';

  @override
  String get demoLivePreview => 'デモモード、ライブプレビューはこちら！';

  @override
  String get zoneSaved => 'ゾーンを保存しました！';

  @override
  String zoneSaveError(String e) {
    return 'エラー: $e';
  }

  @override
  String get newZoneTitle => '新しいゾーンの追加';

  @override
  String get zoneNameHint => 'ゾーン名...';

  @override
  String get noZonesYet => 'まだゾーンがありません。';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get submitPin => 'PINを送信';

  @override
  String get demoModeBtn => 'デモモード';

  @override
  String get orSeparator => 'または';

  @override
  String get setupErrPin => '接続に失敗したか、PINが無効です！';

  @override
  String get saveSuccess => '設定を保存しました！';

  @override
  String get navReplays => 'リプレイ';

  @override
  String get replaysTitle => 'リプレイ';

  @override
  String get logOut => 'ログアウト';

  @override
  String replaysLoadError(int code) {
    return 'リプレイの読み込みに失敗しました（エラー $code）';
  }

  @override
  String replaysNetworkError(String e) {
    return 'ネットワークエラー: $e';
  }

  @override
  String get close => '閉じる';

  @override
  String get openDownload => '開く / ダウンロード';

  @override
  String get retry => '再試行';

  @override
  String get noReplays => 'まだリプレイが録画されていません。';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => 'QRコードをスキャン';

  @override
  String get qrScannerHint => 'サーバーのターミナルに表示されたQRコードをスキャンしてください！';

  @override
  String get notifChannelAlertsName => 'PetTrackアラート';

  @override
  String get notifChannelAlertsDesc => 'ゾーンの変更とバッテリーに関する通知';

  @override
  String get notifChannelMedicalName => '医療リマインダー';

  @override
  String get notifChannelMedicalDesc => '投薬に関する通知';

  @override
  String get syncToWatch => 'スマートウォッチと同期';

  @override
  String get syncStarting => '同期を開始しています...';

  @override
  String get syncSuccess => 'ウォッチに送信しました！';

  @override
  String get syncNoWatch => '接続されたウォッチが見つかりません。';

  @override
  String get onlineStatus => 'オンライン';

  @override
  String get eventLog => 'イベントログ';

  @override
  String get shareInviteText => 'うちのペットの様子を見て！';

  @override
  String get chooseLanguageTitle => '言語を選択';

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
  String get aiGeneratedMarker => '（AI生成）';

  @override
  String get wearSynced => '同期しました！';

  @override
  String get wearOpenAppOnPhone => 'スマホでアプリを開いてください。';

  @override
  String get wearManual => '手動';

  @override
  String get wearSetupTitle => 'セットアップ';

  @override
  String get pinHint => '4桁のPIN';

  @override
  String get errInvalidPin => 'PINが無効です！';

  @override
  String get errNetwork => 'ネットワークエラー！';

  @override
  String get defaultPetName => 'ペット';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => 'ネットワークからサーバーを探す';

  @override
  String get discoveryTitle => 'ネットワーク上のサーバー';

  @override
  String get discoverySearching => 'ローカルネットワークを検索中…';

  @override
  String get discoveryEmpty => 'PetTrackサーバーがまだ見つかりません。';

  @override
  String get discoveryHint => 'サーバーが起動していて、同じWi-Fiに接続しているか確認してください。';

  @override
  String get discoveryNotSupported =>
      'このデバイスでは自動検索を利用できません。サーバーアドレスを手動で入力してください。';

  @override
  String get discoveryTapToUse => 'タップして接続';

  @override
  String get tooltipRefresh => '更新';

  @override
  String get tooltipAdd => '追加';

  @override
  String get tooltipDelete => '削除';

  @override
  String get highlightTitle => '今日のまとめ';

  @override
  String get highlightSubtitle => '今日のすべての瞬間を1つのクリップに';

  @override
  String highlightMoments(Object count) {
    return '$count 件の瞬間';
  }

  @override
  String get highlightShare => '共有';

  @override
  String get quietHoursTitle => '消音時間';

  @override
  String get quietHoursSubtitle => 'この時間帯はゾーン・バッテリー通知を送りません';

  @override
  String get quietHoursFrom => '開始';

  @override
  String get quietHoursTo => '終了';

  @override
  String get batteryLowTitle => 'バッテリー残量低下';

  @override
  String batteryLowBody(int level) {
    return 'バッテリー残量 $level%';
  }

  @override
  String get aboutCardTitle => 'バージョンとアップデート';

  @override
  String get versionAppLabel => 'アプリ';

  @override
  String get versionServerLabel => 'サーバー';

  @override
  String get versionCheckButton => '今すぐ確認';

  @override
  String get versionUnknown => '未接続';

  @override
  String get versionMatch => 'アプリとサーバーのバージョンは一致しています';

  @override
  String get versionAppOlder => 'サーバーの方が新しいです — アプリを更新してください';

  @override
  String get versionServerOlder => 'アプリの方が新しいです — サーバーを更新してください';

  @override
  String get privacyButton => 'プライバシー';

  @override
  String get privacyTitle => 'プライバシー';

  @override
  String get privacyBody =>
      'PetTrack は完全にセルフホストです — カメラ映像、録画、ペットのデータはすべて自分のサーバーに留まります。\n\n• クラウドなし、どこにもアップロードされません\n• アカウントなし — 登録するサービスはありません\n• 分析・トラッキングなし\n• 既定では LAN 内のみ。リモートアクセスは自分で設定した場合だけです';

  @override
  String get whatsNewButton => '新機能';

  @override
  String get whatsNewTitle => '新機能';

  @override
  String get changelogBody =>
      '1.0.0\n• ダッシュボードに「今日のまとめ」\n• アラートのサイレント時間\n• Home Assistant 連携\n• Material 3 デザイン';

  @override
  String get tooltipPlaySound => '音を鳴らす';

  @override
  String get tooltipSnapshot => 'スナップショットを撮る';

  @override
  String get playSoundSent => 'モニターに音を送信しました';

  @override
  String get tooltipTimelapse => '1日のタイムラプス';

  @override
  String get timelapseBuilding => 'その日のタイムラプスを作成中…';

  @override
  String get timelapseEmpty => '今日はまだフレームが足りません';

  @override
  String timelapseError(int code) {
    return 'タイムラプスを作成できませんでした（エラー $code）';
  }

  @override
  String get tooltipNightMode => 'ナイトモード';

  @override
  String get nightModeOn => 'ナイトモードをオンにしました';

  @override
  String get nightModeOff => 'ナイトモードをオフにしました';

  @override
  String get alertsSound => '音の通知（鳴き声）';

  @override
  String get soundDetectedTitle => '音を検出しました';

  @override
  String get soundDetectedBody => 'カメラの近くで大きな音がしました。';
}
