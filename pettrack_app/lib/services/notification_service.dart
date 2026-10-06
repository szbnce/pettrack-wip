import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';

/// Pure quiet-hours check, exported for tests.
///
/// [from] and [to] are minutes after midnight; the window wraps midnight
/// (e.g. 23:00–07:00). Returns true when `now` falls inside the window.
bool isWithinQuietHours(DateTime now, bool enabled, int from, int to) {
  if (!enabled) return false;
  final minutes = now.hour * 60 + now.minute;
  if (from == to) return false; // empty window
  if (from < to) return minutes >= from && minutes < to;
  return minutes >= from || minutes < to; // wraps midnight
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefsQuietEnabled = 'quiet_hours_enabled';
  static const String _prefsQuietFrom = 'quiet_hours_from';
  static const String _prefsQuietTo = 'quiet_hours_to';

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<bool> _inQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsQuietEnabled) ?? false;
    final from = prefs.getInt(_prefsQuietFrom) ?? 23 * 60;
    final to = prefs.getInt(_prefsQuietTo) ?? 7 * 60;
    return isWithinQuietHours(DateTime.now(), enabled, from, to);
  }

  Future<void> requestPermissions() async {
    if (!kIsWeb) {
      await Permission.notification.request();

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else {
      // For web, flutter_local_notifications handles permission automatically
      // when show() is called, but we can also use html.Notification if we wanted to.
    }
  }

  Future<AppLocalizations> _getL10n() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'hu';
    return lookupAppLocalizations(Locale(languageCode));
  }

  /// Show an alert-channel notification.
  ///
  /// Zone and battery alerts honour quiet hours; deliberate actions (the
  /// settings "test notification" button) pass [respectQuietHours]: false.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool respectQuietHours = true,
  }) async {
    if (respectQuietHours && await _inQuietHours()) {
      debugPrint('Notification suppressed by quiet hours: $title');
      return;
    }
    final l10n = await _getL10n();
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'pettrack_alerts_channel',
      l10n.notifChannelAlertsName,
      channelDescription: l10n.notifChannelAlertsDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required int intervalHours,
  }) async {
    final l10n = await _getL10n();
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'medical_alerts_channel',
      l10n.notifChannelMedicalName,
      channelDescription: l10n.notifChannelMedicalDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    RepeatInterval interval = RepeatInterval.daily;
    if (intervalHours <= 1) {
      interval = RepeatInterval.hourly;
    } else if (intervalHours <= 24) {
      interval = RepeatInterval.daily;
    } else {
      interval = RepeatInterval.weekly;
    }

    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id: id,
      title: title,
      body: body,
      repeatInterval: interval,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
