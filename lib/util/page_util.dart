import 'package:cadansa_app/global.dart';
import 'package:flutter/material.dart';

@immutable
class PageHooks {
  const PageHooks({
    required this.actionHandler,
    required this.buildScaffold,
  });

  final ActionHandler actionHandler;
  final Widget Function({
    PreferredSizeWidget? appBarBottomWidget,
    required Widget body,
  }) buildScaffold;
}

class IndexedPageController {
  IndexedPageController({this.index});

  int? index;
}
