import 'package:cadansa_app/widgets/map.dart';
import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  final dynamic _config;
  final BottomNavigationBar Function() _bottomBarGenerator;

  MapPage(this._config, this._bottomBarGenerator);

  @override
  Widget build(final BuildContext context) {
    final String title = _config['title'];
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: FestivalMap(_config['map']),
        ),
        bottomNavigationBar: _bottomBarGenerator());
  }
}
