import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class MapData {
  const MapData._(this._floors);

  MapData.parse(final dynamic json)
      : this._(parseList(json['floors'], (dynamic floor) => Floor.parse(floor)));

  final BuiltList<Floor> _floors;

  BuiltList<Floor> get floors => _floors;
}

@immutable
class Floor {
  const Floor._(
      this._title,
      this._url,
      this._version,
      this._initialScale,
      this._minScale,
      this._maxScale,
      this._areas,
      this._text,
      );

  Floor.parse(final dynamic json) : this._(
      LText(json['title']),
      LText(json['path']),
      parseNum(json['version']),
      parseNum(json['initialScale'])?.toDouble(),
      parseNum(json['minScale'])?.toDouble(),
      parseNum(json['maxScale'])?.toDouble(),
      parseList(json['areas'], (dynamic area) => FloorArea.parse(area)),
      parseList(json['text'], (dynamic area) => FloorText.parse(area)));

  final LText _title;
  final LText _url;
  final num? _version;
  final double? _initialScale, _minScale, _maxScale;
  final BuiltList<FloorArea> _areas;
  final BuiltList<FloorText> _text;

  LText get title => _title;

  LText get url => _url;

  num? get version => _version;

  double? get initialScale => _initialScale;

  double? get minScale => _minScale;

  double? get maxScale => _maxScale;

  BuiltList<FloorArea> get areas => _areas;

  BuiltList<FloorText> get text => _text;
}

@immutable
class FloorArea {
  const FloorArea._(
      this._id,
      this._points,
      this._title,
      this._titleFontSize,
      this._buttonIcon,
      this._buttonSize,
      this._actionTitle,
      this._action,
      this._center,
      );

  FloorArea.parse(final dynamic json) : this._(
    json['id'] as String?,
    parseList(json['path'], parseOffset),
    LText(json['title']),
    parseNum(json['titleFontSize'])?.toDouble(),
    json['buttonIcon'] as String?,
    parseNum(json['buttonSize'])!.toDouble(),
    LText(json['actionTitle']),
    LText(json['action']),
    parseOffset(json['center']),
  );

  final String? _id;
  final BuiltList<Offset> _points;
  final LText _title;
  final double? _titleFontSize;
  final String? _buttonIcon;
  final double _buttonSize;
  final LText _actionTitle;
  final LText _action;
  final Offset _center;

  String? get id => _id;

  Path get path => Path()..addPolygon(_points.toList(), true);

  Path? getTransformedPath(final Offset? Function(Offset) transformation) {
    final points = List<Offset>.unmodifiable(_points.map(transformation).nonNulls);
    if (points.isEmpty) return null;
    return Path()..addPolygon(points, true);
  }

  bool contains(final Offset position) {
    if (_points.isNotEmpty) {
      return path.contains(position);
    }

    return (position - center).distanceSquared < _buttonRadiusSquared;
  }

  LText get title => _title;

  double? get titleFontSize => _titleFontSize;

  String get buttonIcon => _buttonIcon ?? '';

  double get buttonSize => _buttonSize;

  double get _buttonRadiusSquared => 0.5 * buttonSize * 0.5 * buttonSize;

  LText get actionTitle => _actionTitle;

  LText get action => _action;

  Offset get center => _center;
}

@immutable
class FloorText {
  const FloorText._(
      this._location,
      this._angle,
      this._align,
      this._fontSize,
      this._text,
      );

  FloorText.parse(final dynamic json) : this._(
    parseOffset(json['location']),
    parseNum(json['angle'])?.toDouble() ?? 0.0,
    parseNum(json['alignment'])?.toInt() ?? TextAlign.center.index,
    parseNum(json['fontSize'])?.toDouble(),
    LText(json['text']),
  );

  final Offset _location;
  final double _angle;
  final int _align;
  final double? _fontSize;
  final LText _text;

  Offset get location => _location;

  double get angle => _angle;

  TextAlign get textAlign => TextAlign.values.skip(_align).firstOrNull ?? TextAlign.center;

  double? get fontSize => _fontSize;

  LText get text => _text;
}
