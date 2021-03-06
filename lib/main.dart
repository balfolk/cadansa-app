import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/event_page.dart';
import 'package:cadansa_app/util/extensions.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/util/localization.dart';
import 'package:cadansa_app/widgets/event_tile.dart';
import 'package:cadansa_app/widgets/locale_widgets.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _LOAD_TIMEOUT = Duration(seconds: 5);

const _CONFIG_LIFETIME = Duration(hours: 5);

const _DEFAULT_ACCENT_COLOR = Colors.tealAccent;
const _DEFAULT_EVENT_INDEX = 0;

const _PRIMARY_SWATCH_COLOR_KEY = 'primarySwatchColor';
const _ACCENT_COLOR_KEY = 'accentColor';
const _EVENT_INDEX_KEY = 'eventIndex';
const _LOCALE_KEY = 'locale';

late PackageInfo _packageInfo;

void main() {
  _main();
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _packageInfo = await PackageInfo.fromPlatform();
  final sharedPrefs = await SharedPreferences.getInstance();

  final primarySwatchColor = sharedPrefs.getInt(_PRIMARY_SWATCH_COLOR_KEY);
  final primarySwatch = getPrimarySwatch(primarySwatchColor) ?? DEFAULT_PRIMARY_SWATCH;
  final accentColorValue = sharedPrefs.getInt(_ACCENT_COLOR_KEY);
  final accentColor = accentColorValue != null ? Color(accentColorValue) : null;

  final localeList = sharedPrefs.getStringList(_LOCALE_KEY);
  Locale? locale;
  if (localeList != null && localeList.isNotEmpty) {
    locale = Locale.fromSubtags(languageCode: localeList[0],
        scriptCode: localeList.length >= 2 ? localeList[1] : null,
        countryCode: localeList.length >= 3 ? localeList[2] : null);
  } else {
    await sharedPrefs.remove(_LOCALE_KEY);
  }

  runApp(CaDansaApp(locale, primarySwatch, accentColor, sharedPrefs));
}

class CaDansaApp extends StatefulWidget {
  const CaDansaApp(
    this._initialLocale,
    this._initialPrimarySwatch,
    this._initialAccentColor,
    this._sharedPreferences,
  );

  final Locale? _initialLocale;
  final MaterialColor _initialPrimarySwatch;
  final Color? _initialAccentColor;
  final SharedPreferences _sharedPreferences;

  @override
  _CaDansaAppState createState() => _CaDansaAppState();
}

enum _CaDansaAppStateMode { done, loading, error }

// ignore: prefer_mixin
class _CaDansaAppState extends State<CaDansaApp> with WidgetsBindingObserver {
  final BaseCacheManager _configCacheManager = _JsonCacheManager();

  _CaDansaAppStateMode _mode = _CaDansaAppStateMode.loading;
  String? _configUrl;
  GlobalConfig? _config;
  DateTime? _lastConfigLoad;

  final StreamController<Locale> _localeStreamController = StreamController();

  int? _currentEventIndex;
  GlobalEvent? _currentEvent;
  dynamic _currentEventConfig;
  int? _initialPageIndex;

  static const _DEFAULT_LOCALES = [
    Locale('en', 'GB'),
    Locale('nl', 'NL'),
    Locale('fr', 'FR'),
  ];
  static const _CONFIG_URL_KEY = 'CONFIG_URL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _loadConfig();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadConfig();
    }
  }

  void _resetConfig({final bool force = false}) {
    if (mounted) {
      setState(() {
        _mode = _CaDansaAppStateMode.loading;
      });
    }

    _loadConfig(force: force);
  }

  Future<void> _loadConfig({final bool force = false}) async {
    final lastConfigLoad = _lastConfigLoad;
    if (!force && _config != null && lastConfigLoad != null
        && lastConfigLoad.add(_CONFIG_LIFETIME).isAfter(DateTime.now())) {
      // Config still valid, use the existing one rather than reloading
      if (mounted && _mode != _CaDansaAppStateMode.done) {
        setState(() {
          _mode = _CaDansaAppStateMode.done;
        });
      }
      return;
    }

    if (_configUrl == null) {
      await dotenv.load();
      if (mounted && !dotenv.isEveryDefined({_CONFIG_URL_KEY})) {
        setState(() {
          _mode = _CaDansaAppStateMode.done;
        });
        return;
      }
      _configUrl = dotenv.env[_CONFIG_URL_KEY];
    }

    final dynamic jsonConfig = await _loadJson(_configUrl!);
    if (jsonConfig != null) {
      try {
        final config = _config = GlobalConfig(jsonConfig);
        _lastConfigLoad = DateTime.now();

        if (config.allEvents.isNotEmpty) {
          final eventIndex = widget._sharedPreferences.getInt(_EVENT_INDEX_KEY)
              ?.clamp(0, config.allEvents.length - 1)
              ?? _DEFAULT_EVENT_INDEX;
          await _switchToEvent(config.allEvents[eventIndex], eventIndex);
        }

        if (mounted) {
          final pageIndex = widget._sharedPreferences.getInt(PAGE_INDEX_KEY);
          setState(() {
            _mode = _CaDansaAppStateMode.done;
            _initialPageIndex = pageIndex;
          });
        }
      // ignore: avoid_catches_without_on_clauses
      } catch (e, stackTrace) {
        debugPrint('$e');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          setState(() {
            _mode =
            _config != null ? _CaDansaAppStateMode.done : _CaDansaAppStateMode.error;
          });
        }
      }
    } else if (mounted) {
      setState(() {
        _mode =
        _config != null ? _CaDansaAppStateMode.done : _CaDansaAppStateMode.error;
      });
    }
  }

  Future<dynamic> _loadJson(final String url) async {
    String? jsonString;
    if (url.startsWith('http')) {
      try {
        final file =
        await _configCacheManager.getSingleFile(url).timeout(_LOAD_TIMEOUT);
        jsonString = file.readAsStringSync();
      } on Exception {
        jsonString = null;
      }
    } else {
      jsonString = await rootBundle.loadString(url);
    }

    return jsonString != null ? jsonDecode(jsonString) : null;
  }

  @override
  Widget build(final BuildContext context) {
    final title = _currentEvent?.title ?? _config?.title ?? LText(APP_TITLE);
    final primarySwatch = _currentEvent?.primarySwatch ?? widget._initialPrimarySwatch;
    final accentColor = _currentEvent?.accentColor ?? widget._initialAccentColor ?? _DEFAULT_ACCENT_COLOR;

    return StreamBuilder<Locale>(
      stream: _localeStreamController.stream,
      initialData: widget._initialLocale,
      builder: (_, localeSnapshot) {
        final locale = localeSnapshot.hasData
            ? localeSnapshot.data
            : Localizations.maybeLocaleOf(context);
        return MaterialApp(
          onGenerateTitle: (context) => title.get(locale ?? Localizations.localeOf(context)),
          theme: ThemeData(
            primarySwatch: primarySwatch,
            accentColor: accentColor,
            fontFamily: 'AppFontFamily',
          ),
          home: _homePage,
          localizationsDelegates: const [
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
    final currentEvent = _currentEvent;
    if (currentEvent != null && _mode == _CaDansaAppStateMode.done) {
      return CaDansaEventPage(
        event: Event(currentEvent, _config!.defaults, _currentEventConfig),
        initialIndex: _initialPageIndex,
        buildDrawer:_buildDrawer,
        sharedPreferences: widget._sharedPreferences,
        key: ValueKey(_currentEventIndex),
      );
    } else if (_mode == _CaDansaAppStateMode.loading) {
      return LoadingPage();
    } else {
      return TimeoutPage(_resetConfig);
    }
  }

  Widget? _buildDrawer({required final BuildContext context}) {
    final config = _config;
    if (config == null) return null;

    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    var currentIndex = 0;
    final eventWidgets = config.sections.map((section) {
      final title = section.title.get(locale);
      return [
        if (title.isNotEmpty) Padding(
          padding: const EdgeInsetsDirectional.only(start: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: theme.textTheme.headline6,
          ),
        ),
        ...section.events.map((event) {
          final index = currentIndex++;
          return EventTile(
            event: event,
            isSelected: identical(event, _currentEvent),
            onTap: () async {
              await _switchToEvent(event, index);
              if (mounted) {
                setState(() {});
                Navigator.pop(context);
              }
            },
          );
        }),
      ];
    }).toList(growable: false);

    final bottomWidgets = <Widget>[
      LocaleWidgets(
        locales: _supportedLocales,
        activeLocale: locale,
        setLocale: (final Locale locale) async {
          await _setLocale(locale);
          if (mounted) {
            await Navigator.maybePop(context);
          }
        },
      ),
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _showTerms(context, config.legal),
            child: Text(config.legal.labelTerms.get(locale)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.0),
            child: Text('•'),
          ),
          TextButton(
            onPressed: () => _showAbout(context, config.legal),
            child: Text(config.legal.labelAbout.get(locale)),
          ),
        ],
      )
    ];

    if (kDebugMode) {
      bottomWidgets.add(ElevatedButton.icon(
        onPressed: _reloadConfig,
        icon: const Icon(MdiIcons.refresh),
        label: const Text('Reload config'),
      ));
    }

    final headerPlaceholder = Text(APP_TITLE, style: theme.textTheme.headline2);
    final logoUri = _config?.logoUri;
    final header = logoUri != null
        ? CachedNetworkImage(
            imageUrl: logoUri.get(locale),
            errorWidget: (context, url, dynamic error) => headerPlaceholder,
            fadeInDuration: Duration.zero,
          )
        : headerPlaceholder;

    return Drawer(
      child: Column(children: <Widget>[
        DrawerHeader(
          margin: EdgeInsets.zero,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: header,
          ),
        ),
        Expanded(
          child: ListView(
            children: eventWidgets.reduce((prev, next) => [
              ...prev,
              const Divider(),
              ...next,
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Divider(height: 0.0),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: bottomWidgets,
        ),
      ]),
    );
  }

  Future<void> _switchToEvent(final GlobalEvent event, final int index) async {
    _currentEventIndex = index;
    _currentEvent = event;
    _currentEventConfig = await _loadJson(event.configUri);
    _initialPageIndex = 0;

    await widget._sharedPreferences.setInt(_EVENT_INDEX_KEY, index);

    {
      final primarySwatch = event.primarySwatch;
      if (primarySwatch != null) {
        await widget._sharedPreferences.setInt(_PRIMARY_SWATCH_COLOR_KEY, primarySwatch.value);
      } else {
        await widget._sharedPreferences.remove(_PRIMARY_SWATCH_COLOR_KEY);
      }
    }

    {
      final accentColorIndex = event.accentColor;
      if (accentColorIndex != null) {
        await widget._sharedPreferences.setInt(_ACCENT_COLOR_KEY, accentColorIndex.value);
      } else {
        await widget._sharedPreferences.remove(_ACCENT_COLOR_KEY);
      }
    }
  }

  Future<void> _setLocale(final Locale locale) async {
    _localeStreamController.add(locale);

    await widget._sharedPreferences.setStringList(
        _LOCALE_KEY,
        [locale.languageCode, locale.scriptCode, locale.countryCode]
            .whereNotNull()
            .toList());
  }

  Future<void> _reloadConfig() async {
    await _configCacheManager.emptyCache();
    _resetConfig(force: true);
  }

  Iterable<Locale> get _supportedLocales =>
      _config?.locales ?? _DEFAULT_LOCALES;

  Future<void> _showTerms(final BuildContext context, final Legal legal) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
      final locale = Localizations.localeOf(context);
      return Scaffold(
        appBar: AppBar(
          // Fix the status bar brightness - hopefully this becomes obsolete soon
          backwardsCompatibility: false,
          systemOverlayStyle: Theme.of(context).systemUiOverlayStyle,
          title: Text(legal.labelTerms.get(locale)),
        ),
        body: Html(
          data: '<h1>${_packageInfo.appName}</h1>${legal.terms.get(locale)}',
        ),
      );
    }));
  }

  Future<void> _showAbout(final BuildContext context, final Legal legal) async {
    final locale = Localizations.localeOf(context);
    final year = DateFormat.y(locale.toLanguageTag()).format(DateTime.now());
    showAboutDialog(
      context: context,
      applicationName: _packageInfo.appName,
      applicationLegalese: 'Copyright © $year ${legal.copyright.get(locale)}',
      applicationVersion: '${_packageInfo.version} (${_packageInfo.buildNumber})',
    );
  }

  @override
  void dispose() {
    _localeStreamController.close();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}

class LoadingPage extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Fix the status bar brightness - hopefully this becomes obsolete soon
        backwardsCompatibility: false,
        systemOverlayStyle: Theme.of(context).systemUiOverlayStyle,
        title: const Text(APP_TITLE),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class TimeoutPage extends StatelessWidget {
  const TimeoutPage(this._onRefresh);

  final VoidCallback _onRefresh;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Fix the status bar brightness - hopefully this becomes obsolete soon
        backwardsCompatibility: false,
        systemOverlayStyle: Theme.of(context).systemUiOverlayStyle,
        title: const Text(APP_TITLE),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(
              Localization.TIMEOUT_MESSAGE.get(Localizations.localeOf(context)),
              textAlign: TextAlign.center,
            ),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(MdiIcons.refresh),
              label: Text(Localization.REFRESH.get(Localizations.localeOf(context))),
            )],
          ),
        ),
      ),
    );
  }
}

class _JsonCacheManager extends CacheManager {
  factory _JsonCacheManager() {
    return _instance;
  }

  _JsonCacheManager._()
      : super(Config(
          key,
          stalePeriod: _CONFIG_LIFETIME,
        ));

  static const key = 'jcm';

  static late final _JsonCacheManager _instance = _JsonCacheManager._();
}
