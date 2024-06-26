import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({
    super.key,
    required this.content,
    required this.linkColor,
    required this.pageHooks,
  });

  final LText content;
  final Color? linkColor;
  final PageHooks pageHooks;

  @override
  InfoPageState createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
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
              htmlAnchor: Style(
                color: widget.linkColor ?? theme.colorScheme.secondary,
              ),
            },
          ),
        ),
      ),
    );
  }

  void _onLinkTap(
    final String? url,
    final Map<String, String> attributes,
    final Object? element,
  ) {
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }
}
