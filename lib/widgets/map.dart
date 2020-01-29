import 'dart:async';

import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/widgets/indicator_card.dart';
import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

class MapWidget extends StatefulWidget {
  final Floor _data;
  final ActionHandler _actionHandler;

  static final LText _MAP_LOAD_FAIL_TEXT = LText(const {
    'en': "Could not load the festival map. Please make sure you're connected to the Internet.",
    'nl': 'Het is niet gelukt om de plattegrond te downloaden. Controleer of je internetverbinding aanstaat.',
    'fr': 'Échec du téléchargement du plan. Assurez-vous que votre connexion Internet fonctionne.'
  });

  static const _INDICATOR_WIDTH = 20.0, _INDICATOR_LENGTH = 10.0;
  static const _POPUP_HEIGHT = 100.0, _POPUP_WIDTH = 215.0;
  static const _POPUP_PADDING = EdgeInsets.all(5.0);
  static const _MAX_INDICATOR_ALIGNMENT = 0.85;

  MapWidget(this._data, this._actionHandler);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  PhotoViewController _controller;
  StreamSubscription _controllerOutputStreamSubscription;
  FloorArea _activeArea;
  Offset _indicatorPosition;
  Alignment _indicatorAlignment;
  Size _lastKnownSize;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _controllerOutputStreamSubscription = _controller.outputStateStream.listen(_onMapControllerEvent);
  }

  @override
  Widget build(final BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String path = widget._data.url.get(locale) + '?version=${widget._data.version}';
    final stackChildren = <Widget>[
      PhotoView(
        controller: _controller,
        imageProvider: path.startsWith('http') ? NetworkImage(path) : AssetImage(path.split('?')[0]),
    initialScale: widget._data.initialScale ?? PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        maxScale: widget._data.maxScale ?? 1.0,
        backgroundDecoration: BoxDecoration(color: Colors.white),
        filterQuality: FilterQuality.medium,
        loadFailedChild: _buildLoadFailedChild(),
        onTapUp: _onTapUp,
      )
    ];

    if (_activeArea != null) {
      stackChildren.add(Positioned.fromRect(
        rect: Rect.fromCenter(
          center: _indicatorPosition.translate(0, -_indicatorAlignment.y * (MapWidget._POPUP_HEIGHT / 2.0 + MapWidget._INDICATOR_LENGTH)),
          width: MapWidget._POPUP_WIDTH,
          height: MapWidget._POPUP_HEIGHT,
        ),
        child: IndicatorCard(
          indicator: Indicator(MapWidget._INDICATOR_WIDTH, MapWidget._INDICATOR_LENGTH, _indicatorAlignment),
          child: FlatButton(
            onPressed: _onAreaPopupPressed,
            child: Text(
              _activeArea.title.get(locale),
              style: Theme.of(context).textTheme.display1,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ));
    }

    return Container(
      child: Stack(
        children: stackChildren,
      ),
    );
  }

  Widget _buildLoadFailedChild() => Builder(builder: (context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        MapWidget._MAP_LOAD_FAIL_TEXT.get(Localizations.localeOf(context)),
        textAlign: TextAlign.center,
      ),
    );
  });

  void _onMapControllerEvent(final PhotoViewControllerValue value) {
    if (_activeArea != null) {
      if (_calculateAreaCenter()) {
        setState(() {});
      } else {
        setState(() {
          _deselectArea();
        });
      }
    }
  }

  void _onTapUp(final BuildContext context, final TapUpDetails tapUpDetails, final PhotoViewControllerValue controllerValue) {
    _lastKnownSize = context.findRenderObject().paintBounds.size;

    final area = _determinePressedArea(tapUpDetails.localPosition, controllerValue);
    if (area != null && area != _activeArea) {
      _activeArea = area;
      final isInView = _calculateAreaCenter();
      if (!isInView) {
        final moveTo = -_activeArea.center * _controller.scale;
        _controller.position = moveTo;
      }
      setState(() {});
    } else {
      setState(() {
        _deselectArea();
      });
    }
  }

  FloorArea _determinePressedArea(final Offset tapPosition, final PhotoViewControllerValue controllerValue) {
    final controllerPosition = -controllerValue.position / controllerValue.scale;
    final localPosition = tapPosition.translate(-_lastKnownSize.width / 2.0, -_lastKnownSize.height / 2.0) / controllerValue.scale;
    final position = controllerPosition + localPosition;

    return widget._data.areas.firstWhere(
      (area) => area.path.contains(position),
      orElse: () => null,
    );
  }

  bool _calculateAreaCenter() {
    final areaCenter = ((_activeArea.center * _controller.scale)
        .translate(_lastKnownSize.width / 2.0, _lastKnownSize.height / 2.0) + _controller.position);
    final verticalTranslation = (areaCenter.dy - MapWidget._INDICATOR_LENGTH - MapWidget._POPUP_PADDING.top) - MapWidget._POPUP_HEIGHT;
    if (verticalTranslation < -(MapWidget._POPUP_HEIGHT + MapWidget._INDICATOR_LENGTH) || verticalTranslation > (_lastKnownSize.height - MapWidget._POPUP_HEIGHT - MapWidget._INDICATOR_LENGTH)) {
      return false;
    }

    final doHorizontalFlip = verticalTranslation < 0.0;

    final leftTranslation = (MapWidget._POPUP_WIDTH / 2.0 - (areaCenter.dx - MapWidget._POPUP_PADDING.left)) / (MapWidget._POPUP_WIDTH / 2.0);
    final rightTranslation = (MapWidget._POPUP_WIDTH / 2.0 - (_lastKnownSize.width - areaCenter.dx - MapWidget._POPUP_PADDING.right)) / (MapWidget._POPUP_WIDTH / 2.0);
    if (leftTranslation > MapWidget._MAX_INDICATOR_ALIGNMENT || rightTranslation > MapWidget._MAX_INDICATOR_ALIGNMENT) {
      return false;
    }

    final horizontalTranslation = leftTranslation > 0 ? -leftTranslation : (rightTranslation > 0 ? rightTranslation : 0.0);

    _indicatorAlignment = Alignment(horizontalTranslation, doHorizontalFlip ? -1.0 : 1.0);
    _indicatorPosition = areaCenter.translate(-_indicatorAlignment.x * MapWidget._POPUP_WIDTH / 2.0, 0.0);
    return true;
  }

  void _onAreaPopupPressed() => widget._actionHandler(_activeArea.action);

  void _deselectArea() {
    _activeArea = null;
    _indicatorPosition = null;
    _indicatorAlignment = null;
  }

  @override
  void dispose() {
    _controllerOutputStreamSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
