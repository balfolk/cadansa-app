import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

abstract class LText {
  factory LText.nullable(final dynamic json) {
    if (json == null) return null;
    return LText(json);
  }

  factory LText(final dynamic json) {
    if (json is String) return _StringLText(json);
    else if (json is Map<String, dynamic>) return _MapLText(json);
    else return _StringLText(json?.toString());
  }

  String get(final Locale locale);
}

class _StringLText implements LText {
  final String _string;

  const _StringLText(this._string);

  String get(final Locale locale) =>
    sprintf(_string ?? '', [locale.languageCode, locale.countryCode]);
}

class _MapLText implements LText {
  final Map<Locale, String> _strings = Map();

  _MapLText(final Map<String, dynamic> map) {
    map.forEach((l, str) {
      final localeParts = l.split('_');
      _strings[Locale(localeParts[0],
          localeParts.length == 2 ? localeParts[1] : null)] = str?.toString() ?? '';
    });
  }

  String get(final Locale locale) => _strings[locale]
      ?? _strings.entries.where((s) => s.key.languageCode == locale.languageCode).map((entry) => entry.value).firstWhere((_) => true, orElse: () => '')
      ?? _strings.values.firstWhere((_) => true, orElse: () => '');
}

toDateTime(final dynamic json) {
  num milliseconds;
  if (json is String) {
    milliseconds = num.parse(json);
  } else {
    milliseconds = json as num;
  }
  return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt());
}

toTimeOfDay(final dynamic json) {
  if (json == null || json.isEmpty) return null;
  final parts = (json as String).split(':');
  return TimeOfDay(hour: num.parse(parts[0]).toInt(), minute: num.parse(parts[1]).toInt());
}
