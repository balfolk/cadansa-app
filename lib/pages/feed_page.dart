import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/page.dart';
import 'package:cadansa_app/util/localization.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/util/refresher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rss_dart/dart_rss.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.data,
    required this.pageHooks,
    required this.getReadGuids,
    required this.setReadGuid,
  });

  final FeedPageData data;
  final PageHooks pageHooks;
  final Set<String> Function() getReadGuids;
  final Future<void> Function(String?) setReadGuid;

  @override
  FeedPageState createState() => FeedPageState();
}

enum _FeedPageStatus {
  LOADING,
  DONE,
  ERROR
}

class FeedPageState extends State<FeedPage> {
  _FeedPageStatus _status = _FeedPageStatus.LOADING;
  String? _feed;

  static const _FETCH_TIMEOUT = Duration(seconds: 5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshFeed();
  }

  Future<void> _refreshFeed() async {
    final feed = await _fetchFeed();
    if (mounted) {
      setState(() {
        _feed = feed;
        _status = _feed != null ? _FeedPageStatus.DONE : _FeedPageStatus.ERROR;
      });
    }
  }

  Future<String?> _fetchFeed() async {
    final url = Uri.tryParse(widget.data.feedUrl.get(Localizations.localeOf(context)));
    if (url == null) return null;

    try {
      return await http.read(url).timeout(_FETCH_TIMEOUT);
    } on Exception catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @override
  Widget build(final BuildContext context) => widget.pageHooks.buildScaffold(
    body: _buildBody(context),
  );

  Widget _buildBody(final BuildContext context) {
    switch (_status) {
      case _FeedPageStatus.LOADING:
        return _buildLoading(context);
      case _FeedPageStatus.DONE:
        return _buildFeed(context);
      case _FeedPageStatus.ERROR:
      default:
        return _buildError(context);
    }
  }

  Widget _buildLoading(final BuildContext context) =>
      const Center(child: CircularProgressIndicator());

  Widget _buildError(final BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: AutoSizeText(
        Localization.TIMEOUT_MESSAGE.get(Localizations.localeOf(context)),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _buildFeed(final BuildContext context) {
    RssFeed? feed;
    try {
      final feedString = _feed;
      if (feedString != null) {
        feed = RssFeed.parse(feedString);
      }
    // ignore: avoid_catching_errors
    } on ArgumentError {
      feed = null;
    }

    final feedItems = feed?.items;
    final Widget list;
    if (feedItems != null && feedItems.isNotEmpty) {
      final readGuids =
          widget.data.supportsUnread ? widget.getReadGuids() : null;
      list = ListView.separated(
        itemBuilder: (context, index) {
          final item = feedItems[index];
          return FeedItem(
            item: item,
            read: readGuids == null || readGuids.contains(item.guid),
            onPressed: () => _openItem(item),
          );
        },
        separatorBuilder: (context, _) => const Divider(),
        itemCount: feedItems.length,
      );
    } else {
      list = _buildEmptyFeed();
    }

    return Refresher(
      onRefresh: _fetchFeed,
      child: list,
    );
  }

  Widget _buildEmptyFeed() => LayoutBuilder(
    builder: (context, constraints) => ListView(
      children: [
        SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Text(
              widget.data.feedEmptyText.get(Localizations.localeOf(context)),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _openItem(final RssItem item) async {
    final link = item.link?.trim();
    if (link != null && link.isNotEmpty) {
      await widget.pageHooks.actionHandler('url:$link');
      setState(() {
        widget.setReadGuid(item.guid);
      });
    }
  }
}

class FeedItem extends StatelessWidget {
  const FeedItem({
    super.key,
    required this.item,
    this.read = true,
    required this.onPressed,
  });

  final RssItem item;
  final bool read;
  final VoidCallback onPressed;

  static final _RSS_DATE_FORMAT = DateFormat('E, d MMM y H:m:s Z', 'en_US');

  @override
  Widget build(final BuildContext context) {
    return ListTile(
      selected: !read,
      title: Text(
        item.title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: read ? null : const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        _subtitle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onPressed,
    );
  }

  String _subtitle(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    DateTime? pubDate;
    try {
      pubDate = _RSS_DATE_FORMAT.parseUtc(item.pubDate ?? '').toLocal();
    } catch (_) {
      pubDate = null;
    }
    final dateTime = pubDate != null
        ? DateFormat.yMMMMEEEEd(locale.toLanguageTag()).add_jm().format(pubDate)
        : null;

    final parts = [item.author, dateTime].nonNulls;
    return parts.where((part) => part.isNotEmpty).join(' • ');
  }
}
