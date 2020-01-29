import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgrammeItemBody extends StatelessWidget {
  final ProgrammeItem _item;

  ProgrammeItemBody(this._item);

  @override
  Widget build(final BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle urlStyle = theme.textTheme.body2.copyWith(color: theme.primaryColor);

    final List<Widget> columnItems = [];

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: _item.kind?.icon != null ? MdiIcons.fromString(_item.kind?.icon) : null,
      text: _item.kind?.name?.get(locale),
    ));

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: MdiIcons.mapMarker,
      text: _item.location?.get(locale),
    ));

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: MdiIcons.school,
      text: _item.teacher?.get(locale),
    ));

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: _item.level?.icon != null ? MdiIcons.fromString(_item.level?.icon) : null,
      text: _item.level?.name?.get(locale),
    ));

    columnItems.add(Container(
      child: Text(_item.description?.get(locale) ?? ''),
      padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 15.0, bottom: 10.0),
    ));

    if (_item.website?.text != null) {
      columnItems.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: OutlineButton.icon(
          onPressed: () => launch(_item.website.url.get(locale)),
          label: Text(_item.website.text.get(locale), style: urlStyle),
          icon: Icon(MdiIcons.fromString(_item.website.icon)),
        ),
      ));
    }

    return Column(children: columnItems);
  }
}

class ProgrammeItemPropertyWidget extends StatelessWidget {
  final IconData _icon;
  final String _text;

  ProgrammeItemPropertyWidget({
    @required final IconData icon,
    @required final String text
  })
      : _icon = icon,
        _text = text ?? '';

  @override
  Widget build(final BuildContext context) {
    if (_text.isEmpty) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return InkWell(
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
