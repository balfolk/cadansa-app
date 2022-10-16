import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    Key? key,
    required this.event,
    required this.isSelected,
    required this.onTap,
    required this.isLarge,
  }) : super(key: key);

  final GlobalEvent event;
  final VoidCallback onTap;
  final bool isSelected, isLarge;

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final avatarUri = event.avatarUri;
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: event.primarySwatch ?? DEFAULT_PRIMARY_SWATCH,
            style: isSelected ? BorderStyle.solid : BorderStyle.none,
            width: isLarge ? 3.0 : 2.0,
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          backgroundColor: event.primarySwatch ?? DEFAULT_PRIMARY_SWATCH,
          backgroundImage: avatarUri != null
              ? CachedNetworkImageProvider(avatarUri)
              : null,
          radius: isLarge ? 24.0 : 20.0,
        ),
      ),
      title: Text(
        event.title.get(locale),
        textScaleFactor: isLarge ? 1.5 : 1.0,
      ),
      subtitle: Text(
        formatDateRange(
          locale: locale,
          startDay: event.startDate,
          endDay: event.endDate,
        ),
        textScaleFactor: isLarge ? 1.2 : 1.0,
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
