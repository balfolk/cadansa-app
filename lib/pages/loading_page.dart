import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/extensions.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Fix the status bar brightness - hopefully this becomes obsolete soon
        backwardsCompatibility: false,
        systemOverlayStyle: Theme.of(context).systemUiOverlayStyle,
        title: const Text(APP_TITLE),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
