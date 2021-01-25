import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  final LText _title;
  final LText _content;
  final PageHooks _pageHooks;

  InfoPage(this._title, this._content, this._pageHooks, {final Key key})
      : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._title.get(locale)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Html(
            data: widget._content.get(locale),
            onLinkTap: launch,
          ),
        ),
      ),
      drawer: widget._pageHooks.buildDrawer(() => this.context),
      bottomNavigationBar: widget._pageHooks.buildBottomBar(),
    );
  }
}
