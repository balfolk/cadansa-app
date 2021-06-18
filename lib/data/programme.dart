import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class Programme {
  const Programme._(this._days);

  Programme.parse(final dynamic json, final EventConstants constants)
      : this._(parseList(json['days'],
          (dynamic d) => ProgrammeDay.parse(d, constants)));

  final BuiltList<ProgrammeDay> _days;

  BuiltList<ProgrammeDay> get days => _days;
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
}

@immutable
class ProgrammeItem {
  const ProgrammeItem._(
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
      );

  ProgrammeItem.parse(final dynamic json, final EventConstants constants)
      : this._(
    LText(json['name']),
    parseTimeOfDay(json['startTime']),
    parseTimeOfDay(json['endTime']),
    json['location'] != null ? Location._parse(json['location']) : null,
    parseList(json['countries'], (dynamic c) => c as String),
    LText(json['teacher']),
    constants.getLevel(json['level']?.toString()),
    constants.getKind(json['kind']?.toString()),
    LText(json['description']),
    Website._parse(json['website']),
  );

  final LText _name;
  final TimeOfDay? _startTime, _endTime;
  final Location? _location;
  final BuiltList<String> _countries;
  final LText _teacher;
  final WorkshopLevel _level;
  final ProgrammeItemKind _kind;
  final LText _description;
  final Website _website;

  LText get name => _name;

  TimeOfDay? get startTime => _startTime;

  TimeOfDay? get endTime => _endTime;

  Location? get location => _location;

  BuiltList<String> get countries => _countries;

  LText get teacher => _teacher;

  WorkshopLevel get level => _level;

  ProgrammeItemKind get kind => _kind;

  LText get description => _description;

  Website get website => _website;
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
