import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
