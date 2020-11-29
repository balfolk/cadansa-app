import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/widgets/programme_item_body.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ProgrammePage extends StatefulWidget {
  final LText _title;
  final Programme _programme;
  final Widget Function(BuildContext) _buildDrawer;
  final Widget Function() _buildBottomBar;
  final ActionHandler _actionHandler;

  static const _EXPANDABLE_THEME = ExpandableThemeData(
    tapBodyToCollapse: true,
  );

  ProgrammePage(this._title, this._programme, this._buildDrawer,
      this._buildBottomBar, this._actionHandler, {final Key key})
      : super(key: key);

  @override
  _ProgrammePageState createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    return ExpandableTheme(
      data: ProgrammePage._EXPANDABLE_THEME,
      child: DefaultTabController(
        initialIndex: _initialIndex,
        length: widget._programme.days.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget._title.get(locale)),
            bottom: TabBar(tabs: tabs),
          ),
          body: TabBarView(children: tabChildren),
          drawer: widget._buildDrawer(context),
          bottomNavigationBar: widget._buildBottomBar(),
        ),
      ),
    );
  }

  int get _initialIndex {
    final now = DateTime.now();
    return widget._programme.days
        .lastIndexWhere((day) => day.startsOn.isBefore(now))
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
    final theme = Theme.of(context);
    return widget._programme.days.asMap().entries.map((entry) {
      final day = entry.value;
      return ListView.separated(
        itemCount: day.items.length,
        itemBuilder: (context, index) {
          final item = day.items[index];

          Widget subtitle;
          if (item.startTime != null || item.endTime != null) {
            String text;
            if (item.startTime != null && item.endTime != null) {
              text = '${item.startTime.format(context)} – ${item.endTime.format(context)}';
            } else {
              text = (item.startTime ?? item.endTime).format(context);
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

          if (item.description != null) {
            return ExpandableNotifier(
              child: ScrollOnExpand(
                child: ExpandablePanel(
                  header: header,
                  expanded: ProgrammeItemBody(item, widget._actionHandler),
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

  static _PlayingStatus _getPlayingStatus(final ProgrammeDay day, final ProgrammeItem item) {
    // Anything with hours smaller than this number is in the "wee hours" and takes place on the preceding day
    const HOUR_NIGHT_CUTOFF = 6;

    final startDay =
        DateTime(day.startsOn.year, day.startsOn.month, day.startsOn.day);
    final startMoment = startDay.add(Duration(
        days: item.startTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: item.startTime.hour,
        minutes: item.startTime.minute));
    final endMoment = item.endTime != null ? startDay.add(Duration(
        days: item.endTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: item.endTime.hour,
        minutes: item.endTime.minute)) : null;
    final now = DateTime.now();
    if (now.isBefore(startMoment)) return _PlayingStatus.before;
    if (endMoment != null) {
      if (now.isAfter(endMoment)) return _PlayingStatus.after;
      return _PlayingStatus.during;
    } else {
      return _PlayingStatus.after;
    }
  }

  Widget _getIcon(final ProgrammeDay day, final ProgrammeItem item) {
    final iconData = MdiIcons.fromString(item.kind.icon);
    if (iconData?.codePoint == null) {
      print('Invalid icon ${item.kind.icon}');
      return null;
    }

    final status = _getPlayingStatus(day, item);
    final color = status == _PlayingStatus.after
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
}

enum _PlayingStatus { before, during, after }
