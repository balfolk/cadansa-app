import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/feed_page.dart';
import 'package:cadansa_app/pages/info_page.dart';
import 'package:cadansa_app/pages/map_page.dart';
import 'package:cadansa_app/pages/programme_page.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CaDansaEventPage extends StatefulWidget {
  final Event _event;
  final int _initialIndex;
  final Widget Function(BuildContext) _buildDrawer;

  CaDansaEventPage(this._event, this._initialIndex, this._buildDrawer);

  @override
  _CaDansaEventPageState createState() => _CaDansaEventPageState();
}

class _CaDansaEventPageState extends State<CaDansaEventPage> {
  int _currentIndex;

  int _highlightAreaFloorIndex, _highlightAreaIndex;

  PageHooks _pageHooks;
  IndexedPageController _programmePageController;

  static const _DEFAULT_PAGE_INDEX = 0;

  @override
  void initState() {
    super.initState();
    _pageHooks = PageHooks(
      buildDrawer: (context) => widget._buildDrawer(context),
      buildBottomBar: _buildBottomNavigationBar,
      actionHandler: _handleAction,
    );
    _programmePageController = IndexedPageController();
    _setIndex(widget._initialIndex);
  }

  @override
  void didUpdateWidget(final CaDansaEventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateIndex();
  }

  void _validateIndex() {
    _setIndex(_currentIndex);
  }

  void _setIndex(int newIndex) {
    newIndex = newIndex?.clamp(0, widget._event.pages.length - 1) ?? _DEFAULT_PAGE_INDEX;
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _storePageIndex(newIndex);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final key = Key('page$_currentIndex');
    _currentIndex = _currentIndex.clamp(0, widget._event.pages.length - 1);
    final pageData = widget._event.pages[_currentIndex];
    if (pageData is MapPageData) {
      return MapPage(widget._event.title, pageData.mapData, _pageHooks, _highlightAreaFloorIndex, _highlightAreaIndex, key: key);
    } else if (pageData is ProgrammePageData) {
      return ProgrammePage(widget._event.title, pageData.programme, _pageHooks, _programmePageController, key: key);
    } else if (pageData is InfoPageData) {
      return InfoPage(widget._event.title, pageData.content, _pageHooks, key: key);
    } else if (pageData is FeedPageData) {
      return FeedPage(widget._event.title, pageData.feedUrl, _pageHooks, key: key);
    }
    return null;
  }

  Widget _buildBottomNavigationBar() {
    final locale = Localizations.localeOf(context);
    return BottomNavigationBar(
      items: widget._event.pages.map((pageData) => BottomNavigationBarItem(
        icon: Icon(MdiIcons.fromString(pageData.icon)),
        label: pageData.title.get(locale),
      )).toList(growable: false),
      onTap: (int index) async {
        setState(() {
          _currentIndex = index;
        });
        _storePageIndex(index);
      },
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
    );
  }

  void _handleAction(final String action) {
    switch (action.split(':').first) {
      case 'page':
        final index = int.tryParse(action.substring('page:'.length));
        _selectPage(index);
        break;
      case 'url':
        final url = action.substring('url:'.length);
        launch(url);
        break;
      case 'area':
        final areaId = action.substring('area:'.length);
        _selectArea(areaId);
        break;
    }
  }

  void _selectPage(final int pageIndex) {
    if (pageIndex == null || pageIndex < 0 || pageIndex >= widget._event.pages.length) return;

    setState(() {
      _currentIndex = pageIndex;
    });
  }

  void _selectArea(final String areaId) {
    if (areaId == null) return;

    int pageIndex, floorIndex, areaIndex;
    for (final page in widget._event.pages.asMap().entries) {
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

    if (pageIndex != null && floorIndex != null && areaIndex != null) {
      setState(() {
        _currentIndex = pageIndex;
        _highlightAreaFloorIndex = floorIndex;
        _highlightAreaIndex = areaIndex;
      });
    }
  }

  static void _storePageIndex(final int index) async {
    await (await SharedPreferences.getInstance()).setInt(PAGE_INDEX_KEY, index);
  }
}
