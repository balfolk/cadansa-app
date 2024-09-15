import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

@immutable
class GlobalConfig {
  GlobalConfig(final dynamic json)
      : title = LText(json['title']),
        logoUri = LText(json['logo']),
        locales = parseList(json['locales'], parseLocale),
        defaults = GlobalDefaults(json['defaults']),
        sections = parseList(json['eventSections'], (dynamic s) => EventsSection(s)),
        legal = Legal(json['legal']);

  final LText title;
  final LText? logoUri;
  final BuiltList<Locale> locales;
  final GlobalDefaults defaults;
  final BuiltList<EventsSection> sections;
  final Legal legal;

  late final BuiltList<GlobalEvent> allEvents = BuiltList.of(
      sections.map((s) => s.events).expand<GlobalEvent>((events) => events));
}

@immutable
class EventsSection {
  EventsSection(final dynamic json)
      : title = LText(json['title']),
        events = parseList(json['events'], (dynamic e) => GlobalEvent(e));

  final LText title;
  final BuiltList<GlobalEvent> events;
}

@immutable
class GlobalEvent {
  GlobalEvent(final dynamic json)
      : id = json['id'] as String,
        title = LText(json['title']),
        startDate = parseDate(json['startDate']),
        endDate = parseDate(json['endDate']),
        avatarUri = json['avatar'] as String?,
        configUri = json['config'] as String,
        seedColor = parseColor(json['seedColor']),
        isLarge = json['isLarge'] as bool? ?? false;

  final String id;
  final LText title;
  final DateTime startDate, endDate;
  final String? avatarUri;
  final String configUri;
  final Color? seedColor;
  final bool isLarge;

  bool get isCurrent =>
      startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
}

@immutable
class GlobalDefaults {
  GlobalDefaults(final dynamic json)
      : supportsFavorites = json['supportsFavorites'] as bool,
        favoriteInnerColor = parseColor(json['favoriteInnerColor'])!,
        favoriteOuterColor = parseColor(json['favoriteOuterColor'])!,
        favoriteTooltip = LText(json['favoriteTooltip']),
        notificationTimeBefore = parseDuration(json['notificationTimeBefore'])!,
        favoriteSnackText = LText(json['favoriteSnackText']),
        unfavoriteSnackText = LText(json['unfavoriteSnackText']),
        notificationTitle = LText(json['notificationTitle']),
        notificationBody = LText(json['notificationBody']);

  final bool supportsFavorites;
  final Color favoriteInnerColor;
  final Color favoriteOuterColor;
  final LText favoriteTooltip;
  final Duration notificationTimeBefore;
  final LText favoriteSnackText;
  final LText unfavoriteSnackText;
  final LText notificationTitle;
  final LText notificationBody;
}

@immutable
class Legal {
  Legal(final dynamic json)
      : labelTerms = LText(json['labels']['terms']),
        labelAbout = LText(json['labels']['about']),
        terms = LText(json['terms']),
        copyright = LText(json['copyright']);

  final LText labelTerms;
  final LText labelAbout;
  final LText terms;
  final LText copyright;
}
