// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'PetTrack';

  @override
  String get settingsTitle => '设置';

  @override
  String get uploadProfilePicture => '上传头像';

  @override
  String get serverIp => '服务器 IP';

  @override
  String get serverIpHint => '例如 192.168.1.100';

  @override
  String get secretToken => '密钥令牌';

  @override
  String get petName => '宠物名字';

  @override
  String get petNameHint => '请输入名字';

  @override
  String get save => '保存';

  @override
  String get navDashboard => '仪表盘';

  @override
  String get navZones => '区域';

  @override
  String get navSettings => '设置';

  @override
  String get liveVideo => '实时视频';

  @override
  String get activities => '活动';

  @override
  String get noRecentEvents => '最近没有事件';

  @override
  String zoneEntered(String petName, String zone) {
    return '$petName进入了$zone';
  }

  @override
  String get zoneVisits => '区域访问';

  @override
  String zoneLeft(String petName, String zone) {
    return '$petName离开了$zone';
  }

  @override
  String get cameraDetectedMovement => '摄像头检测到移动。';

  @override
  String get editZones => '编辑区域';

  @override
  String get addNewZone => '添加新区域';

  @override
  String get cancel => '取消';

  @override
  String get existingZones => '现有区域';

  @override
  String get safeZone => '安全区域';

  @override
  String get today => '今天';

  @override
  String get language => '语言';

  @override
  String get lastUpdated => '最后更新';

  @override
  String get justNow => '刚刚';

  @override
  String minsAgo(int mins) {
    return '$mins分钟前';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get unknown => '未知';

  @override
  String get leftTheZone => '离开了区域。';

  @override
  String get greetingsList =>
      '嗨，老板！|欢迎回来！|祝你今天愉快！|嘿！|你好吗？|你好！|最近怎么样？|很高兴又见到你！|准备好了吗？|来看看它们在做什么！';

  @override
  String get subGreetingsList =>
      '这里一切都好。|好像在睡觉。|精力充沛！|正在观察周围。|在等晚饭。|在闻什么东西。|在安静休息。|在最喜欢的地方。|想玩耍。|一切安静。';

  @override
  String get petTypeTitle => '宠物类型';

  @override
  String get petTypeDog => '狗';

  @override
  String get petTypeCat => '猫';

  @override
  String get petTypeRabbit => '兔子';

  @override
  String get petTypeGuineaPig => '豚鼠';

  @override
  String get petTypeBird => '鸟';

  @override
  String get petTypeOther => '其他';

  @override
  String get alertsTitle => '通知';

  @override
  String get alertsZone => '区域提醒（进入/离开）';

  @override
  String get alertsBattery => '低电量提醒';

  @override
  String batteryThreshold(int level) {
    return '电量阈值：$level%';
  }

  @override
  String get testNotification => '测试通知';

  @override
  String get testNotifTitle => '测试通知';

  @override
  String get testNotifBody => '通知设置成功！';

  @override
  String get alertsRemoteTitle => '外出时的警报';

  @override
  String get alertsRemoteDesc =>
      '将警报转发到 ntfy 主题，让你在任何地方都能收到——ntfy 应用或任意浏览器。请取一个难以猜到的主题名；任何有链接的人都能订阅。';

  @override
  String get alertsRemoteUrlLabel => 'ntfy 主题 URL';

  @override
  String get alertsRemoteUrlHint => 'https://ntfy.sh/你的秘密主题';

  @override
  String get alertsRemoteTokenLabel => '访问令牌（可选）';

  @override
  String get alertsRemoteTest => '发送测试通知';

  @override
  String get alertsRemoteTestSent => '测试通知已发送 — 请查看手机。';

  @override
  String get alertsRemoteTestFailed => '无法发送测试通知。请检查主题 URL 和服务器。';

  @override
  String get alertsRemoteUrlInvalid => '这看起来不是有效的 ntfy URL。';

  @override
  String secondsAgo(int seconds) {
    return '$seconds秒前';
  }

  @override
  String get toiletZone => '猫砂盆 / 厕所';

  @override
  String get bedZone => '床 / 休息区';

  @override
  String get waterZone => '水碗';

  @override
  String get foodZone => '食盆';

  @override
  String get playZone => '玩耍区';

  @override
  String get appearance => '外观（主题）';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String failedToLoadPetProfile(String e) {
    return '加载宠物资料失败 $e';
  }

  @override
  String get invalidSecretToken => '密钥令牌无效！';

  @override
  String decodingError(String e) {
    return '解码错误：$e';
  }

  @override
  String get setupWelcomeTitle => '欢迎使用 PetTrack！';

  @override
  String get setupWelcomeDesc => '照看宠物的最佳方式。\n\n首先，让我们连接到服务器。';

  @override
  String get setupScanBtn => '读取二维码';

  @override
  String get setupSuccessTitle => '成功！';

  @override
  String get setupSuccessDesc => '连接已加密。\n现在来登记你的宠物。';

  @override
  String get setupNextBtn => '下一步';

  @override
  String get setupErrConnect => '连接服务器失败！请检查网络。';

  @override
  String get setupErrSave => '保存资料失败。';

  @override
  String get setupErrEmpty => '请输入名字！';

  @override
  String get setupMonitorTitle => '监视器设置';

  @override
  String get setupMonitorDesc => '在另一部手机上打开 Monitor 应用，扫描此二维码进行连接！';

  @override
  String get settingsShowQrBtn => '显示二维码';

  @override
  String get settingsQrDialogDesc => '用旧手机扫描：';

  @override
  String get settingsQrDialogDone => '完成';

  @override
  String get settingsResetApp => '重置应用并重新设置';

  @override
  String get settingsResetConfirmTitle => '确定吗？';

  @override
  String get settingsResetConfirmDesc => '这将删除所有保存的数据并重新启动设置向导。';

  @override
  String get serverUnreachableTitle => '无法连接服务器';

  @override
  String get serverUnreachableDesc => '无法连接到 PetTrack 服务器。\n请检查网络或服务器是否在运行。';

  @override
  String get profileAndSystem => '资料与系统';

  @override
  String get monitorAndConnection => '监视器与连接';

  @override
  String get offlineStatus => '离线！';

  @override
  String get liveStatus => '直播';

  @override
  String get searchingStatus => '搜索中...';

  @override
  String get navMedical => '健康';

  @override
  String get medications => '用药';

  @override
  String get vaccines => '疫苗';

  @override
  String get addMedication => '添加用药';

  @override
  String get addVaccine => '添加疫苗';

  @override
  String get dose => '剂量';

  @override
  String get time => '时间';

  @override
  String get dateGiven => '给药日期';

  @override
  String get nextDue => '下次到期';

  @override
  String get enableAlert => '启用提醒';

  @override
  String get medName => '药品名称';

  @override
  String get vacName => '疫苗名称';

  @override
  String get noMedications => '还没有添加用药。';

  @override
  String get noVaccines => '还没有添加疫苗。';

  @override
  String get saveMedication => '保存用药';

  @override
  String get saveVaccine => '保存疫苗';

  @override
  String get cardColor => '卡片颜色：';

  @override
  String get alertFrequency => '提醒频率（小时）';

  @override
  String get alertFrequencyHint => '例如 12 或 24';

  @override
  String get medTimeTitle => '用药时间到！';

  @override
  String medTimeBody(String name, String dose) {
    return '该给药了：$name（$dose）';
  }

  @override
  String everyXHours(int hours) {
    return '每$hours小时';
  }

  @override
  String get setupTitle => 'PetTrack 监视器设置';

  @override
  String get monitorTitle => 'PetTrack 监视器';

  @override
  String get monitorSleepMode => '休眠模式（调暗屏幕）';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutDescription => '此应用安全地将摄像头画面传输到 PetTrack 后端。';

  @override
  String get monitorStreamingLive => '正在直播视频...';

  @override
  String get monitorWaitingForStart => '等待 START 命令...';

  @override
  String get monitorReconnecting => '正在重新连接...';

  @override
  String get start => '开始';

  @override
  String get stop => '停止';

  @override
  String monitorServer(String ip) {
    return '服务器：\n$ip';
  }

  @override
  String get monitorSleeping => '休眠中... 双击唤醒';

  @override
  String errorConnectionFailed(String error) {
    return '连接服务器失败！请检查 IP 和令牌。\n错误：$error';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get setupScanQrTitle => '扫描 PetTrack 应用中的二维码';

  @override
  String get lightMode => '☀️ 浅色模式';

  @override
  String get darkMode => '🌙 深色模式';

  @override
  String get welcomeTitle => '欢迎使用 PetTrack';

  @override
  String get chooseMode => '选择模式';

  @override
  String get modeClient => '客户端（观看）';

  @override
  String get modeClientDesc => '此设备将观看直播。';

  @override
  String get modeMonitor => '监视器（摄像头）';

  @override
  String get modeMonitorDesc => '此设备将传输视频。';

  @override
  String get enterPin => '输入 PIN';

  @override
  String get demoModeTitle => '演示模式';

  @override
  String get demoModePrompt => '要进入演示模式吗？';

  @override
  String get exit => '退出';

  @override
  String get demoLivePreview => '演示模式，实时预览在这里！';

  @override
  String get zoneSaved => '区域已保存！';

  @override
  String zoneSaveError(String e) {
    return '错误：$e';
  }

  @override
  String get newZoneTitle => '添加新区域';

  @override
  String get zoneNameHint => '区域名称...';

  @override
  String get noZonesYet => '还没有区域。';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get submitPin => '提交 PIN';

  @override
  String get demoModeBtn => '演示模式';

  @override
  String get demoNoPlayback => '演示模式 — 无法播放视频';

  @override
  String get insightsTitle => '活动洞察';

  @override
  String get insightsEntrySubtitle => '活动、区域与休息一目了然';

  @override
  String insightsRangeDays(int n) {
    return '$n 天';
  }

  @override
  String get insightsActiveToday => '今日活动';

  @override
  String get insightsAvgPerDay => '每天（平均）';

  @override
  String get insightsMostActiveZone => '最活跃区域';

  @override
  String get insightsActivityChart => '每日活动分钟数';

  @override
  String get insightsZoneChart => '各区域停留时间';

  @override
  String get insightsZoneEmpty => '此时间段内没有区域停留记录';

  @override
  String get insightsActiveVsRest => '活动与休息（日均）';

  @override
  String get insightsWordActive => '活动';

  @override
  String get insightsWordRest => '休息';

  @override
  String get insightsTableDay => '日期';

  @override
  String get tooltipInsightsList => '以表格显示';

  @override
  String get tooltipInsightsChart => '以图表显示';

  @override
  String insightsDurationH(int n) {
    return '$n 小时';
  }

  @override
  String insightsDurationHm(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String insightsDurationM(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String insightsDurationS(int seconds) {
    return '$seconds 秒';
  }

  @override
  String insightsClips(int n) {
    return '$n 个动作片段';
  }

  @override
  String insightsSounds(int n) {
    return '$n 个声音事件';
  }

  @override
  String get insightsLoadError => '无法加载洞察数据';

  @override
  String get demoZoneKitchen => '厨房';

  @override
  String get demoZoneSofa => '沙发';

  @override
  String get demoZoneBed => '床';

  @override
  String get demoZoneGarden => '花园';

  @override
  String get healthCardTitle => '系统状态';

  @override
  String get healthCameraOnline => '摄像头在线';

  @override
  String get healthCameraOffline => '摄像头离线';

  @override
  String healthLastSeen(String duration) {
    return '最后画面：$duration';
  }

  @override
  String healthDiskFreeOf(String free, String total) {
    return '$total 中剩余 $free';
  }

  @override
  String get healthDiskLow => '磁盘空间不足 — 将清理旧回放';

  @override
  String healthReplaysStored(int count, String size) {
    return '$count 个回放 · $size';
  }

  @override
  String get healthKeepReplays => '回放保留时长';

  @override
  String get healthRetentionSaved => '回放保留设置已更新';

  @override
  String get healthLoadError => '无法加载系统状态';

  @override
  String get cameraOfflineTitle => '摄像头离线';

  @override
  String get cameraOfflineBody => '摄像头已有 10 分钟没有画面';

  @override
  String get diskLowTitle => '磁盘空间不足';

  @override
  String get diskLowBody => '正在清理旧回放以释放空间';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsSignOutTitle => '从此服务器退出登录？';

  @override
  String get settingsSignOutMessage => '此设备将忘记令牌，服务器上的会话会被吊销。可用配对 PIN 重新登录。';

  @override
  String get orSeparator => '或';

  @override
  String get setupErrPin => '连接失败或 PIN 无效！';

  @override
  String get saveSuccess => '设置已保存！';

  @override
  String get navReplays => '回放';

  @override
  String get replaysTitle => '回放';

  @override
  String get logOut => '退出登录';

  @override
  String replaysLoadError(int code) {
    return '加载回放失败（错误 $code）';
  }

  @override
  String replaysNetworkError(String e) {
    return '网络错误：$e';
  }

  @override
  String get close => '关闭';

  @override
  String get openDownload => '打开 / 下载';

  @override
  String get retry => '重试';

  @override
  String get noReplays => '还没有录制的回放。';

  @override
  String replaySizeMb(String size) {
    return '${size}MB';
  }

  @override
  String get qrScannerTitle => '扫描二维码';

  @override
  String get qrScannerHint => '扫描服务器终端中显示的二维码！';

  @override
  String get notifChannelAlertsName => 'PetTrack 提醒';

  @override
  String get notifChannelAlertsDesc => '区域变化和电量相关通知';

  @override
  String get notifChannelMedicalName => '健康提醒';

  @override
  String get notifChannelMedicalDesc => '用药相关通知';

  @override
  String get syncToWatch => '与智能手表同步';

  @override
  String get syncStarting => '正在开始同步...';

  @override
  String get syncSuccess => '已成功发送到手表！';

  @override
  String get syncNoWatch => '未找到已连接的手表。';

  @override
  String get onlineStatus => '在线';

  @override
  String get eventLog => '事件日志';

  @override
  String get shareInviteText => '看看我的宠物在做什么！';

  @override
  String get chooseLanguageTitle => '选择语言';

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
  String get aiGeneratedMarker => '（AI 生成）';

  @override
  String get wearSynced => '已同步！';

  @override
  String get wearOpenAppOnPhone => '请在手机上打开应用。';

  @override
  String get wearManual => '手动';

  @override
  String get wearSetupTitle => '设置';

  @override
  String get pinHint => '4 位 PIN';

  @override
  String get errInvalidPin => 'PIN 无效！';

  @override
  String get errNetwork => '网络错误！';

  @override
  String get defaultPetName => '宠物';

  @override
  String get appVersion => 'v1.0 Pre-Release';

  @override
  String get discoveryBtn => '在网络中查找服务器';

  @override
  String get discoveryTitle => '您网络中的服务器';

  @override
  String get discoverySearching => '正在搜索本地网络…';

  @override
  String get discoveryEmpty => '尚未找到 PetTrack 服务器。';

  @override
  String get discoveryHint => '请确保服务器正在运行，并且手机连接到同一个 Wi-Fi。';

  @override
  String get discoveryNotSupported => '此设备不支持自动查找。请手动输入服务器地址。';

  @override
  String get discoveryTapToUse => '点按以连接';

  @override
  String get tooltipRefresh => '刷新';

  @override
  String get tooltipAdd => '添加';

  @override
  String get tooltipDelete => '删除';

  @override
  String get highlightTitle => '今日回顾';

  @override
  String get highlightSubtitle => '今天的每个瞬间，一支视频';

  @override
  String highlightMoments(Object count) {
    return '$count 个瞬间';
  }

  @override
  String get tooltipShare => '分享';

  @override
  String get quietHoursTitle => '免打扰时段';

  @override
  String get quietHoursSubtitle => '此时段不发送区域或电量提醒';

  @override
  String get quietHoursFrom => '从';

  @override
  String get quietHoursTo => '到';

  @override
  String get snoozeTitle => '静音提醒';

  @override
  String get snoozeChip => '静音';

  @override
  String get snoozeChipActive => '已静音';

  @override
  String get snooze30m => '30 分钟';

  @override
  String get snooze1h => '1 小时';

  @override
  String get snoozeTonight => '直到 23:00';

  @override
  String get snoozeEnd => '结束静音';

  @override
  String snoozeActive(String time) {
    return '此手机的提醒将静音至 $time';
  }

  @override
  String get snoozeEnded => '此手机的提醒已重新开启。';

  @override
  String get batteryLowTitle => '电量不足';

  @override
  String batteryLowBody(int level) {
    return '电量剩余 $level%';
  }

  @override
  String get aboutCardTitle => '关于与更新';

  @override
  String get versionAppLabel => '应用';

  @override
  String get versionServerLabel => '服务器';

  @override
  String get versionCheckButton => '立即检查';

  @override
  String get versionUnknown => '未连接';

  @override
  String get versionMatch => '应用与服务器版本一致';

  @override
  String get versionAppOlder => '服务器版本较新 — 请更新应用';

  @override
  String get versionServerOlder => '应用版本较新 — 请更新服务器';

  @override
  String updateAvailable(String version) {
    return '版本 $version 已可安装';
  }

  @override
  String get updateInstallButton => '安装更新';

  @override
  String get updateDownloading => '正在下载…';

  @override
  String get updateDownloadFailed => '无法下载更新。请检查服务器后重试。';

  @override
  String get updateInstallFailed => '无法打开 Android 安装程序。';

  @override
  String get privacyButton => '隐私';

  @override
  String get privacyTitle => '隐私';

  @override
  String get privacyBody =>
      'PetTrack 完全自托管 — 摄像头画面、录像和宠物数据都留在你自己的服务器上。\n\n• 没有云端，任何内容都不会上传\n• 没有账户 — 无需注册任何服务\n• 没有分析或追踪\n• 默认仅限局域网；远程访问仅限你自己配置的内容';

  @override
  String get whatsNewButton => '新功能';

  @override
  String get whatsNewTitle => '新功能';

  @override
  String get changelogBody =>
      '1.0.0\n• 仪表板上的“今日回顾”\n• 通知免打扰时段\n• Home Assistant 集成\n• Material 3 设计';

  @override
  String get tooltipPlaySound => '播放声音';

  @override
  String get cameraGridLabel => '全部摄像头';

  @override
  String get widgetEmptyHint => '打开 PetTrack 以加载摄像头';

  @override
  String get tooltipSnapshot => '截取快照';

  @override
  String get playSoundSent => '声音已发送到监视器';

  @override
  String get tooltipTimelapse => '每日延时';

  @override
  String get tooltipRecap => '每日回顾';

  @override
  String get recapBuilding => '正在生成每日回顾…';

  @override
  String get recapEmpty => '这一天没有精彩时刻';

  @override
  String recapError(int code) {
    return '无法生成回顾（错误 $code）';
  }

  @override
  String get replayAllDays => '全部日期';

  @override
  String get noReplaysForDay => '这一天没有录像';

  @override
  String get timelapseBuilding => '正在生成今天的延时视频…';

  @override
  String get timelapseEmpty => '这一天的帧数不足';

  @override
  String timelapseError(int code) {
    return '无法生成延时视频（错误 $code）';
  }

  @override
  String get tooltipNightMode => '夜间模式';

  @override
  String get nightModeOn => '夜间模式已开启';

  @override
  String get nightModeOff => '夜间模式已关闭';

  @override
  String get alertsSound => '声音提醒（吠叫 / 猫叫）';

  @override
  String get soundDetectedTitle => '检测到声音';

  @override
  String get soundDetectedBody => '摄像头附近有大声响。';

  @override
  String get demoZoneLitter => '猫砂盆';

  @override
  String get demoZonePlayground => '游乐区';

  @override
  String get demoZoneFeeder => '喂食区';

  @override
  String get demoMedName => '消化补充剂';

  @override
  String get demoMedDose => '0.5 毫升';

  @override
  String get demoVacName => '粘液瘤病疫苗';

  @override
  String get activityLoadError => '无法加载活动记录';

  @override
  String get zonesLoadError => '无法加载区域';

  @override
  String get cameraStartFailed => '无法启动相机';

  @override
  String get videoLoadError => '无法播放视频';

  @override
  String get medicalCachedNotice => '无法连接服务器 — 显示已保存的副本';

  @override
  String get tooltipPlayPause => '播放 / 暂停';

  @override
  String get settingsSaveError => '无法保存更改';

  @override
  String get shareFailed => '无法分享';

  @override
  String get evidenceNoClip => '该时刻附近没有录像片段';

  @override
  String get feedSearchHint => '搜索事件';

  @override
  String get feedSearchClear => '清除';

  @override
  String get feedFilterAll => '全部';

  @override
  String get feedFilterZones => '区域';

  @override
  String get feedFilterSounds => '声音';

  @override
  String get feedFilterSystem => '系统';

  @override
  String get feedNoMatch => '没有匹配的事件';

  @override
  String get armingTitle => '监控';

  @override
  String get armingModeOn => '始终开启';

  @override
  String get armingModeSchedule => '按计划';

  @override
  String get armingModeOff => '关闭';

  @override
  String get armingStatusArmed => '监控中';

  @override
  String get armingStatusDisarmed => '已停止';

  @override
  String get armingAddWindow => '添加时段';

  @override
  String get armingRemoveWindow => '删除时段';

  @override
  String get armingFrom => '开始';

  @override
  String get armingTo => '结束';

  @override
  String get armingDays => '星期';

  @override
  String get armingHelp => '监控中会记录动态并发送提醒；已停止则不保存任何录像。实时画面始终可用。';

  @override
  String get armingWindowRequired => '请至少添加一个时段';

  @override
  String get semanticCameraView => '摄像头画面';

  @override
  String get semanticChangePhoto => '更换头像';

  @override
  String get semanticZoneCanvas => '区域编辑 — 点按以放置点';

  @override
  String get semanticWakeMonitor => '双击以唤醒监视器';

  @override
  String get colorTeal => '青绿色';

  @override
  String get colorRed => '红色';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorPurple => '紫色';

  @override
  String get tooltipConfirm => '确认';

  @override
  String get backupCardTitle => '备份与恢复';

  @override
  String get backupHelp =>
      '将设置保存为一个文件——可在新手机或重装后恢复。该文件包含配对密钥，任何拿到它的人都能访问你的摄像头。';

  @override
  String get backupExport => '导出备份';

  @override
  String get backupRestore => '从备份恢复';

  @override
  String get backupExportTitle => '导出备份？';

  @override
  String get backupExportBody => '备份文件包含你的配对密钥。请只留给自己——任何拿到该文件的人都能访问你的摄像头。';

  @override
  String get backupRestoreTitle => '恢复备份？';

  @override
  String get backupRestoreBody => '这会替换本机设置；若服务器可达，也会替换服务器上的设置。';

  @override
  String get backupInvalid => '该文件不是 PetTrack 备份';

  @override
  String get backupRestored => '备份已恢复';

  @override
  String get backupRestoredOffline => '备份已在本机恢复。打开设置并保存以与服务器同步。';

  @override
  String get backupRestoreError => '无法恢复备份';

  @override
  String get setupSkipMonitor => '暂时跳过';

  @override
  String get setupMissingFields => '请输入服务器地址和 PIN';
}
