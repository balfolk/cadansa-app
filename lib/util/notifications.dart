import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
var _hasProcessedInitialNotification = false;

const _requestAlert = true, _requestBadge = false, _requestSound = true;

Future<void> initializeNotifications({
  required final BuildContext context,
  required final Future<void> Function(String?) onSelectNotification,
}) async {
  final d = DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  final initializationSettings = InitializationSettings(
    android: const AndroidInitializationSettings('@drawable/notification'),
    iOS: d,
    macOS: d,
  );
  await _flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (final details) =>
        onSelectNotification(details.payload),
  );
}

Future<String?> getInitialNotification() async {
  if (_hasProcessedInitialNotification) return null;
  _hasProcessedInitialNotification = true;

  final notificationAppLaunchDetails =
      await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails == null ||
      !notificationAppLaunchDetails.didNotificationLaunchApp ||
      (notificationAppLaunchDetails.notificationResponse?.payload?.isEmpty ??
          true)) {
    return null;
  }

  return notificationAppLaunchDetails.notificationResponse?.payload;
}

Future<bool> addNotification({
  required final String id,
  required final String eventId,
  required final String title,
  final String? body,
  required final String payload,
  final Color? color,
  required final DateTime when,
  final DateTime? whenStart,
}) async {
  final hasPermission = await _requestPermissions();
  if (!hasPermission || when.isBefore(DateTime.now())) return false;

  final platformChannelSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      eventId,
      eventId,
      groupKey: eventId,
      color: color,
      when: whenStart?.millisecondsSinceEpoch,
      showWhen: whenStart != null,
      largeIcon: const DrawableResourceAndroidBitmap('notification_large'),
    ),
    iOS: DarwinNotificationDetails(threadIdentifier: eventId),
  );
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    _stringToNotificationId(id),
    title,
    body,
    tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, when.millisecondsSinceEpoch),
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exact,
    payload: payload,
  );
  return true;
}

Future<void> cancelNotification({required final String id}) async {
  await _flutterLocalNotificationsPlugin.cancel(_stringToNotificationId(id));
}

Future<bool> _requestPermissions() async {
  if (Platform.isIOS) {
    return await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: _requestAlert,
      badge: _requestBadge,
      sound: _requestSound,
    ) ?? false;
  } else if (Platform.isMacOS) {
    return await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: _requestAlert,
      badge: _requestBadge,
      sound: _requestSound,
    ) ?? false;
  } else if (Platform.isAndroid) {
    final androidPermissions =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return (await androidPermissions?.requestNotificationsPermission() ?? false)
        && (await androidPermissions?.requestExactAlarmsPermission() ?? false);
  }
  return true;
}

int _stringToNotificationId(final String string) {
  return string.hashCode;
}
