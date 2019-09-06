import 'package:cadansa_app/data/parse_utils.dart';

class GlobalConfiguration {
  Map<String, WorkshopLevel> _levels;
  Map<String, ProgrammeItemKind> _kinds;

  GlobalConfiguration(final dynamic json) {
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

  WorkshopLevel._(final dynamic json) : _name = LText(json);
  WorkshopLevel.empty() : _name = LText(null);

  LText get name => _name;
}

class ProgrammeItemKind {
  final LText _name;

  ProgrammeItemKind._(final dynamic json) : _name = LText(json);
  ProgrammeItemKind.empty() : _name = LText(null);

  LText get name => _name;
}
