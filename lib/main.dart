import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/event_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  final primarySwatchIndex = sharedPrefs.getInt(_PRIMARY_SWATCH_INDEX_KEY);
  final primarySwatch = primarySwatchIndex != null ? Colors.primaries[primarySwatchIndex] : null;
  final accentColorValue = sharedPrefs.getInt(_ACCENT_COLOR_KEY);
  final accentColor = accentColorValue != null ? Color(accentColorValue) : null;

  runApp(CaDansaApp(primarySwatch, accentColor));
}

class CaDansaApp extends StatefulWidget {
  final MaterialColor _initialPrimarySwatch;
  final Color _initialAccentColor;

  CaDansaApp(this._initialPrimarySwatch, this._initialAccentColor);

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

  int _currentEventIndex;
  dynamic _currentEventConfig;
  int _initialPageIndex;

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
    _configCacheManager = _JsonCacheManager();
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

    return MaterialApp(
      onGenerateTitle: (context) => title.get(Localizations.localeOf(context)),
      theme: ThemeData(
        primarySwatch: primarySwatch,
        accentColor: accentColor,
      ),
      home: _homePage,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: _currentGlobalEvent?.supportedLocales ?? _DEFAULT_LOCALES,
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

    final headerPlaceholder = Text(APP_TITLE, style: theme.textTheme.display3);
    final header = _config.logoUri != null
        ? CachedNetworkImage(
            imageUrl: _config.logoUri,
            errorWidget: (context, url, error) => headerPlaceholder,
            fadeInDuration: Duration.zero,
          )
        : headerPlaceholder;

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
    final currentEvent = _currentGlobalEvent;
    _currentEventConfig = await _loadJson(currentEvent.configUri);
    _initialPageIndex = 0;

    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setInt(_EVENT_INDEX_KEY, index);
    sharedPrefs.setInt(_PRIMARY_SWATCH_INDEX_KEY, currentEvent.primarySwatchIndex);
    sharedPrefs.setInt(_ACCENT_COLOR_KEY, currentEvent.accentColor.value);
  }

  GlobalEvent get _currentGlobalEvent => _config?.events?.elementAt(_currentEventIndex);

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

class _JsonCacheManager extends BaseCacheManager {
  static const key = 'jcm';

  static _JsonCacheManager _instance;

  factory _JsonCacheManager() {
    if (_instance == null) {
      _instance = new _JsonCacheManager._();
    }
    return _instance;
  }

  _JsonCacheManager._() : super(key, maxAgeCacheObject: _CONFIG_LIFETIME);

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }
}
