import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

class FestivalMap extends StatelessWidget {
  final dynamic _mapConfig;

  FestivalMap(this._mapConfig);

  @override
  Widget build(final BuildContext context) {
    final String path =
        _mapConfig['path'] + '?version=${_mapConfig['version']}';
    return Container(
      child: PhotoView(
        imageProvider: NetworkImage(path),
        minScale: 0.20,
        maxScale: 1.0,
        backgroundDecoration: BoxDecoration(color: Colors.white),
      ),
    );
  }
}
