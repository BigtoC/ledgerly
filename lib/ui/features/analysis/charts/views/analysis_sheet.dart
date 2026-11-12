// The presentation the Analysis account sheet and period picker share: a
// bottom sheet below 600 dp, a Dialog at 600 dp and wider (plan D10).

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/analysis_colors.dart';

/// Opens [builder]'s content as a Dialog at 600 dp and wider, else as a
/// modal bottom sheet whose surface carries [surfaceKey]. `showHandle` is
/// true for the bottom sheet only.
Future<void> showAnalysisSheet(
  BuildContext context, {
  required Key surfaceKey,
  required Widget Function(bool showHandle) builder,
}) {
  final colors = AnalysisColors.of(context);
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<void>(
      context: context,
      // The bottom sheet's 32% scrim (Main.dc.html:263), not black54.
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (_) => Dialog(
        backgroundColor: colors.card,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: builder(false),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The sheet paints its own card surface so it can carry the design's
    // shadow; Material elevation cannot draw a CSS box-shadow.
    backgroundColor: const Color(0x00000000),
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (_) => DecoratedBox(
      key: surfaceKey,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        // 0 -2px 16px rgba(0,0,0,.12)
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            offset: Offset(0, -2),
            blurRadius: 16,
          ),
        ],
      ),
      child: builder(true),
    ),
  );
}

/// The bottom sheet's drag handle, keyed [handleKey], or the dialog's top
/// inset when [showHandle] is false.
class AnalysisSheetHandle extends StatelessWidget {
  const AnalysisSheetHandle({
    super.key,
    required this.showHandle,
    required this.handleKey,
  });

  final bool showHandle;
  final Key handleKey;

  @override
  Widget build(BuildContext context) {
    if (!showHandle) {
      // The dialog has no handle; keep its 16 top inset.
      return const SizedBox(height: 16);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Center(
        child: Container(
          key: handleKey,
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: AnalysisColors.of(context).outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
