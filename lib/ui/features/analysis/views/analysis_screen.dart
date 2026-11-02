// Analysis tab — memo-based transaction search.
// See `docs/superpowers/specs/2026-05-09-transaction-search-design.md`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../app/providers/default_currency_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/analysis_colors.dart';
import '../charts/view_models/charts_controller.dart';
import '../charts/view_models/charts_net_total_providers.dart';
import '../charts/view_models/charts_providers.dart';
import '../charts/view_models/charts_selection_controller.dart';
import '../charts/view_models/slice_drilldown_controller.dart';
import '../charts/views/charts_section.dart';
import '../search/view_models/analysis_controller.dart';
import '../search/view_models/analysis_providers.dart';
import '../search/view_models/analysis_state.dart';
import '../search/views/category_search_tile.dart';
import 'analysis_search_field.dart';

@Dependencies([
  AnalysisController,
  ChartsSelectionController,
  ChartsController,
  chartsCurrenciesByCode,
  initialDefaultCurrency,
  SliceDrilldownController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsFxStatus,
  chartsNetTotal,
])
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

  /// Whether the app-bar search field is open. The account filter button
  /// (spec § Account filter) sits left of the search field and hides while
  /// this is true.
  bool _searchExpanded = false;

  void _openSearch() {
    // The input autofocuses when it mounts.
    setState(() => _searchExpanded = true);
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    ref.read(analysisControllerProvider.notifier).updateQuery('');
    setState(() => _searchExpanded = false);
  }

  void _onChanged(String value) {
    // Skip dispatch while a CJK IME is mid-composition. Pinyin/zhuyin fires
    // `onChanged` for every partial composition keypress; without this guard,
    // each one would cancel the prior subscription and restart the 300ms
    // timer, producing N rapid loading flashes before the user has committed
    // a single character.
    if (!_searchController.value.composing.isValid) {
      ref.read(analysisControllerProvider.notifier).updateQuery(value);
    }
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
        // No active search query: place the charts under the search bar.
        // The placeholder lives above the chart as a subtle "search hint";
        // charts render the full breakdown.
        AnalysisIdle() => const SingleChildScrollView(
          child: Column(children: [ChartsSection()]),
        ),
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

    final colors = AnalysisColors.of(context);
    final titleScaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.5);
    return Scaffold(
      backgroundColor: colors.bg,
      // Pinned (plan D1) so the search field stays reachable while its
      // results replace the charts.
      appBar: AppBar(
        backgroundColor: colors.bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        // The row is fixed at 64, so its text clamps at 1.5× (plan D1). Read
        // from the screen's context: AppBar's own M3 title clamp is 1.34×.
        // The Builder copies the title's own MediaQuery so AppBar's SafeArea
        // padding removal is kept.
        title: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: titleScaler),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                spacing: 12,
                children: [
                  Text(
                    l10n.analysisTitle,
                    style: analysisText(
                      size: 24,
                      lineHeight: 32,
                      weight: FontWeight.w500,
                      color: colors.fg,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 4,
                        children: [
                          // The account filter button goes here, before the
                          // search field, while !_searchExpanded.
                          AnalysisSearchField(
                            expanded: _searchExpanded,
                            expandedWidth: constraints.maxWidth,
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onOpen: _openSearch,
                            onClose: _closeSearch,
                            onChanged: _onChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Semantics(liveRegion: true, container: true, child: body),
    );
  }
}
