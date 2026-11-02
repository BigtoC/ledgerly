// App-bar account filter pill, left of the search control. Visual values
// from docs/design/analysis-redesign/Main.dc.html (lines 20-27,
// accPillStyle in renderVals()).

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/analysis_colors.dart';
import 'dimension_toggle.dart' show RedirectToCenter;

/// A 44-high hit target holding a 32-high pill: the filtered account's
/// name (or "All accounts") and a chevron. Opens the account sheet through
/// [onPressed].
class AccountFilterButton extends StatelessWidget {
  const AccountFilterButton({
    super.key,
    required this.accountName,
    required this.onPressed,
  });

  /// The filtered account's name; null when no account filter is set.
  final String? accountName;
  final VoidCallback onPressed;

  /// Narrowest the button can draw without overflowing: the 2 px button
  /// padding each side, the 1 px border, 12 + 8 pill padding, the 4 gap and
  /// the 16 icon, with no room left for the label.
  static const double _kMinWidth = 2 + 1 + 12 + 4 + 16 + 8 + 1 + 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    final active = accountName != null;
    final label = accountName ?? l10n.chartsAllAccounts;
    final ink = active ? colors.fg : colors.fg2;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The app bar's right-hand area can be narrower than the button at
        // large text scales or while the search field collapses; hide it
        // there rather than overflow the fixed 64 row.
        if (constraints.maxWidth < _kMinWidth) return const SizedBox.shrink();
        return Semantics(
          container: true,
          button: true,
          label: l10n.chartsAccountFilterLabel(label),
          // Flutter has no "opens a dialog" flag; the tap hint names the
          // sheet it opens instead.
          onTapHint: l10n.chartsFilterByAccount,
          onTap: onPressed,
          excludeSemantics: true,
          // A press on the hit target's margin goes to the pill's InkWell,
          // which takes taps, focus and the ripple (D16).
          child: RedirectToCenter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    // The border changes instantly; only the fill
                    // transitions, as in the design.
                    child: Container(
                      foregroundDecoration: BoxDecoration(
                        border: Border.all(
                          color: active ? colors.fg2 : colors.outline,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AnimatedContainer(
                        key: const ValueKey('accountFilterPill'),
                        duration: AnalysisMotion.standardDuration,
                        curve: AnalysisMotion.standardCurve,
                        constraints: const BoxConstraints(minHeight: 32),
                        decoration: BoxDecoration(
                          color: active
                              ? colors.sel
                              : colors.sel.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        // Inside the 1 px border, so the ink stays within
                        // the pill.
                        padding: const EdgeInsets.all(1),
                        // The ink paints on this transparent Material,
                        // above the fill.
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: onPressed,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 30),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: analysisText(
                                          size: 13,
                                          lineHeight: 18,
                                          weight: FontWeight.w500,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.expand_more,
                                      size: 16,
                                      color: ink,
                                    ),
                                  ],
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
          ),
        );
      },
    );
  }
}
