import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  const InfoPage(this._title, this._content, this._pageHooks, {final Key? key})
      : super(key: key);

  final LText _title;
  final LText _content;
  final PageHooks _pageHooks;

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final content = sanitizeHtml(widget._content.get(locale));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._title.get(locale)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Html(
            data: content,
            onLinkTap: _onLinkTap,
          ),
        ),
      ),
      drawer: widget._pageHooks.buildDrawer(() => this.context),
      bottomNavigationBar: widget._pageHooks.buildBottomBar(),
    );
  }

  void _onLinkTap(
    String? url,
    RenderContext context,
    Map<String, String> attributes,
    Object? element,
  ) {
    if (url != null) {
      launch(url);
    }
  }
}
