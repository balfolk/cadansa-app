import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/parse_utils.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/util/localization.dart';
import 'package:cadansa_app/util/page_util.dart';
import 'package:cadansa_app/util/refresher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:webfeed/webfeed.dart';

class FeedPage extends StatefulWidget {
  final LText _title;
  final LText _feedUrl;
  final PageHooks _pageHooks;

  FeedPage(this._title, this._feedUrl, this._pageHooks, {final Key key})
      : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

enum _FeedPageStatus {
  LOADING,
  DONE,
  ERROR
}

class _FeedPageState extends State<FeedPage> {
  _FeedPageStatus _status;
  String _feed;

  static const _FETCH_TIMEOUT = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _status = _FeedPageStatus.LOADING;
    _feed = null;
  }

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

  Future<String> _fetchFeed() async {
    final url = widget._feedUrl.get(Localizations.localeOf(context));
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
      drawer: widget._pageHooks.buildDrawer(context),
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
      Center(child: const CircularProgressIndicator());

  Widget _buildError(final BuildContext context) => Center(
    child: AutoSizeText(
      Localization.TIMEOUT_MESSAGE.get(Localizations.localeOf(context)),
    ),
  );

  Widget _buildFeed(final BuildContext context) {
    RssFeed feed;
    try {
      feed = RssFeed.parse(_feed);
    // ignore: avoid_catching_errors
    } on ArgumentError {
      // Do nothing, feed will be null
    }
    if (feed?.items == null || feed.items.isEmpty) {
      return _buildEmptyFeed(context);
    }

    return Refresher(
      onRefresh: _fetchFeed,
      child: ListView.separated(
        itemBuilder: (context, index) => FeedItem(feed.items[index]),
        separatorBuilder: (context, _) => const Divider(),
        itemCount: feed.items.length,
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
  final RssItem _item;

  FeedItem(this._item, {final Key key})
      : assert(_item != null),
        super(key: key);

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
      onTap: _open,
    );
  }

  String _subtitle(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final date = _item.pubDate != null ? DateFormat.yMMMMEEEEd(locale.toLanguageTag()).format(_item.pubDate) : '';
    final time = _item.pubDate != null ? DateFormat.jm(locale.toLanguageTag()).format(_item.pubDate) : '';
    final dateTime = '$date $time'.trim();
    final parts = [_item.author, dateTime].where((s) => s.isNotEmpty);
    return parts.join(' • ');
  }

  void _open() {
    if (_item.link?.trim()?.isNotEmpty ?? false) {
      openInAppBrowser(_item.link);
    }
  }
}
