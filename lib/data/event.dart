import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/temporal_state.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class Event {
  Event(this._globalEvent, final dynamic json, this.constants)
      : pages = parseList(
            json['pages'], (dynamic p) => PageData.parse(p, constants)),
        popupMenuPages = parseList(
            json['popupMenuPages'], (dynamic p) => PageData.parse(p, constants));

  final GlobalEvent _globalEvent;
  final BuiltList<PageData> pages;
  final BuiltList<PageData> popupMenuPages;
  final EventConstants constants;

  String get id => _globalEvent.id;
  LText get title => _globalEvent.title;
  DateTime get startDate => _globalEvent.startDate;
  DateTime get endDate => _globalEvent.endDate;
  MaterialColor? get primarySwatch => _globalEvent.primarySwatch;
  Color? get secondaryColor => _globalEvent.secondaryColor;

  /// Whether we should color icons on a programme page for this event.
  bool get doColorIcons => _temporalState == TemporalState.present;

  /// Whether we should be able to mark items from this event as favorites.
  bool get canFavorite => _temporalState != TemporalState.past;

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
  EventConstants(final dynamic json, this._globalDefaults)
      : _levels = parseMap(json['workshopLevels'],
            (dynamic value) => WorkshopLevel._parse(value)),
        _kinds = parseMap(json['itemKinds'],
            (dynamic value) => ProgrammeItemKind._parse(value)),
        _supportsFavorites = json['supportsFavorites'] as bool?,
        _favoriteInnerColor = parseColor(json['favoriteInnerColor']),
        _favoriteOuterColor = parseColor(json['favoriteOuterColor']),
        _favoriteTooltip = LText.maybeParse(json['favoriteTooltip']),
        _notificationTimeBefore = parseDuration(json['notificationTimeBefore']),
        _favoriteSnackText = LText.maybeParse(json['favoriteSnackText']),
        _unfavoriteSnackText = LText.maybeParse(json['unfavoriteSnackText']),
        _notificationTitle = LText.maybeParse(json['notificationTitle']),
        _notificationBody = LText.maybeParse(json['notificationBody']);

  final BuiltMap<String, WorkshopLevel> _levels;
  final BuiltMap<String, ProgrammeItemKind> _kinds;
  final bool? _supportsFavorites;
  final Color? _favoriteInnerColor;
  final Color? _favoriteOuterColor;
  final LText? _favoriteTooltip;
  final Duration? _notificationTimeBefore;
  final LText? _favoriteSnackText;
  final LText? _unfavoriteSnackText;
  final LText? _notificationTitle;
  final LText? _notificationBody;
  final GlobalDefaults _globalDefaults;

  WorkshopLevel getLevel(final String? number) {
    return _levels[number] ?? const WorkshopLevel._empty();
  }

  ProgrammeItemKind getKind(final String? string) {
    return _kinds[string] ?? const ProgrammeItemKind._empty();
  }

  bool get supportsFavorites =>
      _supportsFavorites ?? _globalDefaults.supportsFavorites;

  Color get favoriteInnerColor =>
      _favoriteInnerColor ?? _globalDefaults.favoriteInnerColor;

  Color get favoriteOuterColor =>
      _favoriteOuterColor ?? _globalDefaults.favoriteOuterColor;

  LText get favoriteTooltip =>
      _favoriteTooltip ?? _globalDefaults.favoriteTooltip;

  Duration get notificationTimeBefore =>
      _notificationTimeBefore ?? _globalDefaults.notificationTimeBefore;

  LText get favoriteSnackText =>
      _favoriteSnackText ?? _globalDefaults.favoriteSnackText;

  LText get unfavoriteSnackText =>
      _unfavoriteSnackText ?? _globalDefaults.unfavoriteSnackText;

  LText get notificationTitle =>
      _notificationTitle ?? _globalDefaults.notificationTitle;

  LText get notificationBody =>
      _notificationBody ?? _globalDefaults.notificationBody;
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
