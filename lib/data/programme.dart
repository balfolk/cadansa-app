import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class Programme {
  const Programme._(
    this._days,
    this._constants,
    this._supportsFavorites,
    this._favoriteInnerColor,
    this._favoriteOuterColor,
    this._favoriteTooltip,
  );

  Programme.parse(final dynamic json, final EventConstants constants)
      : this._(
    parseList(json['days'], (dynamic d) => ProgrammeDay.parse(d, constants)),
    constants,
    json['supportsFavorites'] as bool?,
    parseColor(json['favoriteInnerColor']),
    parseColor(json['favoriteOuterColor']),
    LText.maybeParse(json['favoriteTooltip']),
  );

  final BuiltList<ProgrammeDay> _days;
  final EventConstants _constants;
  final bool? _supportsFavorites;
  final Color? _favoriteInnerColor;
  final Color? _favoriteOuterColor;
  final LText? _favoriteTooltip;

  BuiltList<ProgrammeDay> get days => _days;

  /// Whether we can mark items as favorite on a programme page for this event.
  bool get supportsFavorites =>
      _supportsFavorites ?? _constants.supportsFavorites;

  Color get favoriteInnerColor =>
      _favoriteInnerColor ?? _constants.favoriteInnerColor;

  Color get favoriteOuterColor =>
      _favoriteOuterColor ?? _constants.favoriteOuterColor;

  LText get favoriteTooltip =>
      _favoriteTooltip ?? _constants.favoriteTooltip;
}

@immutable
class ProgrammeDay {
  const ProgrammeDay._(this._name, this._startsOn, this._items);

  ProgrammeDay.parse(final dynamic json, final EventConstants constants)
      : this._(
      LText(json['name']),
      parseDateTime(json['startsOn']),
      parseList(json['items'],
              (dynamic b) => ProgrammeItem.parse(b, constants)));

  final LText _name;
  final DateTime? _startsOn;
  final BuiltList<ProgrammeItem> _items;

  LText get name => _name;

  DateTime? get startsOn => _startsOn;

  BuiltList<ProgrammeItem> get items => _items;

  DateTimeRange? rangeOfItem(final ProgrammeItem item) {
    // Anything with hours smaller than this number is in the "wee hours" and takes place on the preceding day
    const HOUR_NIGHT_CUTOFF = 6;

    final startsOn = this.startsOn;
    if (startsOn == null) {
      return null;
    }

    final itemStartTime = item.startTime;
    final startDay = DateTime(startsOn.year, startsOn.month, startsOn.day);
    final startMoment = startDay.add(Duration(
        days: itemStartTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: itemStartTime.hour,
        minutes: itemStartTime.minute));
    final itemEndTime = item.endTime;
    final endMoment = itemEndTime != null
        ? startDay.add(Duration(
            days: itemEndTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
            hours: itemEndTime.hour,
            minutes: itemEndTime.minute))
        // Default to the last moment of this day
        : startDay.add(const Duration(days: 1, hours: HOUR_NIGHT_CUTOFF));
    return DateTimeRange(start: startMoment, end: endMoment);
  }
}

@immutable
class ProgrammeItem {
  const ProgrammeItem._(
    this._id,
    this._name,
    this._startTime,
    this._endTime,
    this._location,
    this._countries,
    this._teacher,
    this._level,
    this._kind,
    this._description,
    this._website,
    this._canFavorite,
  );

  ProgrammeItem.parse(final dynamic json, final EventConstants constants)
      : this._(
    json['id'] as String?,
    LText(json['name']),
    parseTimeOfDay(json['startTime'])!,
    parseTimeOfDay(json['endTime']),
    json['location'] != null ? Location._parse(json['location']) : null,
    parseList(json['countries'], (dynamic c) => c as String),
    LText(json['teacher']),
    constants.getLevel(json['level']?.toString()),
    constants.getKind(json['kind']?.toString()),
    LText(json['description']),
    Website._parse(json['website']),
    json['canFavorite'] as bool? ?? true,
  );

  final String? _id;
  final LText _name;
  final TimeOfDay _startTime;
  final TimeOfDay? _endTime;
  final Location? _location;
  final BuiltList<String> _countries;
  final LText _teacher;
  final WorkshopLevel _level;
  final ProgrammeItemKind _kind;
  final LText _description;
  final Website _website;
  final bool _canFavorite;

  String? get id => _id;

  LText get name => _name;

  TimeOfDay get startTime => _startTime;

  TimeOfDay? get endTime => _endTime;

  Location? get location => _location;

  BuiltList<String> get countries => _countries;

  LText get teacher => _teacher;

  WorkshopLevel get level => _level;

  ProgrammeItemKind get kind => _kind;

  LText get description => _description;

  Website get website => _website;

  bool get canFavorite => _canFavorite && id != null;
}

@immutable
class Location {
  const Location._(this.title, this.action);

  factory Location._parse(final dynamic json) => Location._(
    LText(json['title']),
    json['action'] as String?,
  );

  final LText title;
  final String? action;
}

@immutable
class Website {
  factory Website._parse(final dynamic json) {
    if (json == null) return const Website._empty();
    return Website._parseObject(json);
  }

  Website._parseObject(final dynamic json)
      : _url = LText(json['url']),
        _icon = json['icon'] as String?,
        _text = LText(json['text']);

  @literal
  const Website._empty()
      : _url = null,
        _icon = null,
        _text = null;

  final LText? _url;
  final String? _icon;
  final LText? _text;

  LText? get text => _text;

  String? get icon => _icon;

  LText? get url => _url;
}
