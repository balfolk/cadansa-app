import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

void _setClipboardText(final String text) =>
    Clipboard.setData(ClipboardData(text: text));

final _COPIED = LText(const {
  'en': 'Text copied',
  'nl': 'Tekst gekopieerd',
  'fr': 'Texte copié',
});

void reportClipboardText({
  required final BuildContext context,
  required final String text,
  String? message,
}) {
  _setClipboardText(text);

  message ??= _COPIED.get(Localizations.localeOf(context));
  if (message.isNotEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

const FONT_FEATURE_SMALL_CAPS = FontFeature.enable('smcp');

const _DIFF_FLAG_LETTER = 0x01F1E6 - 0x41; // '🇦' - 'A';

/// Convert a string to the corresponding Unicode flag emoji. To work properly,
/// the input string must contain exactly two ASCII letters that together form
/// a Unicode flag.
String stringToUnicodeFlag(final String? s) {
  if (s == null || s.isEmpty) return '';
  return String.fromCharCodes(s.toUpperCase().codeUnits
      .map((cu) => cu + _DIFF_FLAG_LETTER));
}

String formatDateRange({
  required final Locale locale,
  required final DateTime startDay,
  final DateTime? endDay,
}) {
  final formatLocale = locale.toLanguageTag();
  final fullFormatter = DateFormat.yMMMMd(formatLocale);

  if (endDay == null) {
    return fullFormatter.format(startDay);
  }

  final DateFormat shortFormatter;
  if (startDay.month == endDay.month) {
    if (startDay.day == endDay.day) {
      return fullFormatter.format(startDay);
    }
    shortFormatter = DateFormat.d(formatLocale);
  } else if (startDay.year == endDay.year) {
    shortFormatter = DateFormat.MMMMd(formatLocale);
  } else {
    shortFormatter = fullFormatter;
  }

  return '${shortFormatter.format(startDay)} – ${fullFormatter.format(endDay)}';
}

const DEFAULT_PRIMARY_SWATCH = Colors.teal;

MaterialColor? getPrimarySwatch(final int? colorValue) {
  if (colorValue == null) return null;
  return createMaterialColor(Color(colorValue));
}

const _MATERIAL_COLOR_INDICES = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
MaterialColor createMaterialColor(final Color color) {
  final r = color.red, g = color.green, b = color.blue;
  final swatch = <int, Color>{};
  for (final index in _MATERIAL_COLOR_INDICES) {
    final ds = 0.5 - (index / 1000);
    swatch[index] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

IconData? findIcon(final String? key) {
  return key != null ? MdiIcons.fromString(key) : null;
}

ImageProvider? getImageProvider(final String? imageUri) {
  if (imageUri == null) {
    return null;
  }

  if (imageUri.startsWith('http')) {
    return CachedNetworkImageProvider(imageUri);
  } else {
    return AssetImage(imageUri);
  }
}