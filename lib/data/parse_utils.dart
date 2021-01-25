import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

abstract class LText {
  factory LText.nullable(final dynamic json) {
    if (json == null) return null;
    return LText(json);
  }

  factory LText(final dynamic json) {
    if (json is String) {
      return _StringLText(json);
    } else if (json is Map) {
      return _MapLText(json);
    } else {
      return _StringLText(json?.toString());
    }
  }

  String get(final Locale locale);
}

class _StringLText implements LText {
  final String _string;

  const _StringLText(this._string);

  @override
  String get(final Locale locale) =>
    sprintf(_string ?? '', [locale.languageCode, locale.countryCode ?? '']);
}

class _MapLText implements LText {
  final Map<Locale, String> _strings = {};

  _MapLText(final Map map) {
    map.forEach((l, str) {
      final localeParts = (l?.toString() ?? '').split('_');
      _strings[Locale(localeParts[0],
          localeParts.length == 2 ? localeParts[1] : null)] = str?.toString() ?? '';
    });
  }

  @override
  String get(final Locale locale) => _strings[locale]
      ?? _strings.entries.where((s) => s.key.languageCode == locale.languageCode).map((entry) => entry.value).firstWhere((_) => true, orElse: () => null)
      ?? _strings.values.firstWhere((_) => true, orElse: () => '');
}

DateTime toDateTime(final dynamic json) {
  num milliseconds;
  if (json == null || (json is String && json.isEmpty)) {
    return null;
  } else if (json is String) {
    milliseconds = num.tryParse(json);
  } else if (json is num) {
    milliseconds = json;
  }

  if (milliseconds == null) {
    throw ArgumentError.value(json, 'json', 'does not represent a DateTime');
  }

  return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt());
}

TimeOfDay toTimeOfDay(final dynamic json) {
  if (json == null || (json is String && json.isEmpty)) {
    return null;
  } else if (json is! String || !json.contains(':')) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  final parts = json.split(':');
  if (parts.length != 2) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  final hour = num.tryParse(parts[0])?.toInt(), minute = num.parse(parts[1])?.toInt();
  if (hour == null || hour < 0 || hour >= TimeOfDay.hoursPerDay
      || minute == null || minute < 0 || minute >= TimeOfDay.minutesPerHour) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  return TimeOfDay(hour: hour, minute: minute);
}
