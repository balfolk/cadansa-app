import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadansa_app/data/global_config.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final GlobalEvent event;
  final VoidCallback onTap;
  final bool isSelected;

  const EventTile({
    Key key,
    @required this.event,
    @required this.isSelected,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: event.primarySwatch,
            style: isSelected ? BorderStyle.solid : BorderStyle.none,
            width: 2.0,
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          backgroundColor: event.primarySwatch,
          backgroundImage: CachedNetworkImageProvider(event.avatarUri),
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
