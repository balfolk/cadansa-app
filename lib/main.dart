import 'dart:convert';
import 'dart:io';

import 'package:cadansa_app/data/global_conf.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/pages/info_page.dart';
import 'package:cadansa_app/pages/map_page.dart';
import 'package:cadansa_app/pages/programme_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

const String _DEFAULT_TITLE = 'CaDansa';
const Duration _LOAD_TIMEOUT = const Duration(seconds: 5);
final LText _TIMEOUT_MESSAGE = LText({
  'en': "Could not connect to the server. Please make sure you're connected to the internet.",
  'nl': 'Het is niet gelukt verbinding te maken met de server. Controller of je internetverbinding aanstaat.',
  'fr': 'Échec du téléchargement du fichier. Assurez-vous que votre connexion Internet fonctionne.'
});
final LText _REFRESH = LText({
  'en': 'Refresh',
  'nl': 'Probeer opnieuw',
  'fr': 'Réessayer',
});

void main() => runApp(CaDansaApp());

class CaDansaApp extends StatefulWidget {
  @override
  _CaDansaAppState createState() => _CaDansaAppState();
}

class _CaDansaAppState extends State<CaDansaApp> with WidgetsBindingObserver {
  dynamic _config;
  bool _error = false;
  String _configUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConfig();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetConfig();
    }
  }

  void _resetConfig() {
    setState(() {
      _error = false;
      _config = null;
    });
    _loadConfig();
  }

  void _loadConfig() async {
    if (_configUrl == null) {
      await DotEnv().load('.env');
      _configUrl = DotEnv().env['CONFIG_URL'];
    }

    String jsonConfig;
    if (_configUrl.startsWith('http')) {
      jsonConfig = (await new HttpClient()
          .getUrl(Uri.parse(DotEnv().env['CONFIG_URL']))
          .then((final HttpClientRequest request) => request.close())
          .then((final HttpClientResponse response) =>
          response.transform(Utf8Decoder()).toList())
          .timeout(_LOAD_TIMEOUT, onTimeout: () => null)
          .catchError((_) => null))
          ?.join();
    } else {
      jsonConfig = await rootBundle.loadString(_configUrl);
    }

    if (jsonConfig != null) {
      try {
        final config = jsonDecode(jsonConfig);
        setState(() {
          _config = config;
        });
      } catch (_) {
        setState(() {
          _error = true;
        });
      }
    } else {
      setState(() {
        _error = true;
      });
    }
  }


  @override
  Widget build(final BuildContext context) {
    final title = LText((_config ?? const {})['title'] ?? _DEFAULT_TITLE);
    return MaterialApp(
      onGenerateTitle: (context) => title.get(Localizations.localeOf(context)),
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: _homePage,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('nl'),
        const Locale('fr'),
      ],
    );
  }

  Widget get _homePage {
    if (_error) {
      return TimeoutPage(_resetConfig);
    } else if (_config == null) {
      return LoadingPage();
    } else if (DateTime.now().isAfter(_festivalOver)) {
      return FestivalOverPage(
          _config['title'], LText(_config['labels']['afterwards']));
    } else {
      return CaDansaHomePage(_config);
    }
  }

  DateTime get _festivalOver {
    return toDateTime(_config['festivalEnd']);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class CaDansaHomePage extends StatefulWidget {
  final String _title;
  final List<PageData> _pages;

  CaDansaHomePage(final dynamic config)
      : _title = config['title'],
        _pages = (config['pages'] as List)
            .map((p) => PageData.parse(p, GlobalConfiguration(config))).toList(growable: false);

  @override
  _CaDansaHomePageState createState() => _CaDansaHomePageState();
}

class _CaDansaHomePageState extends State<CaDansaHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(final BuildContext context) {
    final key = Key('page$_currentIndex');
    final pageData = widget._pages[_currentIndex];
    if (pageData is MapPageData) {
      return MapPage(widget._title, pageData.mapData, _generateBottomNavigationBar, key: key);
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
      onTap: (int index) => setState(() {
        _currentIndex = index;
      }),
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
    );
  }
}

class LoadingPage extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_DEFAULT_TITLE),
      ),
      body: Center(child: const CircularProgressIndicator()),
    );
  }
}

class TimeoutPage extends StatelessWidget {
  final VoidCallback _onRefresh;

  TimeoutPage(this._onRefresh);

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_DEFAULT_TITLE),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(
              _TIMEOUT_MESSAGE.get(Localizations.localeOf(context)),
              textAlign: TextAlign.center,
            ),
            OutlineButton.icon(
              onPressed: _onRefresh,
              icon: Icon(MdiIcons.refresh, color: Theme.of(context).primaryColor,),
              label: Text(_REFRESH.get(Localizations.localeOf(context))),
              color: Theme.of(context).primaryColor,
            )
          ],
          ),
        ),
      ),
    );
  }
}

class FestivalOverPage extends StatelessWidget {
  final String _title;
  final LText _text;

  FestivalOverPage(this._title, this._text);

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(20.0),
        child: Text(
          _text.get(Localizations.localeOf(context)),
          style: Theme.of(context).textTheme.display2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
