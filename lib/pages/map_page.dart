import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/widgets/map.dart';
import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  final LText _title;
  final MapData _mapData;
  final Widget Function(BuildContext) _buildDrawer;
  final Widget Function() _buildBottomBar;
  final ActionHandler _actionHandler;
  final int _initialFloorIndex, _highligtAreaIndex;

  MapPage(this._title, this._mapData, this._buildDrawer, this._buildBottomBar, this._actionHandler, this._initialFloorIndex, this._highligtAreaIndex, {final Key key})
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
          children: tabChildren,
          physics: const NeverScrollableScrollPhysics(),
        ),
        drawer: widget._buildDrawer(context),
        bottomNavigationBar: widget._buildBottomBar(),
      ),
    );
  }

  List<Tab> get tabs {
    final Locale locale = Localizations.localeOf(context);
    return widget._mapData.floors.map((floor) {
      return Tab(text: floor.title.get(locale));
    }).toList(growable: false);
  }

  List<Widget> get tabChildren {
    return widget._mapData.floors
        .asMap().entries
        .map((floor) => MapWidget(
          floor.value,
          widget._actionHandler,
          floor.key == widget._initialFloorIndex ? widget._highligtAreaIndex : null,
        ))
        .toList(growable: false);
  }
}
