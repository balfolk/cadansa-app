import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

class GlobalConfig {
  final LText title;
  final String logoUri;
  final List<GlobalEvent> events;

  GlobalConfig(final dynamic json)
      : title = LText(json['title']),
        logoUri = json['logo'],
        events = List.unmodifiable(json['events'].map((e) => GlobalEvent(e)));
}

class GlobalEvent {
  final LText title, subtitle;
  final String avatarUri;
  final String configUri;
  final int _primarySwatchIndex, _accentColorIndex;
  final List<Locale> supportedLocales;

  GlobalEvent(final dynamic json)
      : title = LText(json['title']),
        subtitle = LText(json['subtitle']),
        avatarUri = json['avatar'],
        configUri = json['config'],
        _primarySwatchIndex = json['primarySwatchIndex'],
        _accentColorIndex = json['accentColorIndex'],
        supportedLocales = List.unmodifiable(json['locales'].map((l) => Locale(l)));

  MaterialColor get primarySwatch => Colors.primaries[_primarySwatchIndex];

  Color get accentColor => Colors.accents[_accentColorIndex];

}
