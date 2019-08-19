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
  final String _url;
  final int _version;
  final double _initialScale, _minScale, _maxScale;

  Floor._(this._title, this._url, this._version, this._initialScale, this._minScale, this._maxScale);

  Floor.parse(final dynamic json)
      : this._(
      LText(json['title']),
      json['path'],
      json['version'] as int,
      json['initialScale'] as double,
      json['minScale'] as double,
      json['maxScale'] as double);

  LText get title => _title;

  String get url => _url;

  int get version => _version;

  double get initialScale => _initialScale;

  double get minScale => _minScale;

  double get maxScale => _maxScale;
}