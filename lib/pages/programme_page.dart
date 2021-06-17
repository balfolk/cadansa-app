import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/widgets/programme_item_body.dart';
import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ProgrammePage extends StatefulWidget {
  final LText _title;
  final Programme _programme;
  final PageHooks _pageHooks;
  final IndexedPageController _pageController;

  static const _EXPANDABLE_THEME = ExpandableThemeData(
    tapBodyToCollapse: true,
  );

  const ProgrammePage(
      this._title, this._programme, this._pageHooks, this._pageController,
      {final Key? key})
      : super(key: key);

  @override
  _ProgrammePageState createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    initialIndex: _initialIndex,
    length: widget._programme.days.length,
    vsync: this,
  )..addListener(() {
    widget._pageController.index = _tabController.index;
  });

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    return ExpandableTheme(
      data: ProgrammePage._EXPANDABLE_THEME,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._title.get(locale)),
          bottom: TabBar(
            controller: _tabController,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: tabChildren,
        ),
        drawer: widget._pageHooks.buildDrawer(() => this.context),
        bottomNavigationBar: widget._pageHooks.buildBottomBar(),
      ),
    );
  }

  int get _initialIndex {
    final index = widget._pageController.index;
    if (index != null) {
      return index.clamp(0, widget._programme.days.length - 1);
    }

    final now = DateTime.now();
    return widget._pageController.index = widget._programme.days
        .map((day) => day.startsOn)
        .whereNotNull().toList(growable: false)
        .indexWhere((startsOn) => now.difference(startsOn).inDays < 1)
        .clamp(0, widget._programme.days.length - 1);
  }

  List<Tab> get tabs {
    final locale = Localizations.localeOf(context);
    final autoSizeGroup = AutoSizeGroup();
    return widget._programme.days.map((day) {
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
    return widget._programme.days.asMap().entries.map((entry) {
      final day = entry.value;
      return ListView.separated(
        itemCount: day.items.length,
        itemBuilder: (context, index) {
          final item = day.items[index];
          final startTime = item.startTime;
          final endTime = item.endTime;

          Widget? subtitle;
          if (startTime != null || endTime != null) {
            String text;
            if (startTime != null && endTime != null) {
              text = '${startTime.format(context)} – ${endTime.format(context)}';
            } else {
              text = (startTime ?? endTime)!.format(context);
            }
            subtitle = Text(text);
          }

          final Widget header = ListTile(
            leading: _showIcon(day, item, false) ? _getIcon(day, item) : null,
            title: AutoSizeText(
              _formatItemName(item),
              style: theme.textTheme.headline6,
              maxLines: 2,
              softWrap: true,
            ),
            subtitle: subtitle,
          );

          if (item.description.get(locale).isNotEmpty) {
            return ExpandableNotifier(
              child: ScrollOnExpand(
                child: ExpandablePanel(
                  header: header,
                  collapsed: const SizedBox.shrink(),
                  expanded: ProgrammeItemBody(item, widget._pageHooks.actionHandler),
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
    return '${item.name.get(locale)} ${item.countries.map(stringToUnicodeFlag).join(' ')}';
  }

  static bool _showIcon(final ProgrammeDay day, final ProgrammeItem item, final bool isExpanded) {
    switch (item.kind.showIcon) {
      case ProgrammeItemKindShowIcon.always:
        return true;
      case ProgrammeItemKindShowIcon.during:
        return _getPlayingStatus(day, item) == _PlayingStatus.during;
      case ProgrammeItemKindShowIcon.unexpanded:
        return !isExpanded;
      case ProgrammeItemKindShowIcon.never:
      default:
        return false;
    }
  }

  static _PlayingStatus? _getPlayingStatus(final ProgrammeDay day, final ProgrammeItem item) {
    // Anything with hours smaller than this number is in the "wee hours" and takes place on the preceding day
    const HOUR_NIGHT_CUTOFF = 6;

    final dayStartsOn = day.startsOn;
    final itemStartTime = item.startTime;
    if (dayStartsOn == null || itemStartTime == null) {
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
    if (now.isBefore(startMoment)) return _PlayingStatus.before;
    if (endMoment != null) {
      if (now.isAfter(endMoment)) return _PlayingStatus.after;
      return _PlayingStatus.during;
    } else {
      return _PlayingStatus.after;
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
    final color = status == null || status == _PlayingStatus.after
        ? Colors.grey
        : Theme.of(context).primaryColor;

    final icon = Icon(iconData,
      color: color,
      size: 36,
    );

    if (status == _PlayingStatus.during) {
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

enum _PlayingStatus { before, during, after }
