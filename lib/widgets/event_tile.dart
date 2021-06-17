import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final GlobalEvent event;
  final VoidCallback onTap;
  final bool isSelected;

  const EventTile({
    Key? key,
    required this.event,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

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
            width: 2.0,
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          backgroundColor: event.primarySwatch ?? DEFAULT_PRIMARY_SWATCH,
          backgroundImage: avatarUri != null
              ? CachedNetworkImageProvider(avatarUri)
              : null,
        ),
      ),
      title: Text(
        event.title.get(locale),
      ),
      subtitle: Text(
        event.subtitle.get(locale),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
