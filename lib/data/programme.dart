import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

class Programme {
  final List<ProgrammeDay> _days;

  Programme._(this._days);

  Programme.parse(final dynamic json)
      : this._((json as List)
            .map((d) => ProgrammeDay.parse(d))
            .toList(growable: false));

  List<ProgrammeDay> get days => List.unmodifiable(_days);
}

class ProgrammeDay {
  final LText _name;
  final DateTime _startsOn;
  final List<ProgrammeItem> _items;

  ProgrammeDay._(this._name, this._startsOn, this._items);

  ProgrammeDay.parse(final dynamic json)
      : this._(
            LText(json['name']),
            toDateTime(json['startsOn']),
            (json['items'] as List)
                .map((b) => ProgrammeItem.parse(b))
                .toList(growable: false));

  LText get name => _name;

  DateTime get startsOn => _startsOn;

  List<ProgrammeItem> get items => List.unmodifiable(_items);
}

class ProgrammeItem {
  final String _name;
  final TimeOfDay _startTime, _endTime;
  final List<String> _countries;
  final LText _description;
  final String _website;

  ProgrammeItem._(this._name, this._startTime, this._endTime, this._countries,
      this._description, this._website);

  ProgrammeItem.parse(final dynamic json)
      : this._(
            json['name'],
            toTimeOfDay(json['startTime']),
            toTimeOfDay(json['endTime']),
            (json['countries'] as List).toList(growable: false).cast(),
            LText(json['description']),
            json['website']);

  String get name => _name;

  TimeOfDay get startTime => _startTime;

  TimeOfDay get endTime => _endTime;

  List<String> get countries => List.unmodifiable(_countries);

  LText get description => _description;

  String get website => _website;
}
