import 'package:cadansa_app/data/parse_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  final String _title;
  final LText _content;
  final Widget Function(BuildContext) _buildDrawer;
  final Widget Function() _buildBottomBar;

  InfoPage(this._title, this._content, this._buildDrawer, this._buildBottomBar,
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
      body: SingleChildScrollView(
        child: Html(
          data: widget._content.get(locale),
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          onLinkTap: launch,
        ),
      ),
      drawer: widget._buildDrawer(context),
      bottomNavigationBar: widget._buildBottomBar(),
    );
  }
}
