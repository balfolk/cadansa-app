import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgrammeItemBody extends StatelessWidget {
  final ProgrammeItem _item;
  final ActionHandler _actionHandler;

  const ProgrammeItemBody(this._item, this._actionHandler);

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final urlStyle = theme.textTheme.bodyText1?.copyWith(color: theme.primaryColor);

    final columnItems = <Widget>[];

    final kindIcon = _item.kind.icon;
    columnItems.add(ProgrammeItemPropertyWidget(
      icon: kindIcon != null ? MdiIcons.fromString(kindIcon) : null,
      text: _item.kind.name.get(locale),
    ));

    final mapAction = _item.location?.action;
    columnItems.add(ProgrammeItemPropertyWidget(
      icon: MdiIcons.mapMarker,
      text: _item.location?.title.get(locale),
      onTap: mapAction != null ? () => _actionHandler(mapAction) : null,
    ));

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: MdiIcons.school,
      text: _item.teacher.get(locale),
    ));

    final levelIcon = _item.level.icon;
    columnItems.add(ProgrammeItemPropertyWidget(
      icon: levelIcon != null ? MdiIcons.fromString(levelIcon) : null,
      text: _item.level.name.get(locale),
    ));

    columnItems.add(Container(
      padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 15.0, bottom: 10.0),
      child: Text(_item.description.get(locale)),
    ));

    final websiteText = _item.website.text;
    if (websiteText != null) {
      final websiteIcon = _item.website.icon;
      final websiteUrl = _item.website.url;
      columnItems.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: OutlinedButton.icon(
          onPressed: websiteUrl != null ? () => launch(websiteUrl.get(locale)) : null,
          label: Text(websiteText.get(locale), style: urlStyle),
          icon: Icon(websiteIcon != null ? MdiIcons.fromString(websiteIcon) : null),
        ),
      ));
    }

    return Column(children: columnItems);
  }
}

class ProgrammeItemPropertyWidget extends StatelessWidget {
  final IconData? _icon;
  final String _text;
  final VoidCallback? _onTap;

  const ProgrammeItemPropertyWidget({
    required final IconData? icon,
    required final String? text,
    final VoidCallback? onTap,
  })  : _icon = icon,
        _text = text ?? '',
        _onTap = onTap;

  @override
  Widget build(final BuildContext context) {
    if (_text.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return InkWell(
      onTap: _onTap,
      onLongPress: () => _copyText(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
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
