import 'dart:async';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/map.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/widgets/indicator_card.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:photo_view/photo_view.dart';

class MapWidget extends StatefulWidget {
  const MapWidget(
      this._data,
      this._actionHandler,
      this._highlightAreaIndex, {
        super.key,
      });

  final Floor _data;
  final ActionHandler _actionHandler;
  final int? _highlightAreaIndex;

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

  @override
  MapWidgetState createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> with SingleTickerProviderStateMixin {
  final PhotoViewController _controller = PhotoViewController();
  late final StreamSubscription<Object?>? _controllerOutputStreamSubscription;
  FloorArea? _activeArea;
  FloorArea? _highlightedArea;
  Offset? _indicatorPosition;
  AlignmentDirectional? _indicatorAlignment;
  Size? _lastKnownSize;

  AnimationController? _mapMoveAnimationController;

  Animation<Offset>? _mapMoveAnimation;
  FloorArea? _mapMoveTargetArea;

  @override
  void initState() {
    super.initState();
    _controllerOutputStreamSubscription =
        _controller.outputStateStream.listen(_onMapControllerEvent);
    _mapMoveAnimationController = AnimationController(
      duration: MapWidget._MAP_MOVE_ANIMATION_DURATION,
      vsync: this,
    )..addListener(() {
      final mapMoveAnimationController = _mapMoveAnimationController;
      final mapMoveTargetArea = _mapMoveTargetArea;
        final mapMoveAnimation = _mapMoveAnimation;
        if (mapMoveAnimationController == null ||
            mapMoveTargetArea == null ||
            mapMoveAnimation == null) {
          return;
        }

        _controller.position = mapMoveAnimation.value;
      if (mapMoveAnimationController.isCompleted &&
          _calculateIndicatorCoordinates(mapMoveTargetArea)) {
        setState(() {
          _activeArea = _mapMoveTargetArea;
          _mapMoveTargetArea = null;
          _mapMoveAnimation = null;
        });
      }
    });

    _setHighlightedArea();
  }

  @override
  void didUpdateWidget(final MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._highlightAreaIndex != oldWidget._highlightAreaIndex) {
      _setHighlightedArea();
    }
  }

  void _setHighlightedArea() {
    final highlightAreaIndex = widget._highlightAreaIndex;
    if (highlightAreaIndex != null) {
      final areaToHighlight = widget._data.areas[highlightAreaIndex];
      _highlightedArea = areaToHighlight;
      _activeArea = areaToHighlight;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final path = widget._data.url.get(locale);
    ImageProvider imageProvider;
    if (path.startsWith('http')) {
      final versionEncoded = Uri.encodeQueryComponent('${widget._data.version}');
      final url = Uri.parse(widget._data.url.get(locale)).replace(
        queryParameters: <String, String>{'version': versionEncoded},
      );
      imageProvider = CachedNetworkImageProvider(url.toString());
    } else {
      imageProvider = AssetImage(path);
    }

    final stackChildren = <Widget>[
      PhotoView(
        controller: _controller,
        imageProvider: imageProvider,
        initialScale: widget._data.initialScale ?? PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        maxScale: widget._data.maxScale ?? 1.0,
        backgroundDecoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        filterQuality: FilterQuality.medium,
        errorBuilder: _buildLoadFailedChild,
        onTapUp: _onTapUp,
      ),
    ];

    final scale = _controller.value.scale;
    if (scale != null) {
      if (_lastKnownSize != null) {
        final highlightedArea = _highlightedArea;
        if (kDebugMode) {
          stackChildren.add(CustomPaint(
            painter: _AreaPainter(
              widget._data.areas,
              _areaCoordinatesToMap,
              theme,
            ),
          ));
        } else if (highlightedArea != null) {
          stackChildren.add(CustomPaint(
            painter: _AreaPainter(
              [highlightedArea],
              _areaCoordinatesToMap,
              theme
            ),
          ));
        }
      }

      for (final area in widget._data.areas) {
        final size = scale * area.buttonSize;
        final location = _areaCoordinatesToMap(area.center)
            ?.translate(-2 * size, -size / 2);

        final areaWidgets = <Widget>[
          SizedBox.fromSize(
            size: Size.square(size),
            child: FloatingActionButton(
              onPressed: () => _selectArea(area),
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 10.0,
              heroTag: null,
              child: Icon(
                MdiIcons.fromString(area.buttonIcon),
                size: size / 2,
              ),
            ),
          )];

        final text = area.title.get(locale);
        if (text.isNotEmpty) {
          final titleFontSize = area.titleFontSize ?? theme.textTheme.displayLarge?.fontSize;
          areaWidgets.add(Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: MAP_FONT_FAMILY,
              fontSize: titleFontSize != null ? scale * titleFontSize : null,
            ),
          ));
        }

        if (location != null) {
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
        }
      }

      for (final text in widget._data.text) {
        final location = _areaCoordinatesToMap(text.location);
        if (location != null) {
          stackChildren.add(Positioned(
            left: location.dx,
            top: location.dy,
            child: Transform.rotate(
              angle: (2.0 * math.pi) * text.angle / 360.0,
              child: Text(
                text.text.get(locale),
                textAlign: text.textAlign,
                textScaler: TextScaler.linear(scale),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FONT_FEATURE_SMALL_CAPS],
                  fontSize: text.fontSize ?? theme.textTheme.displayMedium?.fontSize,
                ),
              ),
            ),
          ));
        }
      }
    }

    final activeArea = _activeArea;
    final indicatorPosition = _indicatorPosition;
    final indicatorAlignment = _indicatorAlignment;
    if (activeArea != null && indicatorPosition != null && indicatorAlignment != null) {
      final title = activeArea.actionTitle.get(locale);
      final alignment = indicatorAlignment.resolve(Directionality.of(context));
      if (title.isNotEmpty) {
        final action = activeArea.action.get(locale);
        final hasAction = action.isNotEmpty;
        stackChildren.add(Positioned.fromRect(
          rect: Rect.fromCenter(
            center: indicatorPosition.translate(0, -alignment.y * (MapWidget._POPUP_HEIGHT / 2.0 + MapWidget._INDICATOR_LENGTH)),
            width: MapWidget._POPUP_WIDTH,
            height: MapWidget._POPUP_HEIGHT,
          ),
          child: IndicatorCard(
            indicator: Indicator(
              width: MapWidget._INDICATOR_WIDTH,
              length: MapWidget._INDICATOR_LENGTH,
              alignment: indicatorAlignment,
            ),
            child: TextButton(
              onPressed: hasAction ? () => _onAreaPopupPressed(action) : null,
              child: AutoSizeText(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: hasAction ? theme.primaryColor : null,
                  fontFamily: MAP_FONT_FAMILY,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ));
      }
    }

    return Stack(
      children: stackChildren,
    );
  }

  Widget _buildLoadFailedChild(final BuildContext context, final Object error,
          final StackTrace? stackTrace) =>
      Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Text(
          MapWidget._MAP_LOAD_FAIL_TEXT.get(Localizations.localeOf(context)),
          textAlign: TextAlign.center,
        ),
      );

  void _onMapControllerEvent(final PhotoViewControllerValue value) {
    _lastKnownSize = context.findRenderObject()?.paintBounds.size;

    final activeArea = _activeArea;
    if (activeArea != null && !_calculateIndicatorCoordinates(activeArea)) {
      _deselectArea();
    }
    setState(() {});
  }

  void _onTapUp(final BuildContext context, final TapUpDetails tapUpDetails, final PhotoViewControllerValue controllerValue) {
    _lastKnownSize = context.findRenderObject()?.paintBounds.size;

    if (_mapMoveAnimationController?.isAnimating ?? false) {
      return;
    }

    final area = _determinePressedArea(tapUpDetails.localPosition, controllerValue);
    _selectArea(area);
  }

  void _selectArea(final FloorArea? area) {
    if (area != null && area != _activeArea) {
      final isInView = _calculateIndicatorCoordinates(area);
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
      setState(_deselectArea);
    }
  }

  void _animateAreaMapMove(final FloorArea targetArea) {
    final scale = _controller.scale;
    final mapMoveAnimationController = _mapMoveAnimationController;
    if (scale == null || mapMoveAnimationController == null) return;

    final moveTo = -targetArea.center * scale;
    _mapMoveAnimation = Tween(begin: _controller.position, end: moveTo)
        .animate(mapMoveAnimationController);
    mapMoveAnimationController.forward(
        from: mapMoveAnimationController.lowerBound);
    _mapMoveTargetArea = targetArea;
  }

  FloorArea? _determinePressedArea(final Offset tapPosition, final PhotoViewControllerValue controllerValue) {
    final position = _mapCoordinatesToArea(tapPosition, controllerValue);
    if (position == null) return null;

    return widget._data.areas.firstWhereOrNull(
      (area) => area.contains(position),
    );
  }

  /// Calculate the indicator coordinates for a [FloorArea] and stores them in
  /// [_indicatorAlignment] and [_indicatorPosition]. Returns `true` iff the
  /// given area is currently in view.
  bool _calculateIndicatorCoordinates(final FloorArea area) {
    final lastKnownSize = _lastKnownSize;
    if (lastKnownSize == null) return false;

    // TODO calculate the required scale and zoom to that scale if necessary
    final areaCenter = _areaCoordinatesToMap(area.center);
    if (areaCenter == null) {
      return false;
    }

    final verticalTranslation = (areaCenter.dy - MapWidget._INDICATOR_LENGTH - MapWidget._POPUP_PADDING.top) - MapWidget._POPUP_HEIGHT;
    if (verticalTranslation < -(MapWidget._POPUP_HEIGHT + MapWidget._INDICATOR_LENGTH) || verticalTranslation > (lastKnownSize.height - MapWidget._POPUP_HEIGHT - MapWidget._INDICATOR_LENGTH)) {
      return false;
    }

    final doHorizontalFlip = verticalTranslation < 0.0;

    final leftTranslation = (MapWidget._POPUP_WIDTH / 2.0 - (areaCenter.dx - MapWidget._POPUP_PADDING.left)) / (MapWidget._POPUP_WIDTH / 2.0);
    final rightTranslation = (MapWidget._POPUP_WIDTH / 2.0 - (lastKnownSize.width - areaCenter.dx - MapWidget._POPUP_PADDING.right)) / (MapWidget._POPUP_WIDTH / 2.0);
    if (leftTranslation > MapWidget._MAX_INDICATOR_ALIGNMENT || rightTranslation > MapWidget._MAX_INDICATOR_ALIGNMENT) {
      return false;
    }

    final horizontalTranslation = leftTranslation > 0 ? -leftTranslation : (rightTranslation > 0 ? rightTranslation : 0.0);

    _indicatorAlignment = AlignmentDirectional(horizontalTranslation, doHorizontalFlip ? -1.0 : 1.0);
    _indicatorPosition = areaCenter.translate(-horizontalTranslation * MapWidget._POPUP_WIDTH / 2.0, 0.0);
    return true;
  }
  
  Offset? _areaCoordinatesToMap(final Offset c) {
    final controllerValue = _controller.value;
    final scale = controllerValue.scale;
    final lastKnownSize = _lastKnownSize;
    if (scale == null || lastKnownSize == null) {
      return null;
    }

    return (c * scale)
        .translate(lastKnownSize.width / 2.0, lastKnownSize.height / 2.0)
        + controllerValue.position;
  }

  Offset? _mapCoordinatesToArea(final Offset c, [final PhotoViewControllerValue? value]) {
    final controllerValue = value ?? _controller.value;
    final scale = controllerValue.scale;
    final lastKnownSize = _lastKnownSize;
    if (scale == null || lastKnownSize == null) {
      return null;
    }

    final controllerPosition = -controllerValue.position / scale;
    final localPosition = c.translate(-lastKnownSize.width / 2.0, -lastKnownSize.height / 2.0) / scale;
    return controllerPosition + localPosition;
  }

  void _onAreaPopupPressed(final String action) => widget._actionHandler(action);

  void _deselectArea() {
    _activeArea = null;
    _indicatorPosition = null;
    _indicatorAlignment = null;
  }

  @override
  void dispose() {
    _controllerOutputStreamSubscription?.cancel();
    _controller.dispose();
    _mapMoveAnimationController?.dispose();
    super.dispose();
  }
}

@immutable
class _AreaPainter extends CustomPainter {
  _AreaPainter(final Iterable<FloorArea> areas, this._transformation, final ThemeData theme)
      : _areas = List.of(areas),
        _strokePaint = Paint()
          ..color = theme.primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
        _fillPaint = Paint()
          ..color = theme.primaryColorLight.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill
          ..strokeWidth = 0.0;

  final List<FloorArea> _areas;
  final Offset? Function(Offset) _transformation;
  final Paint _strokePaint, _fillPaint;

  @override
  void paint(final Canvas canvas, final Size size) {
    for (final area in _areas) {
      final path = area.getTransformedPath(_transformation);
      if (path != null) {
        canvas.drawPath(path, _fillPaint);
        canvas.drawPath(path, _strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) {
    return !(oldDelegate is _AreaPainter && oldDelegate._areas == _areas);
  }

}
