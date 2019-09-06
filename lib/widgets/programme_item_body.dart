import 'package:cadansa_app/data/programme.dart';
import 'package:flutter/material.dart';
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
      columnItems.add(Row(children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(Icons.info, color: theme.primaryColor,),
        ),
        Text(kind),
      ]));
    }

    final String location = _item.location.get(locale);
    if (location.isNotEmpty) {
      columnItems.add(Row(children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(Icons.location_on, color: theme.primaryColor,),
        ),
        Text(location),
      ]));
    }

    final String teacher = _item.teacher.get(locale);
    if (teacher.isNotEmpty) {
      columnItems.add(Row(children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(Icons.person, color: theme.primaryColor,),
        ),
        Text(teacher),
      ]));
    }

    final String level = _item.level.name.get(locale);
    if (level.isNotEmpty) {
      columnItems.add(Row(children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.only(start: 20.0, end: 12.0),
          child: Icon(Icons.equalizer, color: theme.primaryColor,),
        ),
        Text(level),
      ]));
    }

    if (location.isNotEmpty || teacher.isNotEmpty) {
      columnItems.add(const SizedBox(height: 15.0));
    }

    columnItems.add(Container(
      child: Text(_item.description.get(locale)),
      padding: EdgeInsetsDirectional.only(
          start: 20.0, end: 20.0, bottom: 20.0),
    ));

    if (_item.website != null && _item.website.isNotEmpty) {
      columnItems.add(OutlineButton.icon(
        onPressed: () => launch(_item.website),
        label: Text('Website', style: urlStyle,),
        icon: Icon(Icons.link),
      ));
    }

    return Column(children: columnItems);
  }
}
