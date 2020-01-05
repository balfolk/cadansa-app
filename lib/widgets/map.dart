import 'package:cadansa_app/data/map.dart';
import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

class MapWidget extends StatelessWidget {
  final Floor _data;

  MapWidget(this._data);

  @override
  Widget build(final BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String path = _data.url.get(locale) + '?version=${_data.version}';
    return Container(
      child: PhotoView(
        imageProvider: NetworkImage(path),
        initialScale: _data.initialScale ?? PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        maxScale: _data.maxScale ?? 1.0,
        backgroundDecoration: BoxDecoration(color: Colors.white),
      ),
    );
  }
}
