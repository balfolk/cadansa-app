import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';

@immutable
class GlobalConfig {
  final LText title;
  final LText? logoUri;
  final BuiltList<EventsSection> sections;

  GlobalConfig(final dynamic json)
      : title = LText(json['title']),
        logoUri = LText(json['logo']),
        sections = parseList(json['eventSections'], (dynamic s) => EventsSection(s));

  late final BuiltList<GlobalEvent> allEvents = BuiltList.of(
      sections.map((s) => s.events).expand<GlobalEvent>((events) => events));
}

@immutable
class EventsSection {
  final LText title;
  final BuiltList<GlobalEvent> events;

  EventsSection(final dynamic json)
      : title = LText(json['title']),
        events = parseList(json['events'], (dynamic e) => GlobalEvent(e));
}

@immutable
class GlobalEvent {
  final LText title, subtitle;
  final String? avatarUri;
  final String configUri;
  final int? primarySwatchIndex, _accentColorIndex;
  final BuiltList<Locale>? supportedLocales;

  GlobalEvent(final dynamic json)
      : title = LText(json['title']),
        subtitle = LText(json['subtitle']),
        avatarUri = json['avatar'] as String?,
        configUri = json['config'] as String,
        primarySwatchIndex = json['primarySwatchIndex'] as int?,
        _accentColorIndex = json['accentColorIndex'] as int?,
        supportedLocales = json['locales'] != null
            ? parseList(json['locales'], parseLocale)
            : null;

  MaterialColor? get primarySwatch =>
      getPrimarySwatch(primarySwatchIndex);

  Color? get accentColor =>
      getAccentColor(_accentColorIndex);
}
