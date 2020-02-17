import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/widgets/indicator_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:photo_view/photo_view.dart';

class MapWidget extends StatefulWidget {
  final Floor _data;
  final ActionHandler _actionHandler;
  final int _highlightAreaIndex;

  static final LText _MAP_LOAD_FAIL_TEXT = LText(const {
    'en': "Could not load the festival map. Please make sure you're connected to the Internet.",
    'nl': 'Het is niet gelukt om de plattegrond te downloaden. Controleer of je internetverbinding aanstaat.',
    'fr': 'Échec du téléchargement du plan. Assurez-vous que votre connexion Internet fonctionne.'
  });

  static const _INDICATOR_WIDTH = 20.0, _INDICATOR_LENGTH = 10.0;
  static const _POPUP_HEIGHT = 70.0, _POPUP_WIDTH = 215.0;
  static const _POPUP_PADDING = EdgeInsets.all(5.0);
  static const _MAX_INDICATOR_ALIGNMENT = 0.85;
  static const _MAP_MOVE_ANIMATION_DURATION = Duration(milliseconds: 500);

  MapWidget(this._data, this._actionHandler, this._highlightAreaIndex);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with SingleTickerProviderStateMixin {
  PhotoViewController _controller;
  StreamSubscription _controllerOutputStreamSubscription;
  FloorArea _activeArea;
  Offset _indicatorPosition;
  Alignment _indicatorAlignment;
  Size _lastKnownSize;

  AnimationController _mapMoveAnimationController;
  Animation<Offset> _mapMoveAnimation;
  FloorArea _mapMoveTargetArea;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _controllerOutputStreamSubscription = _controller.outputStateStream.listen(_onMapControllerEvent);

    _mapMoveAnimationController = AnimationController(duration: MapWidget._MAP_MOVE_ANIMATION_DURATION, vsync: this);
    _mapMoveAnimationController.addListener(() {
      _controller.position = _mapMoveAnimation.value;
      if (_mapMoveAnimationController.isCompleted) {
        setState(() {
          _activeArea = _mapMoveTargetArea;
        });
      }
    });

    if (widget._highlightAreaIndex != null) {
      _activeArea = widget._data.areas[widget._highlightAreaIndex];
    }
  }

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final String path = widget._data.url.get(locale) + '?version=${widget._data.version}';
    final stackChildren = <Widget>[
      PhotoView(
        controller: _controller,
        imageProvider: path.startsWith('http') ? CachedNetworkImageProvider(path) : AssetImage(path.split('?')[0]),
        initialScale: widget._data.initialScale ?? PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        maxScale: widget._data.maxScale ?? 1.0,
        backgroundDecoration: BoxDecoration(color: Colors.white),
        filterQuality: FilterQuality.medium,
        loadFailedChild: _buildLoadFailedChild(),
        onTapUp: _onTapUp,
      ),
    ];

    final scale = _controller.value?.scale;
    if (scale != null) {
      widget._data.areas.forEach((area) {
        final size = scale * area.buttonSize;
        final location = _areaCoordinatesToMap(area.center).translate(-2 * size, -size / 2);

        final areaWidgets = <Widget>[
          SizedBox.fromSize(
            size: Size.square(size),
            child: FloatingActionButton(
              onPressed: () => _selectArea(area),
              backgroundColor: theme.primaryColor,
              elevation: 10.0,
              child: Icon(
                MdiIcons.fromString(area.buttonIcon),
                size: size / 2,
              ),
            ),
          )];

        final text = area.title.get(locale);
        if (text.isNotEmpty) {
          areaWidgets.add(Text(
            area.title.get(locale),
            textAlign: TextAlign.center,
            style: theme.textTheme.body1.copyWith(
              fontFamily: 'CaDansa',
              fontSize: scale * area.titleFontSize,
            ),
          ));
        }

        stackChildren.add(Positioned(
          left: location.dx,
          top: location.dy,
          width: 4 * size,
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: areaWidgets,
            ),
          ),
        ));
      });
    }

    if (_activeArea != null && _indicatorPosition != null && _indicatorAlignment != null) {
      final title = _activeArea.actionTitle.get(locale);
      if (title.isNotEmpty) {
        final hasAction = _activeArea.action?.isNotEmpty ?? false;
        stackChildren.add(Positioned.fromRect(
          rect: Rect.fromCenter(
            center: _indicatorPosition.translate(0, -_indicatorAlignment.y * (MapWidget._POPUP_HEIGHT / 2.0 + MapWidget._INDICATOR_LENGTH)),
            width: MapWidget._POPUP_WIDTH,
            height: MapWidget._POPUP_HEIGHT,
          ),
          child: IndicatorCard(
            indicator: Indicator(
                MapWidget._INDICATOR_WIDTH, MapWidget._INDICATOR_LENGTH, _indicatorAlignment),
            child: FlatButton(
              onPressed: hasAction ? _onAreaPopupPressed : null,
              child: Text(
                _activeArea.actionTitle.get(locale),
                style: theme.textTheme.display1.copyWith(
                    color: hasAction ? theme.primaryColor : null, fontFamily: 'CaDansa'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ));
      }
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
    _lastKnownSize = context.findRenderObject().paintBounds.size;

    if (_activeArea != null && !_calculateAreaCenter(_activeArea)) {
      _deselectArea();
    }
    setState(() {});
  }

  void _onTapUp(final BuildContext context, final TapUpDetails tapUpDetails, final PhotoViewControllerValue controllerValue) {
    _lastKnownSize = context.findRenderObject().paintBounds.size;

    if (_mapMoveAnimationController.isAnimating) {
      return;
    }

    final area = _determinePressedArea(tapUpDetails.localPosition, controllerValue);
    _selectArea(area);
  }

  void _selectArea(final FloorArea area) {
    if (area != null && area != _activeArea) {
      final isInView = _calculateAreaCenter(area);
      if (isInView) {
        setState(() {
          _activeArea = area;
        });
      } else {
        _animateAreaMapMove(area);
        setState(() {
          _activeArea = null;
        });
      }
    } else {
      setState(() {
        _deselectArea();
      });
    }
  }

  void _animateAreaMapMove(final FloorArea targetArea) {
    final moveTo = -targetArea.center * _controller.scale;
    _mapMoveAnimation = Tween(begin: _controller.position, end: moveTo).animate(_mapMoveAnimationController);
    _mapMoveAnimationController.forward(from: _mapMoveAnimationController.lowerBound);
    _mapMoveTargetArea = targetArea;
  }

  FloorArea _determinePressedArea(final Offset tapPosition, final PhotoViewControllerValue controllerValue) {
    final position = _mapCoordinatesToArea(tapPosition, controllerValue);

    return widget._data.areas.firstWhere(
      (area) => area.contains(position, controllerValue.scale),
      orElse: () => null,
    );
  }

  bool _calculateAreaCenter(final FloorArea area) {
    final areaCenter = _areaCoordinatesToMap(area.center);
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
  
  Offset _areaCoordinatesToMap(final Offset c) {
    final controllerValue = _controller.value ?? _controller.initial;
    return ((c * controllerValue.scale).translate(_lastKnownSize.width / 2.0, _lastKnownSize.height / 2.0) + controllerValue.position);
  }

  Offset _mapCoordinatesToArea(final Offset c, [final PhotoViewControllerValue value]) {
    final controllerValue = value ?? _controller.value ?? _controller.initial;
    final controllerPosition = -controllerValue.position / controllerValue.scale;
    final localPosition = c.translate(-_lastKnownSize.width / 2.0, -_lastKnownSize.height / 2.0) / controllerValue.scale;
    return controllerPosition + localPosition;
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
    _mapMoveAnimationController?.dispose();
    super.dispose();
  }
}
