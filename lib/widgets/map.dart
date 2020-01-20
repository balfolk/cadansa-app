import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

class MapWidget extends StatelessWidget {
  final Floor _data;

  static final LText _MAP_LOAD_FAIL_TEXT = LText(const {
    'en': "Could not load the festival map. Please make sure you're connected to the Internet.",
    'nl': 'Het is niet gelukt om de plattegrond te downloaden. Controleer of je internetverbinding aanstaat.',
    'fr': 'Échec du téléchargement du plan. Assurez-vous que votre connexion Internet fonctionne.'
  });

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
        filterQuality: FilterQuality.medium,
        loadFailedChild: _buildLoadFailedChild(),
      ),
    );
  }
  
  Widget _buildLoadFailedChild() => Builder(builder: (context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        _MAP_LOAD_FAIL_TEXT.get(Localizations.localeOf(context)),
        textAlign: TextAlign.center,
      ),
    );
  });
  
}
