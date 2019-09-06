import 'dart:ui';

import 'package:flutter/material.dart';

class LText {
  static const Locale _DEFAULT_LOCALE = const Locale('en', 'GB');

  factory LText(final dynamic json) {
    if (json is String) return LText._fromString(json);
    else if (json is Map<String, dynamic>) return LText._fromMap(json);
    else return LText._fromString(json?.toString());
  }

  LText._fromString(final String string) {
    _strings[_DEFAULT_LOCALE] = string ?? '';
  }

  LText._fromMap(final Map<String, dynamic> strings) {
    strings.forEach((l, str) {
      final localeParts = l.split('_');
      _strings[Locale(localeParts[0],
          localeParts.length == 2 ? localeParts[1] : null)] = str.toString();
    });
  }

  final Map<Locale, String> _strings = Map();

  String get(final Locale locale) {
    return _strings[locale ?? _DEFAULT_LOCALE]
        ?? _strings[_DEFAULT_LOCALE]
        ?? _strings.values.firstWhere((_) => true, orElse: () => '');
  }
}

toDateTime(final dynamic json) =>
    DateTime.fromMillisecondsSinceEpoch(json as int);

toTimeOfDay(final dynamic json) {
  final parts = (json as String).split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
