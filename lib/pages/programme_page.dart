import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/widgets/favorite_button.dart';
import 'package:cadansa_app/widgets/programme_items_list.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgrammePage extends StatefulWidget {
  const ProgrammePage({
    required this.programme,
    required this.event,
    required this.pageHooks,
    required this.pageController,
    required this.sharedPreferences,
    required this.openItemId,
    required this.getFavorites,
    required this.setFavorite,
    final Key? key,
  }) : super(key: key);

  final Programme programme;
  final Event event;
  final PageHooks pageHooks;
  final IndexedPageController pageController;
  final SharedPreferences sharedPreferences;
  final String? openItemId;
  final Set<String> Function() getFavorites;
  final Future<bool> Function(ProgrammeItem) setFavorite;

  static const _EXPANDABLE_THEME = ExpandableThemeData(
    tapBodyToCollapse: true,
  );

  @override
  _ProgrammePageState createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    initialIndex: _initialIndex,
    length: widget.programme.days.length,
    vsync: this,
  )..addListener(() {
    widget.pageController.index = _tabController.index;
    widget.sharedPreferences.setInt(PAGE_SUB_INDEX_KEY, _tabController.index);
  });

  @override
  Widget build(final BuildContext context) => ExpandableTheme(
    data: ProgrammePage._EXPANDABLE_THEME,
    child: widget.pageHooks.buildScaffold(
      appBarBottomWidget: TabBar(
        controller: _tabController,
        tabs: tabs,
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabChildren.toList(growable: false),
      ),
    ),
  );

  int get _initialIndex {
    final index = widget.pageController.index;
    if (index != null) {
      return index.clamp(0, widget.programme.days.length - 1);
    }

    final now = DateTime.now();
    return widget.pageController.index = widget.programme.days
        .map((day) => day.startsOn)
        .toList(growable: false)
        .indexWhere((startsOn) => startsOn != null && now.difference(startsOn).inDays < 1)
        .clamp(0, widget.programme.days.length - 1);
  }

  List<Tab> get tabs {
    final locale = Localizations.localeOf(context);
    final autoSizeGroup = AutoSizeGroup();
    return widget.programme.days.map((day) {
      return Tab(
        child: AutoSizeText(
          day.name.get(locale),
          maxLines: 1,
          minFontSize: 11.0,
          group: autoSizeGroup,
        ),
      );
    }).toList(growable: false);
  }

  Iterable<Widget> get tabChildren {
    final favorites = widget.getFavorites();
    return widget.programme.days.map((day) => ProgrammeItemsList(
      day: day,
      openIndex: _getOpenItemIndex(day),
      trailing: (item) => _canFavorite && item.canFavorite ? FavoriteButton(
        isFavorite: favorites.contains(item.id),
        innerColor: widget.programme.favoriteInnerColor,
        outerColor: widget.programme.favoriteOuterColor,
        onPressed: () => _onFavoritePressed(item),
        tooltip: widget.programme.favoriteTooltip,
      ) : null,
      doColorIcons: widget.event.doColorIcons,
      actionHandler: widget.pageHooks.actionHandler,
    ));
  }

  int? _getOpenItemIndex(final ProgrammeDay day) {
    final openItemId = widget.openItemId;
    if (openItemId == null) return null;

    final index = day.items.indexWhere((item) => item.id == widget.openItemId);
    if (index < 0) return null;
    return index;
  }

  bool get _canFavorite =>
      widget.programme.supportsFavorites && widget.event.canFavorite;

  void _onFavoritePressed(final ProgrammeItem item) {
    widget.setFavorite(item);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
