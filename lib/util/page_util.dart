import 'package:cadansa_app/global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/event.dart';
import '../data/page.dart';
import '../data/programme.dart';
import '../pages/feed_page.dart';
import '../pages/info_page.dart';
import '../pages/map_page.dart';
import '../pages/programme_page.dart';

@immutable
class PageHooks {
  const PageHooks({
    required this.actionHandler,
    required this.buildScaffold,
  });

  final ActionHandler actionHandler;
  final Widget Function({
    Iterable<Widget>? actions,
    PreferredSizeWidget? appBarBottomWidget,
    required Widget body,
  }) buildScaffold;
}

class IndexedPageController {
  IndexedPageController({this.index});

  int? index;
}

Widget buildPage(final PageData pageData, {
  required final Event event,
  required final PageHooks pageHooks,
  required final SharedPreferences sharedPreferences,
  required final int? highlightAreaFloorIndex,
  required final int? highlightAreaIndex,
  required final String? openProgrammeItemId,
  required final IndexedPageController programmePageController,
  required final Set<String> Function() getEventFavorites,
  required final Future<bool> Function({required ProgrammeDay day, required ProgrammeItem item}) setFavorite,
  required final Set<String> Function() getReadFeedGuids,
  required final Future<void> Function(String?) setReadFeedGuid,
  final Key? key,
}) {
  if (pageData is MapPageData) {
    return MapPage(
      mapData: pageData.mapData,
      pageHooks: pageHooks,
      initialFloorIndex: highlightAreaFloorIndex,
      highlightAreaIndex: highlightAreaIndex,
      key: key,
    );
  } else if (pageData is ProgrammePageData) {
    return ProgrammePage(
      programme: pageData.programme,
      event: event,
      pageHooks: pageHooks,
      pageController: programmePageController,
      sharedPreferences: sharedPreferences,
      openItemId: openProgrammeItemId,
      getFavorites: getEventFavorites,
      setFavorite: setFavorite,
      key: key,
    );
  } else if (pageData is InfoPageData) {
    return InfoPage(
      content: pageData.content,
      linkColor: pageData.linkColor,
      pageHooks: pageHooks,
      key: key,
    );
  } else if (pageData is FeedPageData) {
    return FeedPage(
      data: pageData,
      pageHooks: pageHooks,
      getReadGuids: getReadFeedGuids,
      setReadGuid: setReadFeedGuid,
      key: key,
    );
  } else {
    throw StateError('Unknown page data object $pageData');
  }
}
