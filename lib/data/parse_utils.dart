import 'dart:ui';

import 'package:flutter/material.dart';

class LText {
  static Locale _DEFAULT_LOCALE = Locale('en', 'GB');

  LText(final dynamic json) : this.fromMap(json as Map<String, dynamic>);

  LText.fromMap(final Map<String, dynamic> strings) {
    strings.forEach((l, str) {
      final localeParts = l.split('_');
      _strings[Locale(localeParts[0],
          localeParts.length == 2 ? localeParts[1] : null)] = str.toString();
    });
  }

  final Map<Locale, String> _strings = Map();

  String get(final Locale locale) {
    return _strings[locale ?? _DEFAULT_LOCALE] ??
        _strings[_DEFAULT_LOCALE] ??
        '';
  }
}

toDateTime(final dynamic json) =>
    DateTime.fromMillisecondsSinceEpoch(json as int);

toTimeOfDay(final dynamic json) {
  final parts = (json as String).split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
