import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgrammeItemBody extends StatelessWidget {
  const ProgrammeItemBody({required this.item, required this.actionHandler});

  final ProgrammeItem item;
  final ActionHandler actionHandler;

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final kindName = item.kind.name.get(locale);
    final locationTitle = item.location?.title.get(locale) ?? '';
    final locationAction = item.location?.action;
    final teacherTitle = item.teacher.get(locale);
    final levelTitle = item.level.name.get(locale);
    final propertyItems = <Widget>[
      if (kindName.isNotEmpty)
        ProgrammeItemPropertyWidget(
          icon: findIcon(item.kind.icon),
          text: kindName,
        ),
      if (locationTitle.isNotEmpty)
        ProgrammeItemPropertyWidget(
          onTap: locationAction != null
              ? () => actionHandler(locationAction)
              : null,
          icon: MdiIcons.mapMarker,
          text: locationTitle,
        ),
      if (teacherTitle.isNotEmpty)
        ProgrammeItemPropertyWidget(
          icon: MdiIcons.school,
          text: teacherTitle,
        ),
      if (levelTitle.isNotEmpty)
        ProgrammeItemPropertyWidget(
          icon: findIcon(item.level.icon),
          text: levelTitle,
        ),
    ];

    final websiteText = item.website.text;
    final websiteUrl = item.website.url;
    final columnItems = <Widget>[
      if (propertyItems.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Column(
            children: propertyItems,
          ),
        ),
      Text(item.description.get(locale)),
      if (websiteText != null && websiteUrl != null)
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: OutlinedButton.icon(
            onPressed: () {
              final uri = Uri.tryParse(websiteUrl.get(locale));
              if (uri != null) {
                launchUrl(uri);
              }
            },
            icon: Icon(findIcon(item.website.icon)),
            label: Text(
              websiteText.get(locale),
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColor),
            ),
          ),
        ),
    ];

    return Column(children: columnItems);
  }
}

class ProgrammeItemPropertyWidget extends StatelessWidget {
  const ProgrammeItemPropertyWidget({
    required final IconData? icon,
    required final String text,
    final VoidCallback? onTap,
  })  : _icon = icon,
        _text = text,
        _onTap = onTap;

  final IconData? _icon;
  final String _text;
  final VoidCallback? _onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _onTap,
      onLongPress: () => _copyText(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12.0),
            child: Icon(_icon, color: theme.primaryColor),
          ),
          Expanded(
            child: AutoSizeText(
              _text,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _copyText(final BuildContext context) =>
      reportClipboardText(context: context, text: _text);
}
