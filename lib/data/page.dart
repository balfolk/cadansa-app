import 'dart:ui';

import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:meta/meta.dart';

@immutable
abstract class PageData {
  const PageData._(this._title, this._icon);

  factory PageData.parse(final dynamic json, final EventConstants eventConstants) {
    final title = LText(json['title']);
    final icon = json['icon'] as String;

    if (json['type'] == 'MAP') {
      return MapPageData._(title, icon, json);
    } else if (json['type'] == 'PROGRAMME') {
      return ProgrammePageData._(title, icon, json, eventConstants);
    } else if (json['type'] == 'INFO') {
      return InfoPageData._(title, icon, json);
    } else if (json['type'] == 'FEED') {
      return FeedPageData._(title, icon, json);
    }

    throw ArgumentError.value(json, 'json', "Page doesn't contain a type");
  }

  final LText _title;
  final String _icon;

  LText get title => _title;

  String get icon => _icon;
}

@immutable
class MapPageData extends PageData {
  MapPageData._(super.title, super.icon, final dynamic json)
      : _mapData = MapData.parse(json),
        super._();

  final MapData _mapData;

  MapData get mapData => _mapData;
}

@immutable
class ProgrammePageData extends PageData {
  ProgrammePageData._(super.title, super.icon, final dynamic json, final EventConstants eventConstants)
      : _programme = Programme.parse(json, eventConstants),
        super._();

  final Programme _programme;

  Programme get programme => _programme;
}

@immutable
class InfoPageData extends PageData {
  InfoPageData._(super.title, super.icon, final dynamic json)
      : _content = LText(json['content']),
        _linkColor = parseColor(json['linkColor']),
        super._();

  final LText _content;
  final Color? _linkColor;

  LText get content => _content;
  Color? get linkColor => _linkColor;
}

@immutable
class FeedPageData extends PageData {
  FeedPageData._(super.title, super.icon, final dynamic json)
      : _feedUrl = LText(json['feedUrl']),
        _feedEmptyText = LText(json['feedEmptyText']),
        _supportsUnread = json['supportsUnread'] as bool,
        super._();

  final LText _feedUrl;
  final LText _feedEmptyText;
  final bool _supportsUnread;

  LText get feedUrl => _feedUrl;
  LText get feedEmptyText => _feedEmptyText;
  bool get supportsUnread => _supportsUnread;
}
