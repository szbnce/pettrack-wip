import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
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
