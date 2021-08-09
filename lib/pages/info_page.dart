import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({
    required this.content,
    required this.pageHooks,
    final Key? key,
  }) : super(key: key);

  final LText content;
  final PageHooks pageHooks;

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(final BuildContext context) {
    const htmlAnchor = 'a';

    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final content = sanitizeHtml(widget.content.get(locale));
    return widget.pageHooks.buildScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Html(
            data: content,
            onLinkTap: _onLinkTap,
            style: {
              htmlAnchor: Style(color: theme.accentColor),
            },
          ),
        ),
      ),
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
