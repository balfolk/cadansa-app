import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class IndicatorCard extends StatelessWidget {
  final Color color;
  final double elevation;
  final Widget child;
  final Indicator indicator;

  static const double _defaultElevation = 1.0;
  static const double _defaultBorderRadius = 4.0;

  IndicatorCard({
    final Key key,
    this.color,
    this.elevation,
    @required this.child,
    @required this.indicator
  })
      : assert(elevation == null || elevation >= 0.0),
        super(key: key);

  @override
  Widget build(final BuildContext context) {
    final cardTheme = CardTheme.of(context);

    return CustomPaint(
      painter: _IndicatorRectanglePainter(
        indicator,
        color ?? cardTheme.color ?? Theme.of(context).cardColor,
        elevation ?? cardTheme.elevation ?? _defaultElevation,
        _defaultBorderRadius,
      ),
      child: Padding(
        padding: indicator.padding,
        child: child,
      ),
    );
  }
}

class Indicator {
  final double width, length;
  // TODO convert to AlignmentGeometry
  final Alignment _alignment;

  static const _defaultAlignment = Alignment.bottomCenter;

  const Indicator(this.width, this.length, this._alignment)
      : assert(width == null || width >= 0.0),
        assert(length == null || length >= 0.0);

  Alignment get alignment => _alignment ?? _defaultAlignment;

  bool get hasLeft => alignment.x == -1.0;

  bool get hasRight => alignment.x == 1.0;

  bool get hasTop => alignment.y == -1.0;

  bool get hasBottom => alignment.y == 1.0;

  EdgeInsets get padding => EdgeInsets.fromLTRB(
    hasLeft ? length : 0,
    hasTop ? length : 0,
    hasRight ? length : 0,
    hasBottom ? length : 0,
  );

  @override
  int get hashCode => hashValues(width, length, _alignment);

  @override
  bool operator ==(final other) => other is Indicator
      && width == other.width
      && length == other.length
      && _alignment == other._alignment;
}

class _IndicatorRectanglePainter extends CustomPainter {
  final Indicator _indicator;
  final Color _color;
  final double _elevation;
  final double _borderRadius;

  _IndicatorRectanglePainter(this._indicator, this._color, this._elevation, this._borderRadius);

  @override
  void paint(final Canvas canvas, final Size size) {
    final alignment = _indicator.alignment;

    final innerRect = _indicator.padding.deflateRect(Offset.zero & size);

    final indicatorCenter = alignment.withinRect(innerRect);
    Offset indicatorStart, apex, indicatorEnd;
    if (_indicator.hasLeft || _indicator.hasRight) {
      indicatorStart = Offset(indicatorCenter.dx, indicatorCenter.dy - _indicator.width / 2.0);
      apex = Offset(indicatorCenter.dx + (_indicator.hasLeft ? -1.0 : 1.0) * _indicator.length, indicatorCenter.dy);
      indicatorEnd = Offset(indicatorCenter.dx, indicatorCenter.dy + _indicator.width / 2.0);
    } else {
      indicatorStart = Offset(indicatorCenter.dx - _indicator.width / 2.0, indicatorCenter.dy);
      apex = Offset(indicatorCenter.dx, indicatorCenter.dy + (_indicator.hasTop ? -1.0 : 1.0) * _indicator.length);
      indicatorEnd = Offset(indicatorCenter.dx + _indicator.width / 2.0, indicatorCenter.dy);
    }

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          innerRect,
          Radius.circular(_borderRadius),
      ))
      ..moveTo(indicatorStart.dx, indicatorStart.dy)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(indicatorEnd.dx, indicatorEnd.dy);

    canvas.drawShadow(path, Colors.black, _elevation, true);
    canvas.drawPath(path, Paint()..color = _color);
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) {
    return this != oldDelegate;
  }

  @override
  int get hashCode => hashValues(_indicator, _color, _elevation, _borderRadius);

  @override
  bool operator ==(final other) {
    return other is _IndicatorRectanglePainter
        && _indicator == other._indicator
        && _color == other._color
        && _elevation == other._elevation
        && _borderRadius == other._borderRadius;
  }
}
