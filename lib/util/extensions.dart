import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension MyIterable<T> on Iterable<T> {
  T? elementAtOrNull(final int? index) {
    if (index != null && index >= 0 && index < length) {
      return elementAt(index);
    }
    return null;
  }
}

Brightness _getOtherBrightness(final Brightness brightness) {
  switch (brightness) {
    case Brightness.dark: return Brightness.light;
    case Brightness.light: return Brightness.dark;
  }
}

extension MyThemeData on ThemeData {
  SystemUiOverlayStyle get systemUiOverlayStyle {
    final primaryColorBrightness =
        ThemeData.estimateBrightnessForColor(primaryColor);
    return SystemUiOverlayStyle(
      statusBarIconBrightness: _getOtherBrightness(primaryColorBrightness),
      statusBarBrightness: primaryColorBrightness,
    );
  }
}
