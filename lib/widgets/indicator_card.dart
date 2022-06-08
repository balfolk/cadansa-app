import 'package:flutter/material.dart';

class IndicatorCard extends StatelessWidget {
  const IndicatorCard({
    final Key? key,
    this.color,
    this.elevation,
    required this.child,
    required this.indicator,
  })  : assert(elevation == null || elevation >= 0.0),
        super(key: key);

  final Color? color;
  final double? elevation;
  final Widget child;
  final Indicator indicator;

  static const double _defaultElevation = 1.0;
  static const double _defaultBorderRadius = 4.0;

  @override
  Widget build(final BuildContext context) {
    final cardTheme = CardTheme.of(context);

    return CustomPaint(
      painter: _IndicatorRectanglePainter(
        indicator,
        color ?? cardTheme.color ?? Theme.of(context).cardColor,
        elevation ?? cardTheme.elevation ?? _defaultElevation,
        _defaultBorderRadius,
        Directionality.of(context),
      ),
      child: Padding(
        padding: indicator.padding,
        child: child,
      ),
    );
  }
}

@immutable
class Indicator {
  const Indicator({
    required this.width,
    required this.length,
    this.alignment = _defaultAlignment,
  })  : assert(width >= 0.0),
        assert(length >= 0.0);

  final double width, length;
  final AlignmentDirectional alignment;

  static const _defaultAlignment = AlignmentDirectional.bottomCenter;

  bool get hasStart => alignment.start == -1.0;

  bool get hasEnd => alignment.start == 1.0;

  bool get hasTop => alignment.y == -1.0;

  bool get hasBottom => alignment.y == 1.0;

  EdgeInsetsDirectional get padding => EdgeInsetsDirectional.fromSTEB(
    hasStart ? length : 0,
    hasTop ? length : 0,
    hasEnd ? length : 0,
    hasBottom ? length : 0,
  );

  @override
  int get hashCode => hashValues(width, length, alignment);

  @override
  bool operator ==(final Object other) => other is Indicator
      && width == other.width
      && length == other.length
      && alignment == other.alignment;
}

@immutable
class _IndicatorRectanglePainter extends CustomPainter {
  const _IndicatorRectanglePainter(this._indicator, this._color,
      this._elevation, this._borderRadius, this._textDirection);

  final Indicator _indicator;
  final Color _color;
  final double _elevation;
  final double _borderRadius;
  final TextDirection _textDirection;

  @override
  void paint(final Canvas canvas, final Size size) {
    final alignment = _indicator.alignment.resolve(_textDirection);

    final innerRect = _indicator.padding.resolve(_textDirection).deflateRect(Offset.zero & size);

    final indicatorCenter = alignment.withinRect(innerRect);
    Offset indicatorStart, apex, indicatorEnd;
    if (_indicator.hasStart || _indicator.hasEnd) {
      indicatorStart = Offset(indicatorCenter.dx, indicatorCenter.dy - _indicator.width / 2.0);
      apex = Offset(indicatorCenter.dx + (_indicator.hasStart ? -1.0 : 1.0) * _indicator.length, indicatorCenter.dy);
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
  bool operator ==(final Object other) {
    return other is _IndicatorRectanglePainter
        && _indicator == other._indicator
        && _color == other._color
        && _elevation == other._elevation
        && _borderRadius == other._borderRadius;
  }
}
