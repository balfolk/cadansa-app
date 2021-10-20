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
  required Future<void> Function(String?) onSelectNotification,
}) async {
  Future<void> _onDidReceiveLocalNotification(final int id, final String? title,
      final String? body, final String? payload) async {
    final isOk = await showDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title ?? ''),
        content: Text(body ?? ''),
        actions: [
          CupertinoDialogAction(
            onPressed: Navigator.of(context, rootNavigator: true).pop,
            isDefaultAction: true,
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (isOk ?? false) {
      await onSelectNotification(payload);
    }
  }

  final initializationSettings = InitializationSettings(
    android: const AndroidInitializationSettings('@drawable/notification'),
    iOS: IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    ),
    macOS: const MacOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await _flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: onSelectNotification,
  );
}

Future<String?> getInitialNotification() async {
  if (_hasProcessedInitialNotification) return null;
  _hasProcessedInitialNotification = true;

  final notificationAppLaunchDetails =
      await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails == null ||
      !notificationAppLaunchDetails.didNotificationLaunchApp ||
      (notificationAppLaunchDetails.payload?.isEmpty ?? true)) {
    return null;
  }

  return notificationAppLaunchDetails.payload;
}

Future<bool> addNotification({
  required String id,
  required String eventId,
  required String title,
  String? body,
  required String payload,
  Color? color,
  required DateTime when,
  DateTime? whenStart,
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
    iOS: IOSNotificationDetails(threadIdentifier: eventId),
  );
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    _stringToNotificationId(id),
    title,
    body,
    tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, when.millisecondsSinceEpoch),
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    androidAllowWhileIdle: false,
    payload: payload,
  );
  return true;
}

Future<void> cancelNotification({required String id}) async {
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
  }
  return true;
}

int _stringToNotificationId(final String string) {
  return string.hashCode;
}
