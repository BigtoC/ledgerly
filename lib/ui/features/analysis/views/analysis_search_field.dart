// Collapsible memo search in the Analysis app bar. Visual values from
// docs/design/analysis-redesign/Main.dc.html (markup lines 28-48,
// searchBoxStyle in renderVals()).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/analysis_colors.dart';

/// Inner width the expanded row needs before the input gets any space:
/// 14 inset + 20 icon + 10 gap + 10 gap + 44 close button.
const double _kExpandedContentMinWidth = 98;

/// A 48 dp search box whose width grows from 48 to [expandedWidth] while
/// [expanded]. The parent keeps its right edge fixed, so it grows leftwards.
class AnalysisSearchField extends StatelessWidget {
  const AnalysisSearchField({
    super.key,
    required this.expanded,
    required this.expandedWidth,
    required this.controller,
    required this.focusNode,
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
  });

  final bool expanded;
  final double expandedWidth;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    // Animate only the open/close progress and scale the live width by it,
    // so a narrower window (rotation, resize) applies at once.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: expanded ? 1 : 0),
      duration: AnalysisMotion.searchExpandDuration,
      curve: AnalysisMotion.emphasizedCurve,
      builder: (context, progress, child) => SizedBox(
        width: 48 + (expandedWidth - 48) * progress,
        height: 48,
        child: child,
      ),
      child: AnimatedContainer(
        duration: AnalysisMotion.standardDuration,
        curve: AnalysisMotion.standardCurve,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: expanded ? colors.card : const Color(0x00000000),
          border: Border.all(
            color: expanded ? colors.line : const Color(0x00000000),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: expanded
            ? LayoutBuilder(
                // While the box is still narrow, lay the row out at its
                // minimum width from the start edge and clip the rest.
                builder: (context, constraints) {
                  final width = math.max(
                    constraints.maxWidth,
                    _kExpandedContentMinWidth,
                  );
                  return OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    minWidth: width,
                    maxWidth: width,
                    child: _ExpandedContent(
                      controller: controller,
                      focusNode: focusNode,
                      onClose: onClose,
                      onChanged: onChanged,
                    ),
                  );
                },
              )
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: _OpenButton(onOpen: onOpen),
              ),
      ),
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    return Semantics(
      container: true,
      label: l10n.analysisSearchOpen,
      button: true,
      expanded: false,
      onTap: onOpen,
      excludeSemantics: true,
      child: IconButton(
        tooltip: l10n.analysisSearchOpen,
        onPressed: onOpen,
        icon: const Icon(Icons.search),
        iconSize: 24,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(46),
          minimumSize: const Size.square(46),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          foregroundColor: colors.fg,
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.controller,
    required this.focusNode,
    required this.onClose,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AnalysisColors.of(context);
    return Row(
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 14),
          child: Icon(Icons.search, size: 20, color: colors.fg2),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: focusNode.requestFocus,
            child: SizedBox(
              height: double.infinity,
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  // The design's hint is a separate span hidden from
                  // assistive tech; the input carries the semantics label.
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? Positioned.directional(
                            textDirection: Directionality.of(context),
                            start: 0,
                            end: 0,
                            child: ExcludeSemantics(
                              child: Text(
                                l10n.analysisSearchHint,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: analysisText(
                                  size: 15,
                                  lineHeight: 20,
                                  color: colors.fg2,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Semantics(
                    label: l10n.analysisSearchPrompt,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      onChanged: onChanged,
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 0,
                        color: colors.fg,
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.analysisSearchClose,
          onPressed: onClose,
          icon: const Icon(Icons.close),
          iconSize: 20,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(44),
            minimumSize: const Size.square(44),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            foregroundColor: colors.fg2,
          ),
        ),
      ],
    );
  }
}
