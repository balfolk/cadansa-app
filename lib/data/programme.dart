import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

class Programme {
  List<ProgrammeDay> _days;

  Programme._(this._days);

  Programme.parse(final dynamic json)
      : this._((json as List)
            .map((d) => ProgrammeDay.parse(d))
            .toList(growable: false));

  List<ProgrammeDay> get days => List.unmodifiable(_days);
}

class ProgrammeDay {
  LText _name;
  DateTime _startsOn;
  List<Band> _bands;

  ProgrammeDay._(this._name, this._startsOn, this._bands);

  ProgrammeDay.parse(final dynamic json)
      : this._(
            LText(json['name']),
            toDateTime(json['startsOn']),
            (json['bands'] as List)
                .map((b) => Band.parse(b))
                .toList(growable: false));

  LText get name => _name;

  DateTime get startsOn => _startsOn;

  List<Band> get bands => List.unmodifiable(_bands);
}

class Band {
  String _name;
  TimeOfDay _startTime, _endTime;
  List<String> _countries;
  LText _description;
  String _website;

  Band._(this._name, this._startTime, this._endTime, this._countries,
      this._description, this._website);

  Band.parse(final dynamic json)
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
