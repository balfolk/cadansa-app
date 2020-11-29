import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/event_page.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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

const _CONFIG_LIFETIME = Duration(hours: 5);

const _DEFAULT_PRIMARY_SWATCH = Colors.teal;
const _DEFAULT_ACCENT_COLOR = Colors.tealAccent;
const _DEFAULT_EVENT_INDEX = 0;

const _PRIMARY_SWATCH_INDEX_KEY = 'primarySwatchIndex';
const _ACCENT_COLOR_KEY = 'accentColor';
const _EVENT_INDEX_KEY = 'eventIndex';
const _LOCALE_KEY = 'locale';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  final primarySwatchIndex = sharedPrefs.getInt(_PRIMARY_SWATCH_INDEX_KEY);
  final primarySwatch = primarySwatchIndex != null ? Colors.primaries[primarySwatchIndex] : null;
  final accentColorValue = sharedPrefs.getInt(_ACCENT_COLOR_KEY);
  final accentColor = accentColorValue != null ? Color(accentColorValue) : null;

  final localeList = sharedPrefs.getStringList(_LOCALE_KEY);
  Locale locale;
  if (localeList != null && localeList.length == 3) {
    locale = Locale.fromSubtags(languageCode: localeList[0],
        scriptCode: localeList[1],
        countryCode: localeList[2]);
  } else {
    sharedPrefs.remove(_LOCALE_KEY);
  }

  runApp(CaDansaApp(locale, primarySwatch, accentColor));
}

class CaDansaApp extends StatefulWidget {
  final Locale _initialLocale;
  final MaterialColor _initialPrimarySwatch;
  final Color _initialAccentColor;

  CaDansaApp(this._initialLocale, this._initialPrimarySwatch, this._initialAccentColor);

  @override
  _CaDansaAppState createState() => _CaDansaAppState();
}

enum _CaDansaAppStateMode { done, loading, error }

class _CaDansaAppState extends State<CaDansaApp> with WidgetsBindingObserver {
  BaseCacheManager _configCacheManager;

  _CaDansaAppStateMode _mode;
  String _configUrl;
  GlobalConfig _config;
  DateTime _lastConfigLoad;

  StreamController<Locale> _localeStreamController;

  int _currentEventIndex;
  dynamic _currentEventConfig;
  int _initialPageIndex;

  static const _DEFAULT_LOCALES = [
    Locale('en', 'GB'),
    Locale('nl', 'NL'),
    Locale('fr', 'FR'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mode = _CaDansaAppStateMode.loading;
    _configCacheManager = _JsonCacheManager();
    _localeStreamController = StreamController();
    _loadConfig();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadConfig();
    }
  }

  void _resetConfig({final bool force = false}) {
    setState(() {
      _mode = _CaDansaAppStateMode.loading;
    });

    _loadConfig(force: force);
  }

  void _loadConfig({final bool force = false}) async {
    if (!force && _config != null && _lastConfigLoad != null
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

    final sharedPrefs = await SharedPreferences.getInstance();
    final jsonConfig = await _loadJson(_configUrl);
    if (jsonConfig != null) {
      try {
        _config = GlobalConfig(jsonConfig);
        _lastConfigLoad = DateTime.now();

        final eventIndex = sharedPrefs.getInt(_EVENT_INDEX_KEY)?.clamp(0, _config.events.length - 1) ?? _DEFAULT_EVENT_INDEX;
        await _switchToEvent(eventIndex);

        final pageIndex = sharedPrefs.getInt(PAGE_INDEX_KEY);
        setState(() {
          _mode = _CaDansaAppStateMode.done;
          _initialPageIndex = pageIndex;
        });
      } catch (e) {
        debugPrint('$e');
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

  Future<dynamic> _loadJson(final String url) async {
    String jsonString;
    if (url.startsWith('http')) {
      jsonString = (await _configCacheManager.getSingleFile(url)
          .timeout(_LOAD_TIMEOUT, onTimeout: () => null)
          .catchError((_) => null)).readAsStringSync();
    } else {
      jsonString = await rootBundle.loadString(url);
    }

    return jsonString != null ? jsonDecode(jsonString) : null;
  }

  @override
  Widget build(final BuildContext context) {
    final title = _currentGlobalEvent?.title ?? _config?.title ?? LText(APP_TITLE);
    final primarySwatch = _currentGlobalEvent?.primarySwatch ?? widget._initialPrimarySwatch ?? _DEFAULT_PRIMARY_SWATCH;
    final accentColor = _currentGlobalEvent?.accentColor ?? widget._initialAccentColor ?? _DEFAULT_ACCENT_COLOR;

    return StreamBuilder<Locale>(
      stream: _localeStreamController.stream,
      initialData: widget._initialLocale,
      builder: (_, localeSnapshot) {
        final locale = localeSnapshot.hasData ? localeSnapshot.data : Localizations.localeOf(context, nullOk: true);
        return MaterialApp(
          onGenerateTitle: (context) => title.get(locale ?? Localizations.localeOf(context)),
          theme: ThemeData(
            primarySwatch: primarySwatch,
            accentColor: accentColor,
          ),
          home: _homePage,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: _supportedLocales,
          locale: locale,
        );
      },
    );
  }

  Widget get _homePage {
    switch (_mode) {
      case _CaDansaAppStateMode.done:
        return CaDansaEventPage(Event(_currentGlobalEvent.title, _currentEventConfig), _initialPageIndex, _buildDrawer);
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

    final eventWidgets = List<Widget>.unmodifiable(_config.events.asMap().entries.map((e) {
      final index = e.key;
      final event = e.value;
      final isSelected = _currentEventIndex == index;

      return ListTile(
        leading: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: event.primarySwatch,
              style: isSelected ? BorderStyle.solid : BorderStyle.none,
              width: 2.0,
            ),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            backgroundColor: event.primarySwatch,
            backgroundImage: CachedNetworkImageProvider(event.avatarUri),
          ),
        ),
        title: Text(
          event.title.get(locale),
        ),
        subtitle: Text(
          event.subtitle.get(locale),
        ),
        onTap: () async {
          await _switchToEvent(index);
          setState(() {});
          Navigator.pop(context);
        },
        selected: isSelected,
      );
    }));

    final bottomWidgets = <Widget>[Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List<Widget>.unmodifiable(_supportedLocales.map((locale) => FlatButton(
        onPressed: () async {
          await _setLocale(locale);
          Navigator.pop(context);
        },
        child: Text(stringToUnicodeFlag(locale.countryCode)),
      ))),
    )];
    if (kDebugMode) {
      bottomWidgets.add(RaisedButton.icon(
        onPressed: () async {
          await _reloadConfig();
          Navigator.pop(context);
        },
        icon: const Icon(MdiIcons.refresh),
        label: const Text('Reload config'),
      ));
    }

    final headerPlaceholder = Text(APP_TITLE, style: theme.textTheme.headline2);
    final header = _config.logoUri != null
        ? CachedNetworkImage(
            imageUrl: _config.logoUri,
            errorWidget: (context, url, error) => headerPlaceholder,
            fadeInDuration: Duration.zero,
          )
        : headerPlaceholder;

    return Drawer(
        child: Column(children: <Widget>[
          DrawerHeader(
            child: Align(alignment: AlignmentDirectional.centerStart, child: header),
          ),
          Expanded(
            child: ListView(children: eventWidgets),
          ),
          const Divider(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: bottomWidgets,
          ),
        ])
    );
  }

  Future<void> _switchToEvent(final int index) async {
    _currentEventIndex = index;
    final currentEvent = _currentGlobalEvent;
    _currentEventConfig = await _loadJson(currentEvent.configUri);
    _initialPageIndex = 0;

    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setInt(_EVENT_INDEX_KEY, index);
    sharedPrefs.setInt(_PRIMARY_SWATCH_INDEX_KEY, currentEvent.primarySwatchIndex);
    sharedPrefs.setInt(_ACCENT_COLOR_KEY, currentEvent.accentColor.value);
  }

  Future<void> _setLocale(final Locale locale) async {
    _localeStreamController.add(locale);

    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setStringList(_LOCALE_KEY, [locale.languageCode, locale.scriptCode, locale.countryCode]);
  }

  Future<void> _reloadConfig() async {
    await _configCacheManager.emptyCache();
    _resetConfig(force: true);
  }

  GlobalEvent get _currentGlobalEvent =>
      _config?.events?.elementAt(_currentEventIndex);

  Iterable<Locale> get _supportedLocales =>
      _currentGlobalEvent?.supportedLocales ?? _DEFAULT_LOCALES;

  @override
  void dispose() {
    _localeStreamController.close();
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

class _JsonCacheManager extends CacheManager {
  static const key = 'jcm';

  static _JsonCacheManager _instance;

  factory _JsonCacheManager() {
    if (_instance == null) {
      _instance = new _JsonCacheManager._();
    }
    return _instance;
  }

  _JsonCacheManager._()
      : super(Config(
          key,
          stalePeriod: _CONFIG_LIFETIME,
        ));
}
