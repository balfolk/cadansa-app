import 'dart:ui';

import 'package:cadansa_app/data/parse_utils.dart';

class MapData {
  final List<Floor> _floors;

  MapData._(this._floors);

  MapData.parse(final dynamic json)
    : this._((json['floors'] ?? [])
        .map((d) => Floor.parse(d))
        .cast<Floor>().toList(growable: false));

  List<Floor> get floors => List.unmodifiable(_floors);
}

class Floor {
  final LText _title;
  final LText _url;
  final int _version;
  final double _initialScale, _minScale, _maxScale;
  final List<FloorArea> _areas;
  final List<FloorText> _text;

  Floor._(this._title, this._url, this._version, this._initialScale, this._minScale, this._maxScale, this._areas, this._text);

  Floor.parse(final dynamic json) : this._(
      LText(json['title']),
      LText(json['path']),
      json['version'] as int,
      json['initialScale'] as double,
      json['minScale'] as double,
      json['maxScale'] as double,
      List.unmodifiable((json['areas'] ?? []).map((area) => FloorArea.parse(area))),
      List.unmodifiable((json['text'] ?? []).map((area) => FloorText.parse(area))));

  LText get title => _title;

  LText get url => _url;

  int get version => _version;

  double get initialScale => _initialScale;

  double get minScale => _minScale;

  double get maxScale => _maxScale;

  List<FloorArea> get areas => _areas;

  List<FloorText> get text => _text;
}

class FloorArea {
  final String _id;
  final List<Offset> _points;
  final LText _title;
  final double _titleFontSize;
  final String _buttonIcon;
  final double _buttonSize;
  final LText _actionTitle;
  final LText _action;
  final Offset _center;

  FloorArea._(this._id, this._points, this._title, this._titleFontSize, this._buttonIcon, this._buttonSize, this._actionTitle, this._action, this._center)
      : assert(_buttonSize != null),
        assert(_buttonIcon != null);

  FloorArea.parse(final dynamic json) : this._(
    json['id'],
    List.unmodifiable(json['path']?.map((point) => Offset(point[0].toDouble(), point[1].toDouble()))?.cast<Offset>() ?? []),
    LText(json['title']),
    json['titleFontSize'],
    json['buttonIcon'],
    json['buttonSize'],
    LText.nullable(json['actionTitle']),
    LText.nullable(json['action']),
    Offset(json['center'][0].toDouble(), json['center'][1].toDouble()),
  );

  String get id => _id;

  Path get path => Path()..addPolygon(_points, true);

  Path getTransformedPath(final Offset Function(Offset) transformation) {
    return Path()..addPolygon(List.unmodifiable(_points.map(transformation)), true);
  }

  bool contains(final Offset position) {
    if (_points.isNotEmpty) {
      return path.contains(position);
    }

    return (position - center).distanceSquared < _buttonRadiusSquared;
  }

  LText get title => _title;

  double get titleFontSize => _titleFontSize;

  String get buttonIcon => _buttonIcon ?? '';

  double get buttonSize => _buttonSize;

  double get _buttonRadiusSquared => 0.5 * buttonSize * 0.5 * buttonSize;

  LText get actionTitle => _actionTitle;

  LText get action => _action;

  Offset get center => _center;
}

class FloorText {
  final Offset _location;
  final double _angle;
  final int _align;
  final double _fontSize;
  final LText _text;

  FloorText._(this._location, this._angle, this._align, this._fontSize, this._text);

  FloorText.parse(final dynamic json) : this._(
    Offset(json['location'][0].toDouble(), json['location'][1].toDouble()),
    json['angle']?.toDouble() ?? 0.0,
    json['alignment']?.toInt() ?? TextAlign.center.index,
    json['fontSize']?.toDouble(),
    LText(json['text']),
  );

  Offset get location => _location;

  double get angle => _angle;

  TextAlign get textAlign => TextAlign.values.skip(_align).firstWhere((_) => true, orElse: () => TextAlign.center);

  double get fontSize => _fontSize;

  LText get text => _text;

}
