import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _offsetToArmed = 100.0;

class Refresher extends StatelessWidget {
  const Refresher({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function()? onRefresh;
  final Widget child;

  @override
  Widget build(final BuildContext context) => onRefresh != null ? CustomRefreshIndicator(
    onRefresh: _onRefresh,
    offsetToArmed: _offsetToArmed,
    builder: (context, child, controller) => _MyRefreshIndicator(
      controller: controller,
      child: child,
    ),
    child: child,
  ) : child;

  Future<void> _onRefresh() async {
    _hapticResponse();
    await onRefresh?.call();
  }

  void _hapticResponse() {
    HapticFeedback.mediumImpact();
  }
}

class _MyRefreshIndicator extends StatelessWidget {
  const _MyRefreshIndicator({required this.controller, required this.child});

  final IndicatorController controller;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    const startDrawingPosition = 0.5;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double? progress;
        if (controller.isDragging || controller.isCanceling || controller.isFinalizing) {
          progress = (controller.value - startDrawingPosition) / startDrawingPosition;
        } else if (controller.isArmed) {
          progress = 1.0;
        }

        return Stack(
          children: <Widget>[
            if (!controller.isIdle && (progress == null || progress > 0.0)) Container(
              height: _offsetToArmed * controller.value,
              width: double.infinity,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: progress,
              ),
            ),
            Transform.translate(
              offset: Offset(0.0, _offsetToArmed * controller.value),
              child: child,
            ),
          ],
        );
      },
      child: child,
    );
  }
}
