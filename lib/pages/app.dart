import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/pages/event_page.dart';
import 'package:cadansa_app/pages/loading_page.dart';
import 'package:cadansa_app/pages/timeout_page.dart';
import 'package:cadansa_app/util/extensions.dart';
import 'package:cadansa_app/util/notifications.dart';
import 'package:cadansa_app/widgets/event_tile.dart';
import 'package:cadansa_app/widgets/locale_widgets.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _LOAD_TIMEOUT = Duration(seconds: 5);

const _CONFIG_LIFETIME = Duration(hours: 5);

const _DEFAULT_SECONDARY_COLOR = Colors.tealAccent;
const _DEFAULT_EVENT_INDEX = 0;

const _EVENT_INDEX_KEY = 'eventIndex';

class CaDansaApp extends StatefulWidget {
  const CaDansaApp({
    required this.initialLocale,
    required this.initialPrimarySwatch,
    required this.initialSecondaryColor,
    required this.sharedPreferences,
    required this.env,
    required this.packageInfo
  });

  final Locale? initialLocale;
  final MaterialColor initialPrimarySwatch;
  final Color? initialSecondaryColor;
  final SharedPreferences sharedPreferences;
  final Map<String, String> env;
  final PackageInfo packageInfo;

  @override
  CaDansaAppState createState() => CaDansaAppState();
}

enum _CaDansaAppStateMode { done, loading, error }

// ignore: prefer_mixin
class CaDansaAppState extends State<CaDansaApp> with WidgetsBindingObserver {
  _CaDansaAppStateMode _mode = _CaDansaAppStateMode.loading;
  GlobalConfig? _config;
  DateTime? _lastConfigLoad;

  int? _currentEventIndex;
  dynamic _currentEventConfig;
  String? _initialAction;

  late final BaseCacheManager _configCacheManager = _JsonCacheManager();
  late final String? _configUri = widget.env[_CONFIG_URI_KEY];
  late final StreamController<Locale> _localeStreamController = StreamController();

  static const _DEFAULT_LOCALES = [
    Locale('en', 'GB'),
    Locale('nl', 'NL'),
    Locale('fr', 'FR'),
  ];
  static const _CONFIG_URI_KEY = 'CONFIG_URI';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    await initializeNotifications(
      context: context,
      onSelectNotification: _onSelectNotification,
    );
    if (mounted) {
      await _reloadConfig(movePage: true, initial: true);
    }
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadConfig(movePage: false);
    }
  }

  Future<void> _resetConfig({final bool force = false}) async {
    if (mounted) {
      setState(() {
        _mode = _CaDansaAppStateMode.loading;
      });

      await _reloadConfig(movePage: true, initial: true, force: force);
    }
  }

  Future<void> _reloadConfig({
    required final bool movePage,
    final bool initial = false,
    final bool force = false,
  }) async {
    final success = await _loadConfig(initial: initial, force: force);
    final newMode = success ? _CaDansaAppStateMode.done : _CaDansaAppStateMode.error;
    if (_mode != newMode) {
      String? initialAction;
      if (success && movePage) {
        final initialNotification = await getInitialNotification();
        if (initialNotification != null) {
          initialAction = initialNotification;
        } else {
          initialAction = 'page'
              ':${widget.sharedPreferences.getInt(PAGE_INDEX_KEY)}'
              ':${widget.sharedPreferences.getInt(PAGE_SUB_INDEX_KEY) ?? ''}';
        }
      }

      if (mounted) {
        setState(() {
          _mode = newMode;
          _initialAction = initialAction;
        });
      }
    }
  }

  Future<bool> _loadConfig({
    final bool initial = false,
    final bool force = false,
  }) async {
    final lastConfigLoad = _lastConfigLoad;
    if (!force &&
        _config != null &&
        lastConfigLoad != null &&
        lastConfigLoad.add(_CONFIG_LIFETIME).isAfter(DateTime.now())) {
      // Config still valid, use the existing one rather than reloading
      return true;
    }

    final configUri = _configUri;
    if (configUri == null) return false;

    final dynamic jsonConfig = await _loadJson(configUri);
    if (jsonConfig == null) return false;

    try {
      final config = _config = GlobalConfig(jsonConfig);
      _lastConfigLoad = DateTime.now();

      if (config.allEvents.isNotEmpty) {
        // On initial load, find current event, if any
        int eventIndex =
            initial ? config.allEvents.indexWhere((e) => e.isCurrent) : -1;
        // If no current events, use stored event index and default to 0
        if (eventIndex == -1) {
          eventIndex = widget.sharedPreferences.getInt(_EVENT_INDEX_KEY)
              ?.clamp(0, config.allEvents.length - 1)
              ?? _DEFAULT_EVENT_INDEX;
        }
        await _switchToEvent(config.allEvents[eventIndex], eventIndex);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stackTrace) {
      debugPrint('$e');
      debugPrintStack(stackTrace: stackTrace);
    }

    return _config != null;
  }

  Future<dynamic> _loadJson(final String url) async {
    String? jsonString;
    if (url.startsWith('http')) {
      try {
        final file = await _configCacheManager.getSingleFile(url).timeout(_LOAD_TIMEOUT);
        jsonString = file.readAsStringSync();
      } on Exception {
        jsonString = null;
      }
    } else {
      jsonString = await rootBundle.loadString(url);
    }

    return jsonString != null ? jsonDecode(jsonString) : null;
  }

  GlobalEvent? get _currentEvent =>
      _config?.allEvents.elementAtOrNull(_currentEventIndex);

  @override
  Widget build(final BuildContext context) {
    final currentEvent = _currentEvent;
    final title = currentEvent?.title ?? _config?.title ?? LText(APP_TITLE);
    final primarySwatch = currentEvent?.primarySwatch ?? widget.initialPrimarySwatch;
    final secondaryColor = currentEvent?.secondaryColor ?? widget.initialSecondaryColor ?? _DEFAULT_SECONDARY_COLOR;

    return StreamBuilder<Locale>(
      stream: _localeStreamController.stream,
      initialData: widget.initialLocale,
      builder: (_, localeSnapshot) {
        final locale = localeSnapshot.hasData
            ? localeSnapshot.data
            : Localizations.maybeLocaleOf(context);
        final theme = ThemeData(
          primarySwatch: primarySwatch,
          fontFamily: 'AppFontFamily',
        );
        return MaterialApp(
          onGenerateTitle: (context) => title.get(locale ?? Localizations.localeOf(context)),
          theme: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              secondary: secondaryColor,
            ),
          ),
          home: _homePage,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: _supportedLocales,
          locale: locale,
        );
      },
    );
  }

  Widget get _homePage {
    final config = _config;
    final currentEvent = _currentEvent;
    if (config != null && currentEvent != null && _mode == _CaDansaAppStateMode.done) {
      return CaDansaEventPage(
        event: Event(currentEvent, _currentEventConfig, EventConstants(_currentEventConfig, config.defaults)),
        initialAction: _initialAction,
        buildDrawer:_buildDrawer,
        sharedPreferences: widget.sharedPreferences,
        moveToEvent: _switchToEventById,
        key: ValueKey(_currentEventIndex),
      );
    } else if (_mode == _CaDansaAppStateMode.loading) {
      return const LoadingPage();
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
            isSelected: index == _currentEventIndex,
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
      SafeArea(
        left: false,
        top: false,
        right: false,
        child: Row(
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
        ),
      ),
    ];

    if (kDebugMode) {
      bottomWidgets.add(ElevatedButton.icon(
        onPressed: _forceReload,
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
    _currentEventConfig = await _loadJson(event.configUri);
    _initialAction = null;

    await widget.sharedPreferences.setInt(_EVENT_INDEX_KEY, index);

    {
      final primarySwatch = event.primarySwatch;
      if (primarySwatch != null) {
        await widget.sharedPreferences.setInt(PRIMARY_SWATCH_COLOR_KEY, primarySwatch.value);
      } else {
        await widget.sharedPreferences.remove(PRIMARY_SWATCH_COLOR_KEY);
      }
    }

    {
      final secondaryColorIndex = event.secondaryColor;
      if (secondaryColorIndex != null) {
        await widget.sharedPreferences.setInt(SECONDARY_COLOR_KEY, secondaryColorIndex.value);
      } else {
        await widget.sharedPreferences.remove(SECONDARY_COLOR_KEY);
      }
    }
  }

  Future<void> _switchToEventById({required final String eventId, required final String action}) async {
    final config = _config;
    if (config == null) return;

    final targetEvent =
    config.allEvents.asMap().entries.firstWhereOrNull((event) => event.value.id == eventId);
    if (targetEvent == null) return;

    await _switchToEvent(targetEvent.value, targetEvent.key);
    if (mounted) {
      setState(() {
        _initialAction = action;
      });
    }
  }

  Future<void> _setLocale(final Locale locale) async {
    _localeStreamController.add(locale);

    await widget.sharedPreferences.setStringList(
        LOCALE_KEY,
        [locale.languageCode, locale.scriptCode, locale.countryCode]
            .whereNotNull()
            .toList());
  }

  Future<void> _forceReload() async {
    await _configCacheManager.emptyCache();
    await _resetConfig(force: true);
  }

  Iterable<Locale> get _supportedLocales =>
      _config?.locales ?? _DEFAULT_LOCALES;

  Future<void> _showTerms(final BuildContext context, final Legal legal) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
      final locale = Localizations.localeOf(context);
      return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: Theme.of(context).systemUiOverlayStyle,
          title: Text(legal.labelTerms.get(locale)),
        ),
        body: Html(
          data: '<h1>${widget.packageInfo.appName}</h1>${legal.terms.get(locale)}',
        ),
      );
    }));
  }

  Future<void> _showAbout(final BuildContext context, final Legal legal) async {
    final locale = Localizations.localeOf(context);
    final year = DateFormat.y(locale.toLanguageTag()).format(DateTime.now());
    showAboutDialog(
      context: context,
      applicationName: widget.packageInfo.appName,
      applicationLegalese: 'Copyright © $year ${legal.copyright.get(locale)}',
      applicationVersion: '${widget.packageInfo.version} (${widget.packageInfo.buildNumber})',
    );
  }

  Future<void> _onSelectNotification(final String? payload) async {
    if (mounted && payload != null && payload.isNotEmpty) {
      setState(() {
        _initialAction = payload;
      });
    }
  }

  @override
  void dispose() {
    _localeStreamController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

  static final _JsonCacheManager _instance = _JsonCacheManager._();
}
