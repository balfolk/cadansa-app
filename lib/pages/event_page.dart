import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/info_page.dart';
import 'package:cadansa_app/pages/map_page.dart';
import 'package:cadansa_app/pages/programme_page.dart';
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

  static const _DEFAULT_PAGE_INDEX = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validateIndex();
  }

  @override
  void didUpdateWidget(CaDansaEventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateIndex();
  }

  void _validateIndex() {
    final newIndex = widget._initialIndex?.clamp(0, widget._event.pages.length - 1) ?? _DEFAULT_PAGE_INDEX;
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _storePageIndex(newIndex);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final key = Key('page$_currentIndex');
    final pageData = widget._event.pages[_currentIndex];
    if (pageData is MapPageData) {
      return MapPage(widget._event.title, pageData.mapData, widget._buildDrawer, _buildBottomNavigationBar, _handleAction, key: key);
    } else if (pageData is ProgrammePageData) {
      return ProgrammePage(widget._event.title, pageData.programme, widget._buildDrawer, _buildBottomNavigationBar, key: key);
    } else if (pageData is InfoPageData) {
      return InfoPage(widget._event.title, pageData.content, widget._buildDrawer, _buildBottomNavigationBar, key: key);
    }
    return null;
  }

  Widget _buildBottomNavigationBar() {
    final Locale locale = Localizations.localeOf(context);
    return BottomNavigationBar(
      items: widget._event.pages.map((pageData) => BottomNavigationBarItem(
        icon: Icon(MdiIcons.fromString(pageData.icon)),
        title: Text(pageData.title.get(locale)),
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
        if (index != null) {
          setState(() {
            _currentIndex = index;
          });
        }
        break;
      case 'url':
        final url = action.substring('url:'.length);
        launch(url);
        break;
    }
  }

  static void _storePageIndex(final int index) async {
    (await SharedPreferences.getInstance()).setInt(PAGE_INDEX_KEY, index);
  }
}
