import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/widgets/map.dart';
import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.mapData,
    required this.pageHooks,
    required this.initialFloorIndex,
    required this.highlightAreaIndex,
  });

  final MapData mapData;
  final PageHooks pageHooks;
  final int? initialFloorIndex, highlightAreaIndex;

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  @override
  Widget build(final BuildContext context) => DefaultTabController(
    length: widget.mapData.floors.length,
    initialIndex: widget.initialFloorIndex ?? 0,
    child: widget.pageHooks.buildScaffold(
      appBarBottomWidget: TabBar(tabs: tabs),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        children: tabChildren,
      ),
    ),
  );

  List<Tab> get tabs {
    final locale = Localizations.localeOf(context);
    return widget.mapData.floors
        .map(
          (floor) => Tab(
            child: AutoSizeText(
              floor.title.get(locale),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> get tabChildren {
    return widget.mapData.floors
        .asMap().entries
        .map((floor) => MapWidget(
          floor.value,
          widget.pageHooks.actionHandler,
          floor.key == widget.initialFloorIndex ? widget.highlightAreaIndex : null,
          key: ValueKey(floor.key),
        ))
        .toList(growable: false);
  }
}
