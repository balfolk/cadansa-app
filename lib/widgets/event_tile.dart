import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.isSelected,
    required this.onTap,
    required this.isLarge,
  });

  final GlobalEvent event;
  final VoidCallback onTap;
  final bool isSelected, isLarge;

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final backgroundImage = getImageProvider(event.avatarUri);
    return ListTile(
      leading: backgroundImage != null
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: event.seedColor ?? DEFAULT_SEED_COLOR,
                  style: isSelected ? BorderStyle.solid : BorderStyle.none,
                  width: isLarge ? 3.0 : 2.0,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: event.seedColor ?? DEFAULT_SEED_COLOR,
                backgroundImage: backgroundImage,
                radius: isLarge ? 24.0 : 20.0,
              ),
            )
          : null,
      title: AutoSizeText(
        event.title.get(locale),
        textScaleFactor: isLarge ? 1.5 : 1.0,
      ),
      subtitle: AutoSizeText(
        formatDateRange(
          locale: locale,
          startDay: event.startDate,
          endDay: event.endDate,
        ),
        textScaleFactor: isLarge ? 1.2 : 1.0,
        maxLines: 1,
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
