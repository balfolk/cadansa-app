import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/util/flutter_util.dart';
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

  @factory
  static LText? maybeParse(final dynamic json) {
    if (json == null) return null;
    return LText(json);
  }

  String get(final Locale locale);

  @mustBeOverridden
  @override
  String toString();
}

@immutable
class _EmptyLText implements LText {
  @literal
  const _EmptyLText();

  @override
  String get(final Locale locale) => toString();

  @override
  String toString() => '';
}

@immutable
class _StringLText implements LText {
  @literal
  const _StringLText(this._string);

  final String _string;

  @override
  String get(final Locale locale) =>
      sprintf(_string, [locale.languageCode, locale.countryCode ?? '']);

  @override
  String toString() => _string;
}

@immutable
class _MapLText implements LText {
  _MapLText(final Map<dynamic, dynamic> map)
      : _strings = BuiltMap.build((builder) => map.forEach((dynamic l, dynamic str) {
    final localeParts = (l?.toString() ?? '').split('_');
    builder[Locale(localeParts[0], localeParts.elementAtOrNull(1))] =
        str?.toString() ?? '';
  }));

  final BuiltMap<Locale, String> _strings;

  @override
  String get(final Locale locale) =>
      _strings[locale] ??
      _strings.entries
          .where((s) => s.key.languageCode == locale.languageCode)
          .map((entry) => entry.value)
          .firstOrNull ??
      toString();

  @override
  String toString() => _strings.values.firstOrNull ?? '';
}

BuiltList<T> parseList<T>(final dynamic json, final T Function(dynamic) parseItem) {
  return BuiltList.of(
      (json as Iterable?)?.map<T>(parseItem) ?? const Iterable.empty());
}

BuiltMap<String, T> parseMap<T>(final dynamic json, final T Function(dynamic) parseItem) {
  return BuiltMap.build((builder) => (json as Map<String, dynamic>?)
      ?.forEach((key, dynamic value) => builder[key] = parseItem(value)));
}

num? parseNum(final dynamic json) {
  num? number;
  if (json is num) {
    number = json;
  } else if (json is String) {
    number = num.tryParse(json);
  }
  return number;
}

DateTime? parseDateTime(final dynamic json) {
  if (json == null || (json is String && json.isEmpty)) {
    return null;
  }

  final milliseconds = parseNum(json);
  if (milliseconds == null) {
    throw ArgumentError.value(json, 'json', 'does not represent a DateTime');
  }

  return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt());
}

DateTime parseDate(final dynamic json) {
  if (json is String) {
    return DateTime.parse(json);
  }

  throw ArgumentError.value(json, 'json', 'does not represent a DateTime');
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

  final hour = parseNum(parts[0])?.toInt(),
      minute = parseNum(parts[1])?.toInt();
  if (hour == null || hour < 0 || hour >= TimeOfDay.hoursPerDay
      || minute == null || minute < 0 || minute >= TimeOfDay.minutesPerHour) {
    throw ArgumentError.value(json, 'json', 'does not represent a TimeOfDay');
  }

  return TimeOfDay(hour: hour, minute: minute);
}

Duration? parseDuration(final dynamic json) {
  final milliseconds = parseNum(json);
  if (milliseconds == null) {
    return null;
  }

  return Duration(milliseconds: milliseconds.toInt());
}

Offset parseOffset(final dynamic json) {
  return Offset(parseNum(json[0])!.toDouble(), parseNum(json[1])!.toDouble());
}

Locale parseLocale(final dynamic json) {
  return Locale(
      json[0] as String, (json as Iterable).elementAtOrNull(1) as String?);
}

Color? parseColor(final dynamic json) {
  if (json == null || (json is Iterable && json.length < 3)) return null;
  return Color.fromRGBO(
    parseNum(json[0])!.toInt(),
    parseNum(json[1])!.toInt(),
    parseNum(json[2])!.toInt(),
    parseNum((json as Iterable).elementAtOrNull(3))?.toDouble() ?? 1.0,
  );
}

MaterialColor? parseMaterialColor(final dynamic json) {
  final color = parseColor(json);
  if (color == null) return null;
  return createMaterialColor(color);
}
