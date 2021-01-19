import 'package:cadansa_app/data/parse_utils.dart';
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
  @required final BuildContext context,
  @required final String text,
  String message,
}) {
  _setClipboardText(text);

  message ??= _COPIED.get(Localizations.localeOf(context));
  if (message.isNotEmpty) {
    Scaffold.of(context, nullOk: true)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }
}

const int _DIFF_FLAG_LETTER = 127462 - 65;

/// Convert a string to the corresponding Unicode flag emoji. To work properly,
/// the input string must contain exactly two ASCII letters that together form
/// a Unicode flag.
String stringToUnicodeFlag(final String s) {
  if (s == null || s.isEmpty) return '';
  return String.fromCharCodes(s.toUpperCase().codeUnits
      .map((cu) => cu + _DIFF_FLAG_LETTER));
}

Future<void> openInAppBrowser(final String url) async {
  return ChromeSafariBrowser(bFallback: InAppBrowser()).open(
    url: url,
    options: ChromeSafariBrowserClassOptions(
      android: AndroidChromeCustomTabsOptions(),
      ios: IOSSafariOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: IOSSafariDismissButtonStyle.CLOSE,
      ),
    ),
  );
}
