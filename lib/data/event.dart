import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';

class Event {
  final LText title;
  final List<PageData> pages;

  Event(this.title, final dynamic json)
      : pages = List.unmodifiable(json['pages'].map((p) => PageData.parse(p, EventConstants(json))));
}

class EventConstants {
  Map<String, WorkshopLevel> _levels;
  Map<String, ProgrammeItemKind> _kinds;

  EventConstants(final dynamic json) {
    _levels = (json['workshopLevels'] as Map).map((key, value) => MapEntry(key, WorkshopLevel._(value)));
    _kinds = (json['itemKinds'] as Map).map((key, value) => MapEntry(key, ProgrammeItemKind._(value)));
  }

  WorkshopLevel getLevel(final String number) {
    return _levels[number];
  }

  ProgrammeItemKind getKind(final String string) {
    return _kinds[string];
  }
}

class WorkshopLevel {
  final LText _name;
  final String _icon;

  WorkshopLevel._(final dynamic json)
      : _name = LText(json['name']),
        _icon = json['icon'];

  WorkshopLevel.empty()
      : _name = LText(null),
        _icon = null;

  LText get name => _name;

  String get icon => _icon;
}

enum ProgrammeItemKindShowIcon { always, during, unexpanded, never }
ProgrammeItemKindShowIcon _parseKindShown(final String string) {
  return const {
    'always': ProgrammeItemKindShowIcon.always,
    'during': ProgrammeItemKindShowIcon.during,
    'unexpanded': ProgrammeItemKindShowIcon.unexpanded,
    'never': ProgrammeItemKindShowIcon.never
  }[string];
}

class ProgrammeItemKind {
  final LText _name;
  final String _icon;
  final ProgrammeItemKindShowIcon _showIcon;

  ProgrammeItemKind._(final dynamic json)
      : _name = LText(json['name']),
        _icon = json['icon'],
        _showIcon = _parseKindShown(json['showIcon']);

  ProgrammeItemKind.empty()
      : _name = LText(null),
        _icon = null,
        _showIcon = null;

  LText get name => _name;

  String get icon => _icon;

  ProgrammeItemKindShowIcon get showIcon => _showIcon ?? ProgrammeItemKindShowIcon.never;
}
