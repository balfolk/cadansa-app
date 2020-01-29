import 'package:cadansa_app/data/global_conf.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/info_page.dart';
import 'package:cadansa_app/pages/map_page.dart';
import 'package:cadansa_app/pages/programme_page.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CaDansaHomePage extends StatefulWidget {
  final String _title;
  final List<PageData> _pages;
  final int _initialIndex;

  CaDansaHomePage(final dynamic config, this._initialIndex)
      : _title = config['title'],
        _pages = (config['pages'] as List)
            .map((p) => PageData.parse(p, GlobalConfiguration(config))).toList(growable: false);

  @override
  _CaDansaHomePageState createState() => _CaDansaHomePageState();
}

class _CaDansaHomePageState extends State<CaDansaHomePage> {
  int _currentIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget._initialIndex != null && widget._initialIndex > -1 && widget._initialIndex < widget._pages.length) {
      _currentIndex = widget._initialIndex;
    } else {
      _currentIndex = -1;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final key = Key('page$_currentIndex');
    final pageData = widget._pages[_currentIndex];
    if (pageData is MapPageData) {
      return MapPage(widget._title, pageData.mapData, _generateBottomNavigationBar, _handleAction, key: key);
    } else if (pageData is ProgrammePageData) {
      return ProgrammePage(widget._title, pageData.programme, _generateBottomNavigationBar, key: key);
    } else if (pageData is InfoPageData) {
      return InfoPage(widget._title, pageData.content, _generateBottomNavigationBar, key: key);
    }
    return null;
  }

  BottomNavigationBar _generateBottomNavigationBar() {
    final Locale locale = Localizations.localeOf(context);
    return BottomNavigationBar(
      items: widget._pages.map((pageData) => BottomNavigationBarItem(
        icon: Icon(MdiIcons.fromString(pageData.icon)),
        title: Text(pageData.title.get(locale)),
      )).toList(growable: false),
      onTap: (int index) async {
        setState(() {
          _currentIndex = index;
        });
        (await SharedPreferences.getInstance()).setInt(PAGE_INDEX_KEY, index);
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
}
