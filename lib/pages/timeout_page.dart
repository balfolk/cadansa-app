import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TimeoutPage extends StatelessWidget {
  const TimeoutPage(this._onRefresh, {super.key});

  final VoidCallback _onRefresh;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(APP_TITLE),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(
              Localization.TIMEOUT_MESSAGE.get(Localizations.localeOf(context)),
              textAlign: TextAlign.center,
            ),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: Icon(MdiIcons.refresh),
              label: Text(Localization.REFRESH.get(Localizations.localeOf(context))),
            )],
          ),
        ),
      ),
    );
  }
}
