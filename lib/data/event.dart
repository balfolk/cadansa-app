import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:meta/meta.dart';

@immutable
class Event {
  final LText title;
  final List<PageData> pages;

  Event(this.title, final dynamic json)
      : pages = parseList(json['pages'],
          (dynamic p) => PageData.parse(p, EventConstants(json)));
}

@immutable
class EventConstants {
  final Map<String, WorkshopLevel> _levels;
  final Map<String, ProgrammeItemKind> _kinds;

  EventConstants(final dynamic json)
      : _levels = parseMap(json['workshopLevels'],
            (dynamic value) => WorkshopLevel._parse(value)),
        _kinds = parseMap(json['itemKinds'],
            (dynamic value) => ProgrammeItemKind._parse(value));

  WorkshopLevel getLevel(final String? number) {
    return _levels[number] ?? const WorkshopLevel._empty();
  }

  ProgrammeItemKind getKind(final String? string) {
    return _kinds[string] ?? const ProgrammeItemKind._empty();
  }
}

@immutable
class WorkshopLevel {
  final LText _name;
  final String? _icon;

  WorkshopLevel._parse(final dynamic json)
      : _name = LText(json['name']),
        _icon = json['icon'] as String?;

  @literal
  const WorkshopLevel._empty()
      : _name = const LText.empty(),
        _icon = null;

  LText get name => _name;

  String? get icon => _icon;
}

enum ProgrammeItemKindShowIcon { always, during, unexpanded, never }
ProgrammeItemKindShowIcon? _parseKindShown(final String? string) {
  return const {
    'always': ProgrammeItemKindShowIcon.always,
    'during': ProgrammeItemKindShowIcon.during,
    'unexpanded': ProgrammeItemKindShowIcon.unexpanded,
    'never': ProgrammeItemKindShowIcon.never
  }[string];
}

@immutable
class ProgrammeItemKind {
  final LText _name;
  final String? _icon;
  final ProgrammeItemKindShowIcon? _showIcon;

  ProgrammeItemKind._parse(final dynamic json)
      : _name = LText(json['name']),
        _icon = json['icon'] as String?,
        _showIcon = _parseKindShown(json['showIcon'] as String?);

  @literal
  const ProgrammeItemKind._empty()
      : _name = const LText.empty(),
        _icon = null,
        _showIcon = null;

  LText get name => _name;

  String? get icon => _icon;

  ProgrammeItemKindShowIcon get showIcon => _showIcon ?? ProgrammeItemKindShowIcon.never;
}
