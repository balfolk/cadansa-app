import 'dart:async';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/feed_page.dart';
import 'package:cadansa_app/pages/info_page.dart';
import 'package:cadansa_app/pages/map_page.dart';
import 'package:cadansa_app/pages/programme_page.dart';
import 'package:cadansa_app/util/extensions.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CaDansaEventPage extends StatefulWidget {
  const CaDansaEventPage({
    required this.event,
    required this.initialIndex,
    required this.buildDrawer,
    required this.sharedPreferences,
    final Key? key,
  }) : super(key: key);

  final Event event;
  final int? initialIndex;
  final Widget? Function({required BuildContext context}) buildDrawer;
  final SharedPreferences sharedPreferences;

  @override
  _CaDansaEventPageState createState() => _CaDansaEventPageState();
}

class _CaDansaEventPageState extends State<CaDansaEventPage> {
  int _currentIndex = _DEFAULT_PAGE_INDEX;

  int? _highlightAreaFloorIndex, _highlightAreaIndex;

  late final PageHooks _pageHooks = PageHooks(
    actionHandler: _handleAction,
    buildScaffold: ({actions, appBarBottomWidget, required body}) {
      final locale = Localizations.localeOf(context);
      return Scaffold(
        appBar: AppBar(
          // Fix the status bar brightness - hopefully this becomes obsolete soon
          backwardsCompatibility: false,
          systemOverlayStyle: Theme.of(context).systemUiOverlayStyle,
          title: Text(widget.event.title.get(locale)),
          actions: actions?.toList(growable: false),
          bottom: appBarBottomWidget,
        ),
        body: body,
        drawer: widget.buildDrawer(context: context),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    },
  );
  late final IndexedPageController _programmePageController =
      IndexedPageController(index: widget.initialIndex);

  static const _DEFAULT_PAGE_INDEX = 0;
  static const _ACTION_SEPARATOR = ':',
      _ACTION_PAGE = 'page',
      _ACTION_URL = 'url',
      _ACTION_AREA = 'area';

  @override
  void didUpdateWidget(final CaDansaEventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateIndex();
  }

  void _validateIndex() {
    final newIndex = _currentIndex.clamp(0, widget.event.pages.length - 1);
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _storePageIndex(newIndex);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final key = Key('page$_currentIndex');
    _currentIndex = _currentIndex.clamp(0, widget.event.pages.length - 1);
    final pageData = widget.event.pages[_currentIndex];
    if (pageData is MapPageData) {
      return MapPage(pageData.mapData, _pageHooks, _highlightAreaFloorIndex, _highlightAreaIndex, key: key);
    } else if (pageData is ProgrammePageData) {
      return ProgrammePage(
        programme: pageData.programme,
        event: widget.event,
        pageHooks: _pageHooks,
        pageController: _programmePageController,
        getFavorites: _getEventFavorites,
        setFavorite: _setFavorite,
        key: key,
      );
    } else if (pageData is InfoPageData) {
      return InfoPage(pageData.content, _pageHooks, key: key);
    } else if (pageData is FeedPageData) {
      return FeedPage(
        data: pageData,
        pageHooks: _pageHooks,
        getReadGuids: _getReadFeedGuids,
        setReadGuid: _setReadFeedGuid,
        key: key,
      );
    }
    throw StateError('Unknown page data object $pageData');
  }

  Widget _buildBottomNavigationBar() {
    final locale = Localizations.localeOf(context);
    return BottomNavigationBar(
      items: widget.event.pages.map((pageData) => BottomNavigationBarItem(
        icon: Icon(MdiIcons.fromString(pageData.icon)),
        label: pageData.title.get(locale),
      )).toList(growable: false),
      onTap: (int index) {
        _selectPage(index);
        _storePageIndex(index);
      },
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
    );
  }

  void _handleAction(final String? action) {
    final split = action?.split(_ACTION_SEPARATOR);
    if (action == null || split == null || split.isEmpty) {
      debugPrint('Illegal action: $action');
      return;
    }

    switch (split.first) {
      case _ACTION_PAGE:
        final index = int.tryParse(action.substring('$_ACTION_PAGE$_ACTION_SEPARATOR'.length));
        _selectPage(index);
        break;
      case _ACTION_URL:
        final url = action.substring('$_ACTION_URL$_ACTION_SEPARATOR'.length);
        final locale = Localizations.localeOf(context);
        _launchUrl(LText(url).get(locale));
        break;
      case _ACTION_AREA:
        final areaId = action.substring('$_ACTION_AREA$_ACTION_SEPARATOR'.length);
        _selectArea(areaId);
        break;
    }
  }

  void _selectPage(final int? pageIndex) {
    if (!mounted ||
        pageIndex == null ||
        pageIndex < 0 ||
        pageIndex >= widget.event.pages.length) return;

    setState(() {
      _currentIndex = pageIndex;
    });
  }

  void _launchUrl(final String? url) {
    if (url != null && url.isNotEmpty) {
      launch(url);
    }
  }

  void _selectArea(final String? areaId) {
    if (areaId == null) return;

    int? pageIndex, floorIndex, areaIndex;
    for (final page in widget.event.pages.asMap().entries) {
      if (page.value is MapPageData) {
        for (final floor in (page.value as MapPageData).mapData.floors.asMap().entries) {
          final area = floor.value.areas.indexWhere((area) => area.id == areaId);
          if (area != -1) {
            pageIndex = page.key;
            floorIndex = floor.key;
            areaIndex = area;
            break;
          }
        }
      }
    }

    if (mounted && pageIndex != null && floorIndex != null && areaIndex != null) {
      final thePageIndex = pageIndex;
      setState(() {
        _currentIndex = thePageIndex;
        _highlightAreaFloorIndex = floorIndex;
        _highlightAreaIndex = areaIndex;
      });
    }
  }

  Future<void> _storePageIndex(final int index) async {
    await widget.sharedPreferences.setInt(PAGE_INDEX_KEY, index);
  }

  Set<String> _getEventFavorites() {
    return widget.sharedPreferences
        .getStringList(_favoritesPreferencesKey)?.toSet() ?? {};
  }

  Future<bool> _setFavorite(final ProgrammeItem item) async {
    final id = item.id;
    if (id == null) return false;

    final favorites = _getEventFavorites();
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }

    return widget.sharedPreferences
        .setStringList(_favoritesPreferencesKey, favorites.toList());
  }

  String get _favoritesPreferencesKey => 'favorites_${widget.event.id}';

  Set<String> _getReadFeedGuids() {
    return widget.sharedPreferences
        .getStringList(_readGuidsPreferencesKey)?.toSet() ?? {};
  }

  Future<void> _setReadFeedGuid(final String? guid) async {
    if (guid != null) {
      await widget.sharedPreferences.setStringList(_readGuidsPreferencesKey,
          _getReadFeedGuids().followedBy([guid]).toList());
    }
  }

  String get _readGuidsPreferencesKey => 'read_${widget.event.id}';
}
