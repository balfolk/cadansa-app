import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cadansa_app/data/event.dart';
import 'package:cadansa_app/data/programme.dart';
import 'package:cadansa_app/global.dart';
import 'package:cadansa_app/util/flutter_util.dart';
import 'package:cadansa_app/util/temporal_state.dart';
import 'package:cadansa_app/widgets/programme_item_body.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';

class ProgrammeItemsList extends StatelessWidget {
  const ProgrammeItemsList({
    required this.day,
    required this.openIndex,
    required this.trailing,
    required this.doColorIcons,
    required this.actionHandler,
    Key? key,
  }) : super(key: key);

  final ProgrammeDay day;
  final int? openIndex;
  final Widget? Function(ProgrammeItem) trailing;
  final bool doColorIcons;
  final ActionHandler actionHandler;

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final openIndex = this.openIndex;
    return ScrollablePositionedList.separated(
      itemCount: day.items.length,
      initialScrollIndex: openIndex != null ? max(0, openIndex) : 0,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = day.items[index];
        final isExpandable = item.description.get(locale).isNotEmpty;
        final startTime = item.startTime;
        final endTime = item.endTime;

        String subtitleText;
        if (endTime != null) {
          subtitleText = '${startTime.format(context)} – ${endTime.format(context)}';
        } else {
          subtitleText = startTime.format(context);
        }
        final subtitle = Text(subtitleText);

        final Widget header = ListTile(
          leading: _getIcon(context: context, item: item),
          title: AutoSizeText(
            '${item.name.get(locale)} ${item.countries.map(stringToUnicodeFlag).join(' ')}',
            style: theme.textTheme.headline6,
            maxLines: 2,
            softWrap: true,
          ),
          trailing: trailing(item),
          subtitle: subtitle,
        );

        if (isExpandable) {
          final expandableController = index == openIndex
              ? ExpandableController(initialExpanded: true)
              : null;
          return ExpandableNotifier(
            child: ScrollOnExpand(
              child: ExpandablePanel(
                controller: expandableController,
                theme: const ExpandableThemeData(
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                ),
                header: header,
                collapsed: const SizedBox.shrink(),
                expanded: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 15.0, bottom: 10.0),
                  child: ProgrammeItemBody(
                    item: item,
                    actionHandler: actionHandler,
                  ),
                ),
              ),
            ),
          );
        } else {
          return header;
        }
      },
    );
  }

  Widget? _getIcon({
    required final BuildContext context,
    required final ProgrammeItem item,
  }) {
    final itemKindIcon = item.kind.icon;
    if (itemKindIcon == null) return null;

    final iconData = MdiIcons.fromString(itemKindIcon);
    if (iconData?.codePoint == null) {
      debugPrint('Invalid icon $itemKindIcon');
      return null;
    }

    final status = _getPlayingStatus(item);
    if (item.kind.showIcon == ProgrammeItemKindShowIcon.never ||
        (item.kind.showIcon == ProgrammeItemKindShowIcon.during &&
            status != TemporalState.present)) {
      return null;
    }

    // Icons for the current event may be shown as grey, when they are in the past
    final color = doColorIcons && (status == null || status == TemporalState.past)
        ? Colors.grey
        : Theme.of(context).primaryColor;

    final icon = Icon(iconData,
      color: color,
      size: 36,
    );

    if (status == TemporalState.present) {
      return Shimmer.fromColors(
        baseColor: Theme.of(context).primaryColor,
        highlightColor: Theme.of(context).primaryColorLight,
        child: icon,
      );
    } else {
      return icon;
    }
  }

  TemporalState? _getPlayingStatus(final ProgrammeItem item) {
    // Anything with hours smaller than this number is in the "wee hours" and takes place on the preceding day
    const HOUR_NIGHT_CUTOFF = 6;

    final dayStartsOn = day.startsOn;
    if (dayStartsOn == null) {
      return null;
    }

    final itemStartTime = item.startTime;
    final startDay = DateTime(dayStartsOn.year, dayStartsOn.month, dayStartsOn.day);
    final startMoment = startDay.add(Duration(
        days: itemStartTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: itemStartTime.hour,
        minutes: itemStartTime.minute));
    final itemEndTime = item.endTime;
    final endMoment = itemEndTime != null ? startDay.add(Duration(
        days: itemEndTime.hour < HOUR_NIGHT_CUTOFF ? 1 : 0,
        hours: itemEndTime.hour,
        minutes: itemEndTime.minute)) : null;
    final now = DateTime.now();
    if (now.isBefore(startMoment)) return TemporalState.future;
    if (endMoment != null) {
      if (now.isAfter(endMoment)) return TemporalState.past;
      return TemporalState.present;
    } else {
      return TemporalState.past;
    }
  }
}
