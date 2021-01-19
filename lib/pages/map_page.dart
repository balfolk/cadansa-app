import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/widgets/map.dart';
import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  final LText _title;
  final MapData _mapData;
  final PageHooks _pageHooks;
  final int _initialFloorIndex, _highlightAreaIndex;

  MapPage(this._title, this._mapData, this._pageHooks, this._initialFloorIndex, this._highlightAreaIndex, {final Key key})
      : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DefaultTabController(
      length: widget._mapData.floors.length,
      initialIndex: widget._initialFloorIndex ?? 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._title.get(locale)),
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: tabChildren,
        ),
        drawer: widget._pageHooks.buildDrawer(context),
        bottomNavigationBar: widget._pageHooks.buildBottomBar(),
      ),
    );
  }

  List<Tab> get tabs {
    final locale = Localizations.localeOf(context);
    return widget._mapData.floors.map((floor) {
      return Tab(text: floor.title.get(locale));
    }).toList(growable: false);
  }

  List<Widget> get tabChildren {
    return widget._mapData.floors
        .asMap().entries
        .map((floor) => MapWidget(
          floor.value,
          widget._pageHooks.actionHandler,
          floor.key == widget._initialFloorIndex ? widget._highlightAreaIndex : null,
          key: ValueKey(floor.key),
        ))
        .toList(growable: false);
  }
}
