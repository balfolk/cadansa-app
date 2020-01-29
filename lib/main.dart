import 'dart:convert';
import 'dart:io';

import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _DEFAULT_TITLE = 'CaDansa';
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
  DateTime _lastConfigLoad;
  int _initialPageIndex;

  static const _CONFIG_LIFETIME = const Duration(hours: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mode = _CaDansaAppStateMode.loading;
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

    String jsonConfig;
    if (_configUrl.startsWith('http')) {
      jsonConfig = (await new HttpClient()
          .getUrl(Uri.parse(_configUrl))
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
        _config = jsonDecode(jsonConfig);
        _lastConfigLoad = DateTime.now();
        final int index = (await SharedPreferences.getInstance()).getInt(PAGE_INDEX_KEY);

        setState(() {
          _mode = _CaDansaAppStateMode.done;
          _initialPageIndex = index;
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
    switch (_mode) {
      case _CaDansaAppStateMode.done:
        if (DateTime.now().isAfter(_festivalOver)) {
          return FestivalOverPage(
              _config['title'], LText(_config['labels']['afterwards']));
        } else {
          return CaDansaHomePage(_config, _initialPageIndex);
        }
        break;
      case _CaDansaAppStateMode.loading:
        return LoadingPage();
      case _CaDansaAppStateMode.error:
      default:
        return TimeoutPage(_resetConfig);
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
        padding: const EdgeInsets.all(20.0),
        child: Text(
          _text.get(Localizations.localeOf(context)),
          style: Theme.of(context).textTheme.display2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
