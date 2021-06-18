import 'package:cadansa_app/global.dart';
import 'package:flutter/material.dart';

@immutable
class PageHooks {
  const PageHooks({
    required this.buildDrawer,
    required this.buildBottomBar,
    required this.actionHandler,
  });

  final Widget? Function(BuildContext Function()) buildDrawer;
  final Widget Function() buildBottomBar;
  final ActionHandler actionHandler;
}

class IndexedPageController {
  IndexedPageController({this.index});

  int? index;
}
