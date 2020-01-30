import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Duration _LOAD_TIMEOUT = const Duration(seconds: 5);
final LText _TIMEOUT_MESSAGE = LText(const {
  'en': "Could not connect to the server. Please make sure you're connected to the Internet.",
  'nl': 'Het is niet gelukt verbinding te maken met de server. Controleer of je internetverbinding aanstaat.',
  'fr': 'Échec du téléchargement du fichier. Assurez-vous que votre connexion Internet fonctionne.'
});
final LText _REFRESH = LText(const {
  'en': 'Refresh',
  'nl': 'Probeer opnieuw',
  'fr': 'Réessayer',
});

const _DEFAULT_PRIMARY_SWATCH_INDEX = 8;

void main() => runApp(const CaDansaApp());

class CaDansaApp extends StatefulWidget {
  const CaDansaApp();

  @override
  _CaDansaAppState createState() => _CaDansaAppState();
}

enum _CaDansaAppStateMode { done, loading, error }

class _CaDansaAppState extends State<CaDansaApp> with WidgetsBindingObserver {
  _CaDansaAppStateMode _mode;
  String _configUrl;
  dynamic _config;
  dynamic _events;
  DateTime _lastConfigLoad;

  int _currentEventIndex;
  dynamic _currentEventConfig;
  int _initialPageIndex;

  static const _CONFIG_LIFETIME = Duration(hours: 5);
  static const _DEFAULT_LOCALES = [
    Locale('en'),
    Locale('nl'),
    Locale('fr'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mode = _CaDansaAppStateMode.loading;
    _currentEventIndex = 0;
    _loadConfig();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadConfig();
    }
  }

  void _resetConfig() {
    setState(() {
      _mode = _CaDansaAppStateMode.loading;
    });

    _loadConfig();
  }

  void _loadConfig() async {
    if (_config != null && _lastConfigLoad != null
        && _lastConfigLoad.add(_CONFIG_LIFETIME).isAfter(DateTime.now())) {
      // Config still valid, use the existing one rather than reloading
      if (_mode != _CaDansaAppStateMode.done) {
        setState(() {
          _mode = _CaDansaAppStateMode.done;
        });
      }
      return;
    }

    if (_configUrl == null) {
      await DotEnv().load('.env');
      _configUrl = DotEnv().env['CONFIG_URL'];
    }


    final jsonConfig = await _loadJson(_configUrl);
    if (jsonConfig != null) {
      try {
        _config = jsonConfig;
        _lastConfigLoad = DateTime.now();
        _events = _config['events'];
        await _switchToEvent(min(_currentEventIndex, _events.length - 1));

        final int pageIndex = (await SharedPreferences.getInstance()).getInt(PAGE_INDEX_KEY);

        setState(() {
          _mode = _CaDansaAppStateMode.done;
          _initialPageIndex = pageIndex;
        });
      } catch (_) {
        setState(() {
          _mode = _config != null ? _CaDansaAppStateMode.done : _CaDansaAppStateMode.error;
        });
      }
    } else {
      setState(() {
        _mode = _config != null ? _CaDansaAppStateMode.done : _CaDansaAppStateMode.error;
      });
    }
  }

  static Future<dynamic> _loadJson(final String url) async {
    String jsonString;
    if (url.startsWith('http')) {
      jsonString = (await new HttpClient()
          .getUrl(Uri.parse(url))
          .then((final HttpClientRequest request) => request.close())
          .then((final HttpClientResponse response) =>
          response.transform(Utf8Decoder()).toList())
          .timeout(_LOAD_TIMEOUT, onTimeout: () => null)
          .catchError((_) => null))
        ?.join();
    } else {
      jsonString = await rootBundle.loadString(url);
    }

    return jsonString != null ? jsonDecode(jsonString) : null;
  }

  @override
  Widget build(final BuildContext context) {
    final config = _currentEventConfig ?? const {};

    final title = LText(config['title'] ?? APP_TITLE);
    final primarySwatchIndex = config['primarySwatchIndex'] ?? _DEFAULT_PRIMARY_SWATCH_INDEX;
    final accentColorIndex = config['accentColorIndex'] ?? primarySwatchIndex;

    return MaterialApp(
      onGenerateTitle: (context) => title.get(Localizations.localeOf(context)),
      theme: ThemeData(
        primarySwatch: Colors.primaries[primarySwatchIndex],
        accentColor: Colors.accents[accentColorIndex]
      ),
      home: _homePage,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: config['locales']?.map((l) => Locale(l))?.cast<Locale>() ?? _DEFAULT_LOCALES,
    );
  }

  Widget get _homePage {
    switch (_mode) {
      case _CaDansaAppStateMode.done:
        return CaDansaHomePage(_currentEventConfig, _initialPageIndex, _buildDrawer);
      case _CaDansaAppStateMode.loading:
        return LoadingPage();
      case _CaDansaAppStateMode.error:
      default:
        return TimeoutPage(_resetConfig);
    }
  }

  Widget _buildDrawer(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final eventWidgets = _config['events'].asMap().entries.map((event) => ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(event.value['avatar']),
      ),
      title: Text(
        LText(event.value['title']).get(locale),
        style: _currentEventIndex == event.key ? TextStyle(color: theme.primaryColor) : null,
      ),
      subtitle: Text(
        LText(event.value['subtitle']).get(locale),
      ),
      onTap: () async {
        await _switchToEvent(event.key);
        setState(() {});
        Navigator.pop(context);
      },
    )).cast<Widget>().toList(growable: false);
    final header = _config['logo'] != null
        ? Image.network(_config['logo'])
        : Text(APP_TITLE, style: theme.textTheme.display3);

    return Drawer(
      child: ListView(children: <Widget>[
        DrawerHeader(
          child: Align(alignment: AlignmentDirectional.centerStart, child: header),
        )
      ] + eventWidgets),
    );
  }

  Future<void> _switchToEvent(final int index) async {
    _currentEventIndex = index;
    final currentEvent = _events[index];
    _currentEventConfig = await _loadJson(currentEvent['config']);
    _currentEventConfig['title'] = currentEvent['title'];
    _initialPageIndex = 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class LoadingPage extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(APP_TITLE),
      ),
      body: Center(
        child: const CircularProgressIndicator(),
      ),
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
        title: const Text(APP_TITLE),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20.0),
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
            )],
          ),
        ),
      ),
    );
  }
}
