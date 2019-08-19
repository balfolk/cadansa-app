import 'dart:convert';
import 'dart:io';

import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/pages/map_page.dart';
import 'package:cadansa_app/pages/programme_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const String _DEFAULT_TITLE = 'CaDansa';
const Duration _LOAD_TIMEOUT = const Duration(seconds: 5);
final LText _TIMEOUT_MESSAGE = LText.fromMap({
  'en': "Could not connect to the server. Please make sure you're connected to the internet.",
  'nl': 'Het is niet gelukt verbinding te maken met de server. Zorg ervoor dat je internetverbinding aanstaat.',
});
final LText _REFRESH = LText.fromMap({
  'en': "Refresh",
  'nl': "Probeer opnieuw",
});

void main() => runApp(CaDansaApp());

class CaDansaApp extends StatefulWidget {
  @override
  _CaDansaAppState createState() => _CaDansaAppState();
}

class _CaDansaAppState extends State<CaDansaApp> {
  dynamic _config;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await DotEnv().load('.env');
    final String configUrl = DotEnv().env['CONFIG_URL'];

    String jsonConfig;
    if (configUrl.startsWith('http')) {
      jsonConfig = (await new HttpClient()
          .getUrl(Uri.parse(DotEnv().env['CONFIG_URL']))
          .then((final HttpClientRequest request) => request.close())
          .then((final HttpClientResponse response) =>
          response.transform(Utf8Decoder()).toList())
          .timeout(_LOAD_TIMEOUT, onTimeout: () => null)
          .catchError((_) => null))
          ?.join();
    } else {
      jsonConfig = await rootBundle.loadString(configUrl);
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
    final String title = (_config ?? {})['title'] ?? _DEFAULT_TITLE;
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: _homePage,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
//        GlobalCupertinoLocalizations.delegate,
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
      return TimeoutPage(() {
        setState(() {
          _error = false;
          _config = null;
        });
        _init();
      });
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
}

enum _Page { MAP, PROGRAMME }

class CaDansaHomePage extends StatefulWidget {
  final String _title;
  final Map<String, LText> _labels;
  final MapData _mapData;
  final Programme _programme;

  CaDansaHomePage(final dynamic config)
      : _title = config['title'],
        _labels = (config['labels'] as Map)
            .map((key, value) => MapEntry(key, LText(value))),
        _mapData = MapData.parse(config['map']),
        _programme = Programme.parse(config['programme']);

  @override
  _CaDansaHomePageState createState() => _CaDansaHomePageState();
}

class _CaDansaHomePageState extends State<CaDansaHomePage> {
  _Page _page = _Page.MAP;

  @override
  Widget build(final BuildContext context) {
    switch (_page) {
      case _Page.MAP:
        return MapPage(widget._title, widget._mapData, _generateBottomNavigationBar);
      case _Page.PROGRAMME:
        return ProgrammePage(
            widget._title, widget._programme, _generateBottomNavigationBar);
    }

    return null;
  }

  BottomNavigationBar _generateBottomNavigationBar() {
    final Locale locale = Localizations.localeOf(context);
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            title: Text(widget._labels['map'].get(locale))),
        BottomNavigationBarItem(
            icon: const Icon(Icons.music_note),
            title: Text(widget._labels['programme'].get(locale))),
      ],
      onTap: (int p) => setState(() {
            _page = _Page.values[p];
          }),
      currentIndex: _page.index,
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
                icon: const Icon(Icons.refresh),
                label: Text(_REFRESH.get(Localizations.localeOf(context))))
          ]))),
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
