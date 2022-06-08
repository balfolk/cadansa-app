import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {

  late Locale und, enUs;

  setUp(() {
    und = const Locale('UND');
    enUs = const Locale('en', 'US');
  });

  test('LText(string)', () {
    expect(LText('foo').get(und), 'foo');
    expect(LText('bar_%s').get(und), 'bar_UND');
    expect(LText('bar_%s_%s').get(und), 'bar_UND_');
    expect(LText('bar_%s+%s').get(enUs), 'bar_en+US');
  });

  test('LText(map)', () {
    expect(LText(const {'und': 'foo', 'en': 'bar'}).get(und), 'foo');
    expect(LText(const {'fr': 'foo', 'en': 'bar'}).get(enUs), 'bar');
    expect(LText(const {'fr': 'foo', 'en_GB': 'bar'}).get(enUs), 'bar');
    expect(LText(const {'en_US': 'foo', 'en_GB': 'bar'}).get(enUs), 'foo');
    expect(LText(const {'en': 'foo', 'en_GB': 'bar'}).get(enUs), 'foo');
    expect(LText(const {'en': 'foo', 'en_GB': 'bar'}).get(und), 'foo');
    expect(LText(const <String, dynamic>{}).get(und), '');
    expect(LText(const <String, String>{}).get(und), '');
    expect(LText(const <String, int>{}).get(und), '');
    expect(LText(const <dynamic, dynamic>{}).get(und), '');
  });

  test('LText(other)', () {
    expect(LText(42).get(und), '42');
    expect(LText(3.14).get(und), '3.14');
    expect(LText(const ['foo', 83]).get(und), '[foo, 83]');
    expect(LText(const <dynamic>[]).get(und), '');
    expect(LText(const <dynamic>{}).get(und), '');
    expect(LText(const Iterable<dynamic>.empty()).get(und), '');
    expect(LText(null).get(und), '');
  });

  test('LText.empty()', () {
    expect(const LText.empty().get(enUs), '');
    expect(const LText.empty().get(und), '');
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

  test('parseDuration', () {
    expect(parseDuration('42'), const Duration(milliseconds: 42));
    expect(parseDuration('83.1 \t'), const Duration(milliseconds: 83));
    expect(parseDuration(42.1), const Duration(milliseconds: 42));
    expect(parseDuration(83.9), const Duration(milliseconds: 83));

    expect(parseDuration(''), isNull);
    expect(parseDuration(null), isNull);
    expect(parseDuration(<dynamic, dynamic>{}), isNull);
    expect(parseDuration('bla'), isNull);
  });
}
