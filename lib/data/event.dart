import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/temporal_state.dart';
import 'package:meta/meta.dart';

@immutable
class Event {
  Event(this._globalEvent, final dynamic json)
      : pages = parseList(json['pages'],
          (dynamic p) => PageData.parse(p, EventConstants(json)));

  final GlobalEvent _globalEvent;
  final BuiltList<PageData> pages;

  LText get title => _globalEvent.title;
  DateTime get startDate => _globalEvent.startDate;
  DateTime get endDate => _globalEvent.endDate;

  /// Whether we should color icons on a programme page for this event.
  bool get doColorIcons => _temporalState == TemporalState.present;

  TemporalState get _temporalState {
    final now = DateTime.now();
    final hasStarted = now.isAfter(startDate);
    final hasEnded = now.isAfter(endDate);
    if (hasEnded) {
      return TemporalState.past;
    } else if (hasStarted) {
      return TemporalState.present;
    } else {
      return TemporalState.future;
    }
  }
}

@immutable
class EventConstants {
  EventConstants(final dynamic json)
      : _levels = parseMap(json['workshopLevels'],
            (dynamic value) => WorkshopLevel._parse(value)),
        _kinds = parseMap(json['itemKinds'],
            (dynamic value) => ProgrammeItemKind._parse(value));

  final BuiltMap<String, WorkshopLevel> _levels;
  final BuiltMap<String, ProgrammeItemKind> _kinds;

  WorkshopLevel getLevel(final String? number) {
    return _levels[number] ?? const WorkshopLevel._empty();
  }

  ProgrammeItemKind getKind(final String? string) {
    return _kinds[string] ?? const ProgrammeItemKind._empty();
  }
}

@immutable
class WorkshopLevel {
  WorkshopLevel._parse(final dynamic json)
      : _name = LText(json['name']),
        _icon = json['icon'] as String?;

  @literal
  const WorkshopLevel._empty()
      : _name = const LText.empty(),
        _icon = null;

  final LText _name;
  final String? _icon;

  LText get name => _name;

  String? get icon => _icon;
}

enum ProgrammeItemKindShowIcon { always, during, never }
ProgrammeItemKindShowIcon? _parseKindShown(final String? string) {
  return const {
    'always': ProgrammeItemKindShowIcon.always,
    'during': ProgrammeItemKindShowIcon.during,
    'never': ProgrammeItemKindShowIcon.never
  }[string];
}

@immutable
class ProgrammeItemKind {
  ProgrammeItemKind._parse(final dynamic json)
      : _name = LText(json['name']),
        _icon = json['icon'] as String?,
        _showIcon = _parseKindShown(json['showIcon'] as String?);

  @literal
  const ProgrammeItemKind._empty()
      : _name = const LText.empty(),
        _icon = null,
        _showIcon = null;

  final LText _name;
  final String? _icon;
  final ProgrammeItemKindShowIcon? _showIcon;

  LText get name => _name;

  String? get icon => _icon;

  ProgrammeItemKindShowIcon get showIcon => _showIcon ?? ProgrammeItemKindShowIcon.always;
}
