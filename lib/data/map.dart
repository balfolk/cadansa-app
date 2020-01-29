import 'dart:ui';

import 'package:cadansa_app/data/parse_utils.dart';

class MapData {
  final List<Floor> _floors;

  MapData._(this._floors);

  MapData.parse(final dynamic json)
    : this._((json as List)
        .map((d) => Floor.parse(d))
        .toList(growable: false));

  List<Floor> get floors => List.unmodifiable(_floors);
}

class Floor {
  final LText _title;
  final LText _url;
  final int _version;
  final double _initialScale, _minScale, _maxScale;
  final List<FloorArea> _areas;

  Floor._(this._title, this._url, this._version, this._initialScale, this._minScale, this._maxScale, this._areas);

  Floor.parse(final dynamic json) : this._(
      LText(json['title']),
      LText(json['path']),
      json['version'] as int,
      json['initialScale'] as double,
      json['minScale'] as double,
      json['maxScale'] as double,
      List.unmodifiable((json['areas'] ?? []).map((area) => FloorArea.parse(area))));

  LText get title => _title;

  LText get url => _url;

  int get version => _version;

  double get initialScale => _initialScale;

  double get minScale => _minScale;

  double get maxScale => _maxScale;

  List<FloorArea> get areas => _areas;
}

class FloorArea {
  final Path _path;
  final LText _title;
  final String _action;
  final Offset _center;

  FloorArea._(this._path, this._title, this._action, this._center);

  FloorArea.parse(final dynamic json) : this._(
    Path()..addPolygon(json['path'].map((point) => Offset(point[0].toDouble(), point[1].toDouble())).cast<Offset>().toList(), true),
    LText(json['title']),
    json['action'],
    Offset(json['center'][0].toDouble(), json['center'][1].toDouble()),
  );

  Path get path => Path.from(_path);

  LText get title => _title;

  String get action => _action;

  Offset get center => _center;
}