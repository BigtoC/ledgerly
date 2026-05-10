// Analysis tab — memo-based transaction search.
// See `docs/superpowers/specs/2026-05-09-transaction-search-design.md`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'search/analysis_controller.dart';
import 'search/analysis_state.dart';
import 'search/widgets/analysis_search_placeholder.dart';
import 'search/widgets/category_search_tile.dart';

/// Material 3 SearchBar default height (56dp).
const double _kSearchBarBaseHeight = 56;
const double _kSearchBarVerticalPadding = 8;

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onClear() {
    _searchController.clear();
    _searchFocus.unfocus();
    ref.read(analysisControllerProvider.notifier).updateQuery('');
    setState(() {});
  }

  void _onChanged(String value) {
    // Skip dispatch while a CJK IME is mid-composition. Pinyin/zhuyin fires
    // `onChanged` for every partial composition keypress; without this guard,
    // each one would cancel the prior subscription and restart the 300ms
    // timer, producing N rapid loading flashes before the user has committed
    // a single character.
    if (_searchController.value.composing.isValid) {
      setState(() {});
      return;
    }
    ref.read(analysisControllerProvider.notifier).updateQuery(value);
    setState(() {});
  }

  /// Search-bar row height clamped at 1.5× text-scale so accessibility text
  /// sizes don't clip the input. Matches CLAUDE.md "fixed-height widgets
  /// clamp at 1.5× or reflow".
  double _searchBarRowHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final scaled = scaler
        .clamp(maxScaleFactor: 1.5)
        .scale(_kSearchBarBaseHeight);
    return scaled + _kSearchBarVerticalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final state = ref.watch(analysisControllerProvider);

    final body = state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.analysisErrorMessage)),
      data: (s) => switch (s) {
        AnalysisIdle() => const AnalysisSearchPlaceholder(),
        AnalysisLoading(:final previous, :final query) =>
          previous == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    IgnorePointer(
                      child: ListView.builder(
                        itemCount: previous.length,
                        itemBuilder: (_, i) => CategorySearchTile(
                          result: previous[i],
                          query: query,
                          locale: locale,
                        ),
                      ),
                    ),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
        AnalysisResults(:final categories, :final query) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (_, i) => CategorySearchTile(
            result: categories[i],
            query: query,
            locale: locale,
          ),
        ),
        AnalysisEmpty() => Center(child: Text(l10n.analysisNoResults)),
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchBarRowHeight(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: _kSearchBarVerticalPadding,
            ),
            child: SearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              hintText: l10n.analysisSearchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _onClear,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                  ),
              ],
              onChanged: _onChanged,
            ),
          ),
        ),
      ),
      body: Semantics(liveRegion: true, container: true, child: body),
    );
  }
}
