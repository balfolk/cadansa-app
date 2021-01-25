import 'dart:ui';

import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {

  Locale _und, _enUs;

  setUp(() {
    _und = Locale('UND');
    _enUs = Locale('en', 'US');
  });

  test('LText.nullable', () {
    expect(LText.nullable(null), isNull);
    expect(LText.nullable('bla').get(_und), 'bla');
    expect(LText.nullable({'foo': 'bar'}).get(_und), 'bar');
  });

  test('LText(string)', () {
    expect(LText('foo').get(_und), 'foo');
    expect(LText('bar_%s').get(_und), 'bar_UND');
    expect(LText('bar_%s_%s').get(_und), 'bar_UND_');
    expect(LText('bar_%s+%s').get(_enUs), 'bar_en+US');
  });

  test('LText(map)', () {
    expect(LText({'und': 'foo', 'en': 'bar'}).get(_und), 'foo');
    expect(LText({'fr': 'foo', 'en': 'bar'}).get(_enUs), 'bar');
    expect(LText({'fr': 'foo', 'en_GB': 'bar'}).get(_enUs), 'bar');
    expect(LText({'en_US': 'foo', 'en_GB': 'bar'}).get(_enUs), 'foo');
    expect(LText({'en': 'foo', 'en_GB': 'bar'}).get(_enUs), 'foo');
    expect(LText({'en': 'foo', 'en_GB': 'bar'}).get(_und), 'foo');
    expect(LText(<String, dynamic>{}).get(_und), '');
    expect(LText(<String, String>{}).get(_und), '');
    expect(LText(<String, int>{}).get(_und), '');
    expect(LText(<dynamic, dynamic>{}).get(_und), '');
  });

  test('LText(other)', () {
    expect(LText(42).get(_und), '42');
    expect(LText(3.14).get(_und), '3.14');
    expect(LText(['foo', 83]).get(_und), '[foo, 83]');
    expect(LText(<dynamic>[]).get(_und), '[]');
    expect(LText(<dynamic>{}).get(_und), '{}');
    expect(LText(null).get(_und), '');
  });

  test('toDateTime', () {
    expect(toDateTime('42'), DateTime.fromMillisecondsSinceEpoch(42));
    expect(toDateTime('83.1 \t'), DateTime.fromMillisecondsSinceEpoch(83));
    expect(toDateTime(42.1), DateTime.fromMillisecondsSinceEpoch(42));
    expect(toDateTime(83.9), DateTime.fromMillisecondsSinceEpoch(83));

    expect(toDateTime(''), isNull);
    expect(toDateTime(null), isNull);
    expect(() => toDateTime({}), throwsArgumentError);
    expect(() => toDateTime('bla'), throwsArgumentError);
  });

  test('toTimeOfDay', () {
    expect(toTimeOfDay('13:37'), TimeOfDay(hour: 13, minute: 37));
    expect(toTimeOfDay('\t23  : 59'), TimeOfDay(hour: 23, minute: 59));
    expect(toTimeOfDay('14.42: 12.'), TimeOfDay(hour: 14, minute: 12));

    expect(toTimeOfDay(''), isNull);
    expect(toTimeOfDay(null), isNull);

    expect(() => toTimeOfDay('42:12'), throwsArgumentError);
    expect(() => toTimeOfDay('-1:12'), throwsArgumentError);
    expect(() => toTimeOfDay('13:60'), throwsArgumentError);
    expect(() => toTimeOfDay('13:-1'), throwsArgumentError);

    expect(() => toTimeOfDay({}), throwsArgumentError);
    expect(() => toTimeOfDay('bla'), throwsArgumentError);
    expect(() => toTimeOfDay('12:32:12'), throwsArgumentError);
    expect(() => toTimeOfDay('12'), throwsArgumentError);
    expect(() => toTimeOfDay(15), throwsArgumentError);
    expect(() => toTimeOfDay(15.12), throwsArgumentError);
  });
}
