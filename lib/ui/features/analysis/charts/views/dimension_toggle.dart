import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../view_models/charts_state.dart';

/// Breakdown-card dimension chips (Category · Account · Currency).
class DimensionChips extends StatelessWidget {
  const DimensionChips({
    super.key,
    required this.dimension,
    required this.onChanged,
  });

  final ChartDimension dimension;
  final ValueChanged<ChartDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in [
          (ChartDimension.category, l10n.chartsDimensionCategory),
          (ChartDimension.account, l10n.chartsDimensionAccount),
          (ChartDimension.currency, l10n.chartsDimensionCurrency),
        ])
          _DimensionChip(
            label: label,
            selected: value == dimension,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _DimensionChip extends StatelessWidget {
  const _DimensionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        // 44-high hit target around a 32-high pill; both are minimums so
        // the chip grows at large text scales. The pill's InkWell takes taps,
        // focus and the ripple; presses on the margin are sent to it too.
        child: _RedirectToCenter(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              // The border changes instantly; only the fill and the text
              // colour transition, as in the design.
              child: Container(
                foregroundDecoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? colors.onBg : colors.outline,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedContainer(
                  duration: AnalysisMotion.standardDuration,
                  curve: AnalysisMotion.standardCurve,
                  constraints: const BoxConstraints(minHeight: 32),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.onBg
                        : colors.onBg.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // The ink paints on this transparent Material, above the
                  // fill.
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onTap,
                      child: Padding(
                        // 14 padding inside the 1 px border.
                        padding: const EdgeInsets.fromLTRB(15, 1, 15, 1),
                        child: Align(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: AnimatedDefaultTextStyle(
                            duration: AnalysisMotion.standardDuration,
                            curve: AnalysisMotion.standardCurve,
                            style: analysisText(
                              size: 14,
                              lineHeight: 20,
                              weight: FontWeight.w500,
                              color: selected ? colors.onFg : colors.fg2,
                            ),
                            child: Text(label),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sends a press that lands on the child's margin (inside this box but
/// missing every hit target) to the box's centre, as Material buttons do
/// with their padded tap target, so the centred pill's InkWell gets it.
class _RedirectToCenter extends SingleChildRenderObjectWidget {
  const _RedirectToCenter({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRedirectToCenter();
}

class _RenderRedirectToCenter extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (super.hitTest(result, position: position)) return true;
    final center = size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, _) => child!.hitTest(result, position: center),
    );
  }
}
