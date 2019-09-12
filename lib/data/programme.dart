import 'package:cadansa_app/data/global_conf.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

class Programme {
  final List<ProgrammeDay> _days;

  Programme._(this._days);

  Programme.parse(final dynamic json, final GlobalConfiguration configuration)
      : this._((json as List)
            .map((d) => ProgrammeDay.parse(d, configuration))
            .toList(growable: false));

  List<ProgrammeDay> get days => List.unmodifiable(_days);
}

class ProgrammeDay {
  final LText _name;
  final DateTime _startsOn;
  final List<ProgrammeItem> _items;

  ProgrammeDay._(this._name, this._startsOn, this._items);

  ProgrammeDay.parse(final dynamic json, final GlobalConfiguration configuration)
      : this._(
            LText(json['name']),
            toDateTime(json['startsOn']),
            (json['items'] as List)
                .map((b) => ProgrammeItem.parse(b, configuration))
                .toList(growable: false));

  LText get name => _name;

  DateTime get startsOn => _startsOn;

  List<ProgrammeItem> get items => List.unmodifiable(_items);
}

class ProgrammeItem {
  final LText _name;
  final TimeOfDay _startTime, _endTime;
  final LText _location;
  final List<String> _countries;
  final LText _teacher;
  final WorkshopLevel _level;
  final ProgrammeItemKind _kind;
  final LText _description;
  final String _website;

  ProgrammeItem._(this._name, this._startTime, this._endTime, this._location,
      this._countries, this._teacher, this._level,
      this._kind, this._description, this._website);

  ProgrammeItem.parse(final dynamic json, final GlobalConfiguration configuration)
      : this._(
            LText(json['name']),
            toTimeOfDay(json['startTime']),
            toTimeOfDay(json['endTime']),
            LText(json['location']),
            (json['countries'] as List)?.toList(growable: false)?.cast(),
            LText(json['teacher']),
            configuration.getLevel(json['level']?.toString()),
            configuration.getKind(json['kind']?.toString()),
            LText.nullable(json['description']),
            json['website']);

  LText get name => _name;

  TimeOfDay get startTime => _startTime;

  TimeOfDay get endTime => _endTime;

  LText get location => _location;

  List<String> get countries => _countries != null ? List.unmodifiable(_countries) : [];

  LText get teacher => _teacher;

  WorkshopLevel get level => _level ?? WorkshopLevel.empty();

  ProgrammeItemKind get kind => _kind ?? ProgrammeItemKind.empty();

  LText get description => _description;

  String get website => _website;
}

