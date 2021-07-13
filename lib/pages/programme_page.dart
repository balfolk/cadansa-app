import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/util/temporal_state.dart';
import 'package:cadansa_app/widgets/favorite_button.dart';
import 'package:cadansa_app/widgets/programme_item_body.dart';
import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ProgrammePage extends StatefulWidget {
  const ProgrammePage({
    required this.programme,
    required this.event,
    required this.pageHooks,
    required this.pageController,
    required this.getFavorites,
    required this.setFavorite,
    final Key? key,
  }) : super(key: key);

  final Programme programme;
  final Event event;
  final PageHooks pageHooks;
  final IndexedPageController pageController;
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
        children: tabChildren,
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
        .whereNotNull().toList(growable: false)
        .indexWhere((startsOn) => now.difference(startsOn).inDays < 1)
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

  List<Widget> get tabChildren {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final favorites = widget.getFavorites();
    return widget.programme.days.asMap().entries.map((entry) {
      final day = entry.value;
      return ListView.separated(
        itemCount: day.items.length,
        itemBuilder: (context, index) {
          final item = day.items[index];
          final isExpandable = item.description.get(locale).isNotEmpty;
          final startTime = item.startTime;
          final endTime = item.endTime;

          String text;
          if (endTime != null) {
            text = '${startTime.format(context)} – ${endTime.format(context)}';
          } else {
            text = startTime.format(context);
          }
          final subtitle = Text(text);

          final Widget header = ListTile(
            leading: _getIcon(day, item),
            title: AutoSizeText(
              _formatItemName(item),
              style: theme.textTheme.headline6,
              maxLines: 2,
              softWrap: true,
            ),
            trailing: _canFavorite && item.canFavorite ? FavoriteButton(
              isFavorite: favorites.contains(item.id),
              innerColor: widget.programme.favoriteInnerColor,
              outerColor: widget.programme.favoriteOuterColor,
              onPressed: () => _onFavoritePressed(item),
              tooltip: widget.programme.favoriteTooltip,
            ) : null,
            subtitle: subtitle,
          );

          if (isExpandable) {
            return ExpandableNotifier(
              child: ScrollOnExpand(
                child: ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                  ),
                  header: header,
                  collapsed: const SizedBox.shrink(),
                  expanded: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 15.0, bottom: 10.0),
                    child: ProgrammeItemBody(
                      item: item,
                      actionHandler: widget.pageHooks.actionHandler,
                    ),
                  ),
                ),
              ),
            );
          } else {
            return header;
          }
        },
        separatorBuilder: (context, index) => const Divider(),
      );
    }).toList(growable: false);
  }

  String _formatItemName(final ProgrammeItem item) {
    final locale = Localizations.localeOf(context);
    return '${item.name.get(locale)} ${item.countries.map(stringToUnicodeFlag).join(' ')}';
  }

  bool get _canFavorite =>
      widget.programme.supportsFavorites && widget.event.canFavorite;

  void _onFavoritePressed(final ProgrammeItem item) {
    widget.setFavorite(item);
    setState(() {});
  }

  static TemporalState? _getPlayingStatus(final ProgrammeDay day, final ProgrammeItem item) {
    // Anything with hours smaller than this number is in the "wee hours" and takes place on the preceding day
    const HOUR_NIGHT_CUTOFF = 6;

    final dayStartsOn = day.startsOn;
    final itemStartTime = item.startTime;
    if (dayStartsOn == null) {
      return null;
    }

    final startDay =
        DateTime(dayStartsOn.year, dayStartsOn.month, dayStartsOn.day);
    final startMoment = startDay.add(Duration(
        days: itemStartTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: itemStartTime.hour,
        minutes: itemStartTime.minute));
    final itemEndTime = item.endTime;
    final endMoment = itemEndTime != null ? startDay.add(Duration(
        days: itemEndTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: itemEndTime.hour,
        minutes: itemEndTime.minute)) : null;
    final now = DateTime.now();
    if (now.isBefore(startMoment)) return TemporalState.future;
    if (endMoment != null) {
      if (now.isAfter(endMoment)) return TemporalState.past;
      return TemporalState.present;
    } else {
      return TemporalState.past;
    }
  }

  Widget? _getIcon(final ProgrammeDay day, final ProgrammeItem item) {
    final itemKindIcon = item.kind.icon;
    if (itemKindIcon == null) return null;

    final iconData = MdiIcons.fromString(itemKindIcon);
    if (iconData?.codePoint == null) {
      debugPrint('Invalid icon $itemKindIcon');
      return null;
    }

    final status = _getPlayingStatus(day, item);
    if (item.kind.showIcon == ProgrammeItemKindShowIcon.never ||
        (item.kind.showIcon == ProgrammeItemKindShowIcon.during &&
            status != TemporalState.present)) {
      return null;
    }

    // Icons for the current event may be shown as grey, when they are in the past
    final color = widget.event.doColorIcons &&
            (status == null || status == TemporalState.past)
        ? Colors.grey
        : Theme.of(context).primaryColor;

    final icon = Icon(iconData,
      color: color,
      size: 36,
    );

    if (status == TemporalState.present) {
      return Shimmer.fromColors(
        baseColor: Theme.of(context).primaryColor,
        highlightColor: Theme.of(context).primaryColorLight,
        child: icon,
      );
    } else {
      return icon;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
