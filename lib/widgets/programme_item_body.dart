import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/programme.dart';
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

    final String kind = _item.kind?.name?.get(locale);
    if (kind.isNotEmpty) {
      columnItems.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(MdiIcons.fromString(_item.kind.icon), color: theme.primaryColor),
        ),
        Expanded(
          child: AutoSizeText(
            kind,
            maxLines: 1,
          ),
        ),
      ]));
    }

    final String location = _item.location.get(locale);
    if (location.isNotEmpty) {
      columnItems.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(MdiIcons.mapMarker, color: theme.primaryColor),
        ),
        Expanded(
          child: AutoSizeText(
            location,
            maxLines: 1,
          ),
        ),
      ]));
    }

    final String teacher = _item.teacher.get(locale);
    if (teacher.isNotEmpty) {
      columnItems.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(MdiIcons.school, color: theme.primaryColor),
        ),
        Expanded(
          child: AutoSizeText(
            teacher,
            maxLines: 1,
          ),
        ),
      ]));
    }

    final String level = _item.level.name.get(locale);
    if (level.isNotEmpty) {
      columnItems.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(MdiIcons.fromString(_item.level.icon), color: theme.primaryColor),
        ),
        Expanded(
          child: AutoSizeText(
            level,
            maxLines: 1,
          ),
        ),
      ]));
    }

    columnItems.add(Container(
      child: Text(_item.description.get(locale)),
      padding: const EdgeInsetsDirectional.only(
          start: 20.0, end: 20.0, top: 15.0, bottom: 10.0),
    ));

    if (_item.website != null && _item.website.text != null) {
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
