import 'dart:ui';

import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

const DEFAULT_PRIMARY_SWATCH = Colors.teal;

MaterialColor? getPrimarySwatch(final int? index) {
  return Colors.primaries.elementAtOrNull(index);
}

Color? getAccentColor(final int? index) {
  return Colors.accents.elementAtOrNull(index);
}

Future<void> openInAppBrowser(final String url) async {
  final parsed = Uri.tryParse(url);
  if (parsed == null) return;

  return ChromeSafariBrowser().open(
    url: parsed,
    options: ChromeSafariBrowserClassOptions(
      android: AndroidChromeCustomTabsOptions(),
      ios: IOSSafariOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: IOSSafariDismissButtonStyle.CLOSE,
      ),
    ),
  );
}
