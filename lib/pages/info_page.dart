import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class InfoPage extends StatefulWidget {
  final String _title;
  final LText _content;
  final BottomNavigationBar Function() _bottomBarGenerator;

  InfoPage(this._title, this._content, this._bottomBarGenerator,
      {final Key key})
      : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(final BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._title),
      ),
      body: Html(data: widget._content.get(locale)),
      bottomNavigationBar: widget._bottomBarGenerator(),
    );
  }
}
