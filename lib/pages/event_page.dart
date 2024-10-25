import 'dart:async';

import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/notifications.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:format/format.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CaDansaEventPage extends StatefulWidget {
  const CaDansaEventPage({
    super.key,
    required this.event,
    required this.initialAction,
    required this.buildDrawer,
    required this.sharedPreferences,
    required this.packageInfo,
    required this.moveToEvent,
  });

  final Event event;
  final String? initialAction;
  final Widget? Function({required BuildContext context}) buildDrawer;
  final SharedPreferences sharedPreferences;
  final PackageInfo packageInfo;
  final void Function({required String eventId, required String action}) moveToEvent;

  @override
  CaDansaEventPageState createState() => CaDansaEventPageState();
}

class CaDansaEventPageState extends State<CaDansaEventPage> {
  int _currentIndex = _DEFAULT_PAGE_INDEX;

  int? _highlightAreaFloorIndex, _highlightAreaIndex;
  String? _openProgrammeItemId;

  late final PageHooks _pageHooks = PageHooks(
    actionHandler: _handleAction,
    buildScaffold: ({actions, appBarBottomWidget, required body}) {
      final locale = Localizations.localeOf(context);
      final popupMenuPages = widget.event.popupMenuPages;
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.event.title.get(locale)),
          actions: (actions ?? [])
              .followedBy(popupMenuPages.isNotEmpty
                  ? [
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (final context) => popupMenuPages.map((page) {
                          final title = page.title.get(locale);
                          return PopupMenuItem(
                            value: title,
                            child: ListTile(
                              leading: Icon(MdiIcons.fromString(page.icon)),
                              title: Text(title),
                            ),
                            onTap: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (final context) => _buildOverlayPage(
                                    page,
                                    context: context,
                                  ),
                                ),
                              ),
                            },
                          );
                        }).toList(growable: false),
                      ),
                    ]
                  : [])
              .toList(growable: false),
          bottom: appBarBottomWidget,
        ),
        body: body,
        drawer: widget.buildDrawer(context: context),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    },
  );
  late final _programmePageController = IndexedPageController();

  static const _DEFAULT_PAGE_INDEX = 0;
  static const _ACTION_SEPARATOR = ':',
      _ACTION_PAGE = 'page',
      _ACTION_URL = 'url',
      _ACTION_AREA = 'area',
      _ACTION_ITEM = 'item';

  @override
  void initState() {
    super.initState();
    _handleInitialAction();
  }

  @override
  void didUpdateWidget(final CaDansaEventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setCurrentIndex();
    _handleInitialAction();
  }

  void _setCurrentIndex([final int? newIndex]) {
    final newValidIndex = (newIndex ?? _currentIndex).clamp(0, widget.event.pages.length - 1);
    if (newValidIndex != _currentIndex) {
      _currentIndex = newValidIndex;
      _storePageIndex(newValidIndex);
    }
  }

  void _handleInitialAction() {
    _handleAction(widget.initialAction);
  }

  @override
  Widget build(final BuildContext context) {
    final key = Key('page$_currentIndex');
    _currentIndex = _currentIndex.clamp(0, widget.event.pages.length - 1);
    final pageData = widget.event.pages[_currentIndex];

    final page = _buildPage(
      pageData,
      pageHooks: _pageHooks,
      key: key,
    );

    _highlightAreaFloorIndex = null;
    _highlightAreaIndex = null;
    _openProgrammeItemId = null;

    return page;
  }

  Widget _buildPage(
    final PageData pageData, {
    required final PageHooks pageHooks,
    final Key? key,
  }) {
    return buildPage(
      pageData,
      event: widget.event,
      pageHooks: pageHooks,
      sharedPreferences: widget.sharedPreferences,
      highlightAreaFloorIndex: _highlightAreaFloorIndex,
      highlightAreaIndex: _highlightAreaIndex,
      openProgrammeItemId: _openProgrammeItemId,
      programmePageController: _programmePageController,
      getEventFavorites: _getEventFavorites,
      setFavorite: _setFavorite,
      getReadFeedGuids: _getReadFeedGuids,
      setReadFeedGuid: _setReadFeedGuid,
      key: key,
    );
  }

  Widget _buildOverlayPage(
    final PageData pageData, {
    required final BuildContext context,
  }) {
    final locale = Localizations.localeOf(context);
    final pageHooks = PageHooks(
      actionHandler: (final action) {
        Navigator.pop(context);
        return _handleAction(action);
      },
      buildScaffold: ({
        final actions,
        final appBarBottomWidget,
        required final body,
      }) =>
          Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(pageData.title.get(locale)),
        ),
        body: body,
      ),
    );
    return _buildPage(pageData, pageHooks: pageHooks);
  }

  Widget _buildBottomNavigationBar() {
    final locale = Localizations.localeOf(context);
    return NavigationBar(
      destinations: widget.event.pages
          .map((final pageData) => NavigationDestination(
                icon: Icon(MdiIcons.fromString(pageData.icon)),
                label: pageData.title.get(locale),
              ))
          .toList(growable: false),
      onDestinationSelected: (final index) {
        _selectPage(index);
        _storePageIndex(index);
      },
      selectedIndex: _currentIndex,
    );
  }

  Future<void> _handleAction(final String? action) async {
    final split = action?.split(_ACTION_SEPARATOR);
    if (action == null || split == null || split.isEmpty) {
      debugPrint('Unprocessed action: $action');
      return;
    }

    switch (split.first) {
      case _ACTION_PAGE:
        int? pageIndex, subPageIndex;
        if (split.length >= 2) {
          pageIndex = int.tryParse(split[1]);
          if (split.length >= 3) {
            subPageIndex = int.tryParse(split[2]);
          }
        }
        _selectPage(pageIndex, subPageIndex);
        break;
      case _ACTION_URL:
        final url = action.substring('$_ACTION_URL$_ACTION_SEPARATOR'.length);
        final locale = Localizations.localeOf(context);
        await _launchUrl(LText(url).get(locale));
        break;
      case _ACTION_AREA:
        final areaId = action.substring('$_ACTION_AREA$_ACTION_SEPARATOR'.length);
        _selectArea(areaId);
        break;
      case _ACTION_ITEM:
        String? eventId, itemId;
        if (split.length >= 3) {
          // Interpret the action as eventId:itemId
          eventId = split[1];
          itemId = split[2];
        } else if (split.length >= 2) {
          // Interpret the action as itemId
          itemId = split[1];
        }

        if (eventId != null && eventId.isNotEmpty && eventId != widget.event.id) {
          widget.moveToEvent(eventId: eventId, action: action);
        } else if (itemId != null && itemId.isNotEmpty) {
          int? foundDayIndex;
          final int foundPageIndex = widget.event.pages.indexWhere((page) {
            // Don't try to shortcut this with a whereType<ProgrammePageData>,
            // as that'll mangle the returned page index.
            if (page is! ProgrammePageData) return false;
            final dayIndex = page.programme.days.indexWhere(
                (day) => day.items.any((item) => item.id == itemId));
            if (dayIndex >= 0) {
              foundDayIndex = dayIndex;
              return true;
            }
            return false;
          });
          if (foundPageIndex >= 0 && foundDayIndex != null) {
            _selectPage(foundPageIndex, foundDayIndex, itemId);
          }
        }
    }
  }

  void _selectPage(final int? pageIndex, [final int? subPageIndex, final String? openProgrammeItemId]) {
    if (!mounted || pageIndex == null) return;

    setState(() {
      _setCurrentIndex(pageIndex);
      if (subPageIndex != null) {
        _programmePageController.index = subPageIndex;
      }
      _openProgrammeItemId = openProgrammeItemId;
    });
  }

  Future<void> _launchUrl(final String? url) async {
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri);
      }
    }
  }

  void _selectArea(final String? areaId) {
    if (areaId == null) return;

    int? pageIndex, floorIndex, areaIndex;
    for (final page in widget.event.pages.asMap().entries) {
      if (page.value is MapPageData) {
        for (final floor in (page.value as MapPageData).mapData.floors.asMap().entries) {
          final area = floor.value.areas.indexWhere((area) => area.id == areaId);
          if (area != -1) {
            pageIndex = page.key;
            floorIndex = floor.key;
            areaIndex = area;
            break;
          }
        }
      }
    }

    if (mounted && pageIndex != null && floorIndex != null && areaIndex != null) {
      setState(() {
        _setCurrentIndex(pageIndex);
        _highlightAreaFloorIndex = floorIndex;
        _highlightAreaIndex = areaIndex;
      });
    }
  }

  Future<void> _storePageIndex(final int index) async {
    await widget.sharedPreferences.setInt(PAGE_INDEX_KEY, index);
  }

  Set<String> _getEventFavorites() {
    return widget.sharedPreferences
        .getStringList(_favoritesPreferencesKey)?.toSet() ?? {};
  }

  Future<bool> _setFavorite({
    required final ProgrammeDay day,
    required final ProgrammeItem item,
  }) async {
    final id = item.id;
    if (id == null) return false;

    final itemStart = day.rangeOfItem(item)?.start;
    if (itemStart == null) return false;

    final locale = Localizations.localeOf(context);
    final formatMap = {
      'appName': widget.packageInfo.appName,
      'name': item.name.get(locale),
      'event': widget.event.title.get(locale),
      'days': widget.event.constants.notificationTimeBefore.inDays.toString(),
      'hours': widget.event.constants.notificationTimeBefore.inHours.toString(),
      'minutes': widget.event.constants.notificationTimeBefore.inMinutes.toString(),
      'seconds': widget.event.constants.notificationTimeBefore.inSeconds.toString(),
    };

    final favorites = _getEventFavorites();
    if (favorites.contains(id)) {
      favorites.remove(id);
      _maybeShowSnackBar(widget.event.constants.unfavoriteSnackText.get(locale).format(formatMap));
      await cancelNotification(id: id);
    } else {
      final notificationTime = kDebugMode
          ? DateTime.now().add(const Duration(seconds: 5))
          : itemStart.subtract(widget.event.constants.notificationTimeBefore);
      if (await addNotification(
        id: id,
        eventId: widget.event.id,
        title: widget.event.constants.notificationTitle.get(locale).format(formatMap),
        body: widget.event.constants.notificationBody.get(locale).format(formatMap),
        payload: '$_ACTION_ITEM$_ACTION_SEPARATOR${widget.event.id}$_ACTION_SEPARATOR$id',
        color: widget.event.seedColor,
        when: notificationTime,
        whenStart: itemStart,
      )) {
        favorites.add(id);
        _maybeShowSnackBar(widget.event.constants.favoriteSnackText.get(locale).format(formatMap));
      } else {
        _maybeShowSnackBar(widget.event.constants.favoriteErrorSnackText.get(locale).format(formatMap));
      }
    }

    return widget.sharedPreferences
        .setStringList(_favoritesPreferencesKey, favorites.toList());
  }

  /// Show a [SnackBar] if possible and if the provided text is not empty.
  void _maybeShowSnackBar(final String text) {
    if (text.isNotEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(text),
      ));
    }
  }

  String get _favoritesPreferencesKey => 'favorites_${widget.event.id}';

  Set<String> _getReadFeedGuids() {
    return widget.sharedPreferences
        .getStringList(_readGuidsPreferencesKey)?.toSet() ?? {};
  }

  Future<void> _setReadFeedGuid(final String? guid) async {
    if (guid != null) {
      await widget.sharedPreferences.setStringList(_readGuidsPreferencesKey,
          _getReadFeedGuids().followedBy([guid]).toList());
    }
  }

  String get _readGuidsPreferencesKey => 'read_${widget.event.id}';
}
