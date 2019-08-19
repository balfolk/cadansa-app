import 'package:cadansa_app/data/map.dart';
import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

class FestivalMap extends StatelessWidget {
  final Floor _data;

  FestivalMap(this._data);

  @override
  Widget build(final BuildContext context) {
    final String path = _data.url + '?version=${_data.version}';
    return Container(
      child: PhotoView(
        imageProvider: NetworkImage(path),
        initialScale: PhotoViewComputedScale.contained,// _data.initialScale,
        minScale: _data.minScale ?? 0.2,
        maxScale: _data.maxScale ?? 1.0,
        backgroundDecoration: BoxDecoration(color: Colors.white),
      ),
    );
  }
}
