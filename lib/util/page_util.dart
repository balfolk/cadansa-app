import 'package:cadansa_app/global.dart';
import 'package:flutter/material.dart';

class PageHooks {
  final Widget Function(BuildContext) buildDrawer;
  final Widget Function() buildBottomBar;
  final ActionHandler actionHandler;

  PageHooks({
    @required this.buildDrawer,
    @required this.buildBottomBar,
    @required this.actionHandler,
  });
}

class IndexedPageController {
  int index;
}
