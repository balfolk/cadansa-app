import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

class Programme {
  final List<ProgrammeDay> _days;

  Programme._(this._days);

  Programme.parse(final dynamic json, final EventConstants constants)
      : this._((json as List)
            .map((d) => ProgrammeDay.parse(d, constants))
            .toList(growable: false));

  List<ProgrammeDay> get days => List.unmodifiable(_days);
}

class ProgrammeDay {
  final LText _name;
  final DateTime _startsOn;
  final List<ProgrammeItem> _items;

  ProgrammeDay._(this._name, this._startsOn, this._items);

  ProgrammeDay.parse(final dynamic json, final EventConstants constants)
      : this._(
            LText(json['name']),
            toDateTime(json['startsOn']),
            (json['items'] as List)
                .map((b) => ProgrammeItem.parse(b, constants))
                .toList(growable: false));

  LText get name => _name;

  DateTime get startsOn => _startsOn;

  List<ProgrammeItem> get items => List.unmodifiable(_items);
}

class ProgrammeItem {
  final LText _name;
  final TimeOfDay _startTime, _endTime;
  final Location _location;
  final List<String> _countries;
  final LText _teacher;
  final WorkshopLevel _level;
  final ProgrammeItemKind _kind;
  final LText _description;
  final Website _website;

  ProgrammeItem._(this._name, this._startTime, this._endTime, this._location,
      this._countries, this._teacher, this._level,
      this._kind, this._description, this._website);

  ProgrammeItem.parse(final dynamic json, final EventConstants constants)
      : this._(
            LText(json['name']),
            toTimeOfDay(json['startTime']),
            toTimeOfDay(json['endTime']),
            Location.parse(json['location']),
            (json['countries'] as List)?.toList(growable: false)?.cast(),
            LText(json['teacher']),
            constants.getLevel(json['level']?.toString()),
            constants.getKind(json['kind']?.toString()),
            LText.nullable(json['description']),
            Website.parse(json['website']));

  LText get name => _name;

  TimeOfDay get startTime => _startTime;

  TimeOfDay get endTime => _endTime;

  Location get location => _location;

  List<String> get countries => _countries != null ? List.unmodifiable(_countries) : [];

  LText get teacher => _teacher;

  WorkshopLevel get level => _level ?? WorkshopLevel.empty();

  ProgrammeItemKind get kind => _kind ?? ProgrammeItemKind.empty();

  LText get description => _description;

  Website get website => _website;
}

class Location {
  final LText title;
  final String action;

  Location._(this.title, this.action);

  factory Location.parse(final dynamic json) => json != null ? Location._(
    LText(json['title'] ?? json),
    json['action'],
  ) : null;
}

class Website {
  final LText _url;
  final String _icon;
  final LText _text;

  factory Website.parse(final dynamic json) {
    if (json == null) return Website._empty();
    if (json is String) return Website._parseUrl(json);
    return Website._parseObject(json);
  }

  Website._parseObject(final dynamic json)
      : _url = LText(json['url']),
        _icon = json['icon'],
        _text = LText(json['text']);

  @deprecated
  Website._parseUrl(final String url)
      : _url = LText(url),
        _icon = 'web',
        _text = LText('Website');

  Website._empty()
      : _url = null,
        _icon = null,
        _text = null;

  LText get text => _text;

  String get icon => _icon;

  LText get url => _url;
}
