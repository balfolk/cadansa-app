import 'dart:async';
import 'dart:io';

import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/app.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  _main();
}

Future<void> _main() async {
  tz.initializeTimeZones(); // required by flutter_local_notifications
  WidgetsFlutterBinding.ensureInitialized();

  // Trust the old Let's Encrypt cert to avoid errors in older devices
  final data =
      await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());

  final sharedPrefs = await SharedPreferences.getInstance();
  await dotenv.load();
  final packageInfo = await PackageInfo.fromPlatform();

  final primarySwatchColor = sharedPrefs.getInt(PRIMARY_SWATCH_COLOR_KEY);
  final primarySwatch = getPrimarySwatch(primarySwatchColor) ?? DEFAULT_PRIMARY_SWATCH;
  final secondaryColorValue = sharedPrefs.getInt(SECONDARY_COLOR_KEY);
  final secondaryColor =
      secondaryColorValue != null ? Color(secondaryColorValue) : null;

  final localeList = sharedPrefs.getStringList(LOCALE_KEY) ?? [];
  Locale? locale;
  if (localeList.isNotEmpty) {
    locale = Locale.fromSubtags(
      languageCode: localeList[0],
      scriptCode: localeList.length >= 2 ? localeList[1] : null,
      countryCode: localeList.length >= 3 ? localeList[2] : null,
    );
  } else {
    await sharedPrefs.remove(LOCALE_KEY);
  }

  runApp(CaDansaApp(
    initialLocale: locale,
    initialPrimarySwatch: primarySwatch,
    initialSecondaryColor: secondaryColor,
    sharedPreferences: sharedPrefs,
    env: dotenv.env,
    packageInfo: packageInfo,
  ));
}
