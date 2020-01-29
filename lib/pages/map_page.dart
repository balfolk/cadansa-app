import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/widgets/map.dart';
import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  final String _title;
  final MapData _mapData;
  final BottomNavigationBar Function() _bottomBarGenerator;
  final ActionHandler _actionHandler;

  MapPage(this._title, this._mapData, this._bottomBarGenerator, this._actionHandler, {final Key key})
      : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(final BuildContext context) {
    return DefaultTabController(
      length: widget._mapData.floors.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._title),
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(
          children: tabChildren,
          physics: const NeverScrollableScrollPhysics(),
        ),
        bottomNavigationBar: widget._bottomBarGenerator(),
      ),
    );
  }

  List<Tab> get tabs {
    final Locale locale = Localizations.localeOf(context);
    return widget._mapData.floors.map((flooar) {
      return Tab(text: flooar.title.get(locale));
    }).toList(growable: false);
  }

  List<Widget> get tabChildren {
    return widget._mapData.floors
        .map((floor) => MapWidget(floor, widget._actionHandler))
        .toList(growable: false);
  }
}
