import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';

class LocaleWidgets extends StatelessWidget {
  const LocaleWidgets({
    required this.locales,
    required this.activeLocale,
    required this.setLocale,
    super.key,
  });

  final Iterable<Locale> locales;
  final Locale activeLocale;
  final void Function(Locale) setLocale;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.unmodifiable(locales.map<Widget>((locale) => _LocaleWidget(
        locale: locale,
        isActive: locale == activeLocale,
        onPressed: locale == activeLocale ? null : () => setLocale(locale),
      ))),
    );
  }
}

class _LocaleWidget extends StatelessWidget {
  const _LocaleWidget({
    required this.locale,
    required this.isActive,
    required this.onPressed,
  });

  final Locale locale;
  final bool isActive;
  final void Function()? onPressed;

  // Increase the flag size on iOS since somehow they're much smaller there
  static const _iosFlagScaleFactor = 2.0;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    MaterialStateProperty<BorderSide?>? border;
    if (isActive) {
      border = MaterialStateProperty.all(BorderSide(
        color: theme.primaryColor,
        width: 2.0,
      ));
    }

    return Tooltip(
      message: locale.languageCode,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(
            theme.textTheme.labelLarge?.color,
          ),
          side: border,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Text(
            stringToUnicodeFlag(locale.countryCode),
            textScaler: theme.platform == TargetPlatform.iOS
                ? const TextScaler.linear(_iosFlagScaleFactor)
                : null,
          ),
        ),
      ),
    );
  }
}
