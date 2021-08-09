import 'dart:ui';

import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {

  late Locale _und, _enUs;

  setUp(() {
    _und = const Locale('UND');
    _enUs = const Locale('en', 'US');
  });

  test('LText(string)', () {
    expect(LText('foo').get(_und), 'foo');
    expect(LText('bar_%s').get(_und), 'bar_UND');
    expect(LText('bar_%s_%s').get(_und), 'bar_UND_');
    expect(LText('bar_%s+%s').get(_enUs), 'bar_en+US');
  });

  test('LText(map)', () {
    expect(LText(const {'und': 'foo', 'en': 'bar'}).get(_und), 'foo');
    expect(LText(const {'fr': 'foo', 'en': 'bar'}).get(_enUs), 'bar');
    expect(LText(const {'fr': 'foo', 'en_GB': 'bar'}).get(_enUs), 'bar');
    expect(LText(const {'en_US': 'foo', 'en_GB': 'bar'}).get(_enUs), 'foo');
    expect(LText(const {'en': 'foo', 'en_GB': 'bar'}).get(_enUs), 'foo');
    expect(LText(const {'en': 'foo', 'en_GB': 'bar'}).get(_und), 'foo');
    expect(LText(const <String, dynamic>{}).get(_und), '');
    expect(LText(const <String, String>{}).get(_und), '');
    expect(LText(const <String, int>{}).get(_und), '');
    expect(LText(const <dynamic, dynamic>{}).get(_und), '');
  });

  test('LText(other)', () {
    expect(LText(42).get(_und), '42');
    expect(LText(3.14).get(_und), '3.14');
    expect(LText(const ['foo', 83]).get(_und), '[foo, 83]');
    expect(LText(const <dynamic>[]).get(_und), '');
    expect(LText(const <dynamic>{}).get(_und), '');
    expect(LText(const Iterable<dynamic>.empty()).get(_und), '');
    expect(LText(null).get(_und), '');
  });

  test('LText.empty()', () {
    expect(const LText.empty().get(_enUs), '');
    expect(const LText.empty().get(_und), '');
  });

  test('parseNum', () {
    expect(parseNum(42), 42);
    expect(parseNum(3.14), 3.14);

    expect(parseNum('42'), 42);
    expect(parseNum('3.14 \t'), 3.14);

    expect(parseNum('bla'), isNull);
    expect(parseNum(''), isNull);
    expect(parseNum(<dynamic, dynamic>{}), isNull);
    expect(parseNum(<dynamic>{}), isNull);
    expect(parseNum(<dynamic>[]), isNull);
    expect(parseNum(null), isNull);
  });

  test('parseDateTime', () {
    expect(parseDateTime('42'), DateTime.fromMillisecondsSinceEpoch(42));
    expect(parseDateTime('83.1 \t'), DateTime.fromMillisecondsSinceEpoch(83));
    expect(parseDateTime(42.1), DateTime.fromMillisecondsSinceEpoch(42));
    expect(parseDateTime(83.9), DateTime.fromMillisecondsSinceEpoch(83));

    expect(parseDateTime(''), isNull);
    expect(parseDateTime(null), isNull);
    expect(() => parseDateTime(<dynamic, dynamic>{}), throwsArgumentError);
    expect(() => parseDateTime('bla'), throwsArgumentError);
  });

  test('parseTimeOfDay', () {
    expect(parseTimeOfDay('13:37'), const TimeOfDay(hour: 13, minute: 37));
    expect(parseTimeOfDay('\t23  : 59'), const TimeOfDay(hour: 23, minute: 59));
    expect(parseTimeOfDay('14.42: 12.'), const TimeOfDay(hour: 14, minute: 12));

    expect(parseTimeOfDay(''), isNull);
    expect(parseTimeOfDay(null), isNull);

    expect(() => parseTimeOfDay('42:12'), throwsArgumentError);
    expect(() => parseTimeOfDay('-1:12'), throwsArgumentError);
    expect(() => parseTimeOfDay('13:60'), throwsArgumentError);
    expect(() => parseTimeOfDay('13:-1'), throwsArgumentError);

    expect(() => parseTimeOfDay(<dynamic, dynamic>{}), throwsArgumentError);
    expect(() => parseTimeOfDay('bla'), throwsArgumentError);
    expect(() => parseTimeOfDay('12:32:12'), throwsArgumentError);
    expect(() => parseTimeOfDay('12'), throwsArgumentError);
    expect(() => parseTimeOfDay(15), throwsArgumentError);
    expect(() => parseTimeOfDay(15.12), throwsArgumentError);
  });
}
