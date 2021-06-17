import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:meta/meta.dart';

@immutable
abstract class PageData {
  final LText _title;
  final String _icon;

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

  LText get title => _title;

  String get icon => _icon;
}

@immutable
class MapPageData extends PageData {
  final MapData _mapData;

  MapPageData._(final LText title, final String icon, final dynamic json)
      : _mapData = MapData.parse(json),
        super._(title, icon);

  MapData get mapData => _mapData;
}

@immutable
class ProgrammePageData extends PageData {
  final Programme _programme;

  ProgrammePageData._(final LText title, final String icon, final dynamic json, final EventConstants eventConstants)
      : _programme = Programme.parse(json, eventConstants),
        super._(title, icon);

  Programme get programme => _programme;
}

@immutable
class InfoPageData extends PageData {
  final LText _content;

  InfoPageData._(final LText title, final String icon, final dynamic json)
      : _content = LText(json['content']),
        super._(title, icon);

  LText get content => _content;
}

@immutable
class FeedPageData extends PageData {
  final LText _feedUrl;

  FeedPageData._(final LText title, final String icon, final dynamic json)
      : _feedUrl = LText(json['feedUrl']),
        super._(title, icon);

  LText get feedUrl => _feedUrl;
}
