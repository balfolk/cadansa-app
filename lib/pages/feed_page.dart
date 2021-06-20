import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/util/localization.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/util/refresher.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:webfeed/webfeed.dart';

class FeedPage extends StatefulWidget {
  const FeedPage(this._title, this._feedUrl, this._pageHooks, {final Key? key})
      : super(key: key);

  final LText _title;
  final LText _feedUrl;
  final PageHooks _pageHooks;

  @override
  _FeedPageState createState() => _FeedPageState();
}

enum _FeedPageStatus {
  LOADING,
  DONE,
  ERROR
}

class _FeedPageState extends State<FeedPage> {
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
    setState(() {
      _feed = feed;
      _status = _feed != null ? _FeedPageStatus.DONE : _FeedPageStatus.ERROR;
    });
  }

  Future<String?> _fetchFeed() async {
    final url = Uri.tryParse(widget._feedUrl.get(Localizations.localeOf(context)));
    if (url == null) return null;

    try {
      return http.read(url).timeout(_FETCH_TIMEOUT);
    } on Exception catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._title.get(locale)),
      ),
      body: _buildBody(context),
      drawer: widget._pageHooks.buildDrawer(() => this.context),
      bottomNavigationBar: widget._pageHooks.buildBottomBar(),
    );
  }

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
    child: AutoSizeText(
      Localization.TIMEOUT_MESSAGE.get(Localizations.localeOf(context)),
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
    if (feedItems == null || feedItems.isEmpty) {
      return _buildEmptyFeed(context);
    }

    return Refresher(
      onRefresh: _fetchFeed,
      child: ListView.separated(
        itemBuilder: (context, index) => FeedItem(feedItems[index]),
        separatorBuilder: (context, _) => const Divider(),
        itemCount: feedItems.length,
      ),
    );
  }

  Widget _buildEmptyFeed(final BuildContext context) => Center(
    child: AutoSizeText(
      Localization.FEED_EMPTY.get(Localizations.localeOf(context)),
    ),
  );
}

class FeedItem extends StatelessWidget {
  const FeedItem(this._item, {final Key? key}) : super(key: key);

  final RssItem _item;

  @override
  Widget build(final BuildContext context) {
    return ListTile(
      title: Text(
        _item.title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _subtitle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _open(context),
    );
  }

  String _subtitle(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final pubDate = _item.pubDate;
    final dateTime = pubDate != null
        ? DateFormat.yMMMMEEEEd(locale.toLanguageTag()).add_jm().format(pubDate)
        : null;

    final parts = [_item.author, dateTime].whereNotNull();
    return parts.where((part) => part.isNotEmpty).join(' • ');
  }

  void _open(final BuildContext context) {
    final link = _item.link?.trim();
    if (link != null && link.isNotEmpty) {
      openInAppBrowser(context: context, url: link);
    }
  }
}
