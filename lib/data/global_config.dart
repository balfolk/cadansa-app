import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

class GlobalConfig {
  final LText title;
  final LText logoUri;
  final List<EventsSection> sections;

  GlobalConfig(final dynamic json)
      : title = LText(json['title']),
        logoUri = LText(json['logo']),
        sections = List.unmodifiable(json['eventSections']?.map((s) => EventsSection(s)) ?? []);

  List<GlobalEvent> get allEvents => sections
      .fold(const Iterable<GlobalEvent>.empty(), (l, section) => l.followedBy(section.events))
      .toList();
}

class EventsSection {
  final LText title;
  final List<GlobalEvent> events;

  EventsSection(final dynamic json)
      : title = LText(json['title']),
        events = List.unmodifiable(json['events']?.map((e) => GlobalEvent(e)) ?? []);
}

class GlobalEvent {
  final LText title, subtitle;
  final String avatarUri;
  final String configUri;
  final int primarySwatchIndex, _accentColorIndex;
  final List<Locale> supportedLocales;

  GlobalEvent(final dynamic json)
      : title = LText(json['title']),
        subtitle = LText(json['subtitle']),
        avatarUri = json['avatar'],
        configUri = json['config'],
        primarySwatchIndex = json['primarySwatchIndex'],
        _accentColorIndex = json['accentColorIndex'],
        supportedLocales = json['locales'] != null
            ? List.unmodifiable(json['locales'].map((l) => Locale(l[0], l[1])))
            : null;

  MaterialColor get primarySwatch => Colors.primaries[primarySwatchIndex];

  Color get accentColor => Colors.accents[_accentColorIndex];

}
