import 'package:flutter/material.dart';

/// Shows [child] in a modal bottom sheet [heightFactor] of the screen tall
/// below 600dp, and in a `Dialog` capped at [maxWidth] × [maxHeight] from
/// 600dp, so a picker opened from a form dialog does not stack an
/// unbounded phone sheet inside it.
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required Widget child,
  required double heightFactor,
  double maxWidth = 480,
  double maxHeight = 560,
}) {
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: child,
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) =>
        FractionallySizedBox(heightFactor: heightFactor, child: child),
  );
}
