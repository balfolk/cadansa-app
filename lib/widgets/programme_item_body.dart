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

  ProgrammeItemBody(this._item, this._actionHandler);

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final urlStyle = theme.textTheme.bodyText1.copyWith(color: theme.primaryColor);

    final columnItems = <Widget>[];

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: _item.kind?.icon != null ? MdiIcons.fromString(_item.kind?.icon) : null,
      text: _item.kind?.name?.get(locale),
    ));

    columnItems.add(ProgrammeItemPropertyWidget(
      icon: MdiIcons.mapMarker,
      text: _item.location?.title?.get(locale),
      onTap: _item.location?.action != null ? () => _actionHandler(_item.location.action) : null,
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
      padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 15.0, bottom: 10.0),
      child: Text(_item.description?.get(locale) ?? ''),
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
  final VoidCallback _onTap;

  ProgrammeItemPropertyWidget({
    @required final IconData icon,
    @required final String text,
    final VoidCallback onTap,
  })
      : _icon = icon,
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
