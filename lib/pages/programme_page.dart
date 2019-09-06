import 'package:cadansa_app/data/global_conf.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/widgets/programme_item_body.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProgrammePage extends StatefulWidget {
  final String _title;
  final Programme _programme;
  final BottomNavigationBar Function() _bottomBarGenerator;

  ProgrammePage(this._title, this._programme, this._bottomBarGenerator,
      {final Key key}) : super(key: key);

  @override
  _ProgrammePageState createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  @override
  Widget build(final BuildContext context) {
    return DefaultTabController(
        initialIndex: _initialIndex,
        length: widget._programme.days.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget._title),
            bottom: TabBar(tabs: tabs),
          ),
          body: TabBarView(children: tabChildren),
          bottomNavigationBar: widget._bottomBarGenerator(),
        ));
  }

  int get _initialIndex {
    final now = DateTime.now();
    return widget._programme.days
        .lastIndexWhere((day) => day.startsOn.isBefore(now))
        .clamp(0, widget._programme.days.length - 1);
  }

  List<Tab> get tabs {
    final Locale locale = Localizations.localeOf(context);
    return widget._programme.days.map((day) {
      return Tab(text: day.name.get(locale));
    }).toList(growable: false);
  }

  List<Widget> get tabChildren {
    final ThemeData theme = Theme.of(context);
    return widget._programme.days.asMap().entries.map((entry) {
      final ProgrammeDay day = entry.value;
      return ListView.separated(
        itemCount: day.items.length,
        itemBuilder: (context, index) {
          final ProgrammeItem item = day.items[index];
          return ExpandableNotifier(
            child: ScrollOnExpand(
              child: ExpandablePanel(
                header: ListTile(
                  leading: _showIcon(day, item, false) ? _getIcon(
                      item, theme.accentColor) : null,
                  title: Text(
                    _formatItemName(item),
                    style: theme.textTheme.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                  subtitle: Text('${item.startTime.format(context)} – ${item.endTime.format(context)}'),
                ),
                expanded: ProgrammeItemBody(item),
                tapBodyToCollapse: true,
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
      );
    }).toList(growable: false);
  }

  String _formatItemName(final ProgrammeItem item) {
    final Locale locale = Localizations.localeOf(context);
    const int DIFF_FLAG_LETTER = 127462 - 65;
    final stringToUnicodeFlag = (String s) =>
        String.fromCharCodes(s.codeUnits.map((cu) => cu + DIFF_FLAG_LETTER));
    return '${item.name.get(locale)} ${item.countries.map(stringToUnicodeFlag).join(' ')}';
  }

  static bool _showIcon(final ProgrammeDay day, final ProgrammeItem item, final bool isExpanded) {
    switch (item.kind.showIcon) {
      case ProgrammeItemKindShowIcon.always:
        return true;
      case ProgrammeItemKindShowIcon.during:
        return _isPlaying(day, item);
      case ProgrammeItemKindShowIcon.unexpanded:
        return !isExpanded;
      case ProgrammeItemKindShowIcon.never:
      default:
        return false;
    }
  }

  static bool _isPlaying(final ProgrammeDay day, final ProgrammeItem item) {
    // Anything with hours smaller than this number is in the "wee hours" and takes place on the preceding day
    const int HOUR_NIGHT_CUTOFF = 6;

    final DateTime startDay =
        DateTime(day.startsOn.year, day.startsOn.month, day.startsOn.day);
    final startMoment = startDay.add(Duration(
        days: item.startTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: item.startTime.hour,
        minutes: item.startTime.minute));
    final endMoment = startDay.add(Duration(
        days: item.endTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: item.endTime.hour,
        minutes: item.endTime.minute));
    final now = DateTime.now();
    return now.isAfter(startMoment) && now.isBefore(endMoment);
  }

  static Widget _getIcon(final ProgrammeItem item, final Color color) {
    final IconData iconData = MdiIcons.fromString(item.kind.icon);
    if (iconData == null) return null;
    return Icon(iconData,
      color: color,
      size: 36,
    );
  }
}
