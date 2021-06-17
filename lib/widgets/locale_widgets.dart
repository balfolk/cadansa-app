import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';

class LocaleWidgets extends StatelessWidget {
  final Iterable<Locale> locales;
  final Locale activeLocale;
  final void Function(Locale) setLocale;

  const LocaleWidgets({
    required this.locales,
    required this.activeLocale,
    required this.setLocale,
  });

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
  final Locale locale;
  final bool isActive;
  final void Function()? onPressed;

  const _LocaleWidget({
    required this.locale,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    Widget widget = TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color?>(
          theme.textTheme.button?.color,
        ),
      ),
      child: Text(stringToUnicodeFlag(locale.countryCode)),
    );

    if (isActive) {
      widget = Container(
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(
            color: theme.primaryColor,
            width: 2.0,
          ),
        ),
        child: widget,
      );
    }

    return widget;
  }
}
