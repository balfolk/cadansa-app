import 'package:cadansa_app/data/parse_utils.dart';

class GlobalConfig {
  final String logoUri;
  final List<GlobalEvent> events;

  GlobalConfig(final dynamic json)
      : logoUri = json['logo'],
        events = List.unmodifiable(json['events'].map((e) => GlobalEvent(e)));
}

class GlobalEvent {
  final LText title, subtitle;
  final String avatarUri;
  final String configUri;

  GlobalEvent(final dynamic json)
      : title = LText(json['title']),
        subtitle = LText(json['subtitle']),
        avatarUri = json['avatar'],
        configUri = json['config'];
}