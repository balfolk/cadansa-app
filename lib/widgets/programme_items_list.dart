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
    super.key,
    required this.day,
    required this.openIndex,
    required this.trailing,
    required this.doColorIcons,
    required this.actionHandler,
  });

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
        final isExpandable =
            item.description.get(locale).isNotEmpty || item.website.url != null;
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
            style: theme.textTheme.titleLarge,
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
    final itemRange = day.rangeOfItem(item);
    if (itemRange == null) return null;

    final now = DateTime.now();
    if (now.isBefore(itemRange.start)) return TemporalState.future;
    if (now.isAfter(itemRange.end)) return TemporalState.past;
    return TemporalState.present;
  }
}
