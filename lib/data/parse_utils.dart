import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:cadansa_app/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:sprintf/sprintf.dart';

@immutable
abstract class LText {
  factory LText(final dynamic json) {
    if (json == null ||
        ((json is String || json is Iterable || json is Map) && json.isEmpty as bool)) {
      return const LText.empty();
    } else if (json is String) {
      return _StringLText(json);
    } else if (json is Map) {
      return _MapLText(json);
    } else {
      return _StringLText(json.toString());
    }
  }

  @literal
  const factory LText.empty() = _EmptyLText;

  String get(final Locale locale);
}

@immutable
class _EmptyLText implements LText {
  @literal
  const _EmptyLText();

  @override
  String get(final Locale locale) => '';
}

@immutable
class _StringLText implements LText {
  final String _string;

  @literal
  const _StringLText(this._string);

  @override
  String get(final Locale locale) =>
    sprintf(_string, [locale.languageCode, locale.countryCode ?? '']);
}

@immutable
class _MapLText implements LText {
  final BuiltMap<Locale, String> _strings;

  _MapLText(final Map<dynamic, dynamic> map)
      : _strings = BuiltMap.build((builder) => map.forEach((dynamic l, dynamic str) {
    final localeParts = (l?.toString() ?? '').split('_');
    builder[Locale(localeParts[0], localeParts.elementAtOrNull(1))] =
        str?.toString() ?? '';
  }));

  @override
  String get(final Locale locale) => _strings[locale]
      ?? _strings.entries
          .where((s) => s.key.languageCode == locale.languageCode)
          .map((entry) => entry.value)
          .firstOrNull
      ?? _strings.values.firstOrNull
      ?? '';
}

BuiltList<T> parseList<T>(final dynamic json, final T Function(dynamic) parseItem) {
  return BuiltList.of(
      (json as Iterable?)?.map<T>(parseItem) ?? const Iterable.empty());
}

BuiltMap<String, T> parseMap<T>(final dynamic json, final T Function(dynamic) parseItem) {
  return BuiltMap.build((builder) => (json as Map<String, dynamic>?)
      ?.forEach((key, dynamic value) => builder[key] = parseItem(value)));
}

DateTime? parseDateTime(final dynamic json) {
  num? milliseconds;
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

TimeOfDay? parseTimeOfDay(final dynamic json) {
  if (json == null || (json is String && json.isEmpty)) {
    return null;
  } else if (json is! String || !json.contains(':')) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  final parts = json.split(':');
  if (parts.length != 2) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  final hour = num.tryParse(parts[0])?.toInt(),
      minute = num.tryParse(parts[1])?.toInt();
  if (hour == null || hour < 0 || hour >= TimeOfDay.hoursPerDay
      || minute == null || minute < 0 || minute >= TimeOfDay.minutesPerHour) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  return TimeOfDay(hour: hour, minute: minute);
}

Offset parseOffset(final dynamic json) {
  return Offset((json[0] as num).toDouble(), (json[1] as num).toDouble());
}

Locale parseLocale(final dynamic json) {
  return Locale(
      json[0] as String, (json as Iterable).elementAtOrNull(1) as String?);
}
