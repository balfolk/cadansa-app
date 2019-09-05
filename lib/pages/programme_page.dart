import 'package:cadansa_app/data/programme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgrammePage extends StatefulWidget {
  final String _title;
  final Programme _programme;
  final BottomNavigationBar Function() _bottomBarGenerator;

  ProgrammePage(this._title, this._programme, this._bottomBarGenerator);

  @override
  _ProgrammePageState createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  final Map<ProgrammeDay, List<bool>> _expansions = {};

  @override
  void initState() {
    super.initState();
    widget._programme.days.forEach(
        (day) => _expansions[day] = List.filled(day.items.length, false));
  }

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
    final Locale locale = Localizations.localeOf(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle urlStyle = theme.textTheme.body2.copyWith(color: theme.primaryColor);
    return widget._programme.days.asMap().entries.map((entry) {
      final ProgrammeDay day = entry.value;
      return SingleChildScrollView(
          child: ExpansionPanelList(
        children: day.items.asMap().entries.map((entry) {
          final ProgrammeItem item = entry.value;
          return ExpansionPanel(
            headerBuilder: (_, __) => ListTile(
                  leading: _isPlayingNow(day, item)
                      ? Icon(
                          Icons.music_note,
                          color: theme.accentColor,
                          size: 36,
                        )
                      : null,
                  title: Text(
                    _formatItemName(item),
                    style: theme.textTheme.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                  subtitle: Text(
                      '${item.startTime.format(context)} – ${item.endTime.format(context)}'),
                ),
            body: Column(children: <Widget>[
              Container(
                child: Text(item.description.get(locale)),
                padding: EdgeInsetsDirectional.only(
                    start: 20.0, end: 20.0, bottom: 20.0),
              ),
              OutlineButton.icon(
                onPressed: () => launch(item.website),
                label: Text('Website', style: urlStyle,),
                icon: Icon(Icons.link),
              ),
            ]),
            isExpanded: _expansions[day][entry.key],
            canTapOnHeader: true,
          );
        }).toList(growable: false),
        expansionCallback: (index, isExpanded) => setState(() {
              _expansions[day][index] = !isExpanded;
            }),
      ));
    }).toList(growable: false);
  }

  static String _formatItemName(final ProgrammeItem item) {
    const int DIFF_FLAG_LETTER = 127462 - 65;
    final stringToUnicodeFlag = (String s) =>
        String.fromCharCodes(s.codeUnits.map((cu) => cu + DIFF_FLAG_LETTER));
    return '${item.name} ${item.countries.map(stringToUnicodeFlag).join(' ')}';
  }

  static bool _isPlayingNow(final ProgrammeDay day, final ProgrammeItem item) {
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
}
