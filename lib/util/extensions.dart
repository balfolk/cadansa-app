import 'package:flutter/material.dart';

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
  Brightness get onPrimaryBrightness =>
      _getOtherBrightness(primaryColorBrightness);
}
