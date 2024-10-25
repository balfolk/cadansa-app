import 'package:cadansa_app/global.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(APP_TITLE),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
