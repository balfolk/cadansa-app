import 'package:cadansa_app/data/parse_utils.dart';
import 'package:circular_reveal_animation/circular_reveal_animation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    Key? key,
    required this.isFavorite,
    required this.innerColor,
    required this.outerColor,
    required this.onPressed,
    required this.tooltip,
  }) : super(key: key);

  final bool isFavorite;
  final Color innerColor, outerColor;
  final VoidCallback onPressed;
  final LText tooltip;

  @override
  FavoriteButtonState createState() => FavoriteButtonState();
}

class FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {

  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: widget.isFavorite ? 1.0 : 0.0,
  );

  /// Experimentally determined actor which makes the animation fill the heart exactly.
  static const _HEART_SIZE_FACTOR = 1.0 / 2.6;

  @override
  void didUpdateWidget(covariant final FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final locale = Localizations.localeOf(context);
    final iconSize = IconTheme.of(context).size;
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          CircularRevealAnimation(
            animation: animationController,
            maxRadius: iconSize != null ? iconSize * _HEART_SIZE_FACTOR : null,
            child: Icon(MdiIcons.heart, color: widget.innerColor),
          ),
          Icon(MdiIcons.heartOutline, color: widget.outerColor),
        ],
      ),
      tooltip: widget.tooltip.get(locale),
      onPressed: widget.onPressed,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
