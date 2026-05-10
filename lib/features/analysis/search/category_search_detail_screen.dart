import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import 'analysis_providers.dart';
import 'category_search_detail_controller.dart';
import 'category_search_detail_state.dart';
import 'widgets/transaction_search_row.dart';

class CategorySearchDetailScreen extends ConsumerWidget {
  const CategorySearchDetailScreen({
    super.key,
    required this.categoryId,
    required this.query,
    required this.currencyCode,
  });

  final int categoryId;
  final String query;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    final state = ref.watch(
      categorySearchDetailControllerProvider(
        categoryId: categoryId,
        query: query,
        currencyCode: currencyCode,
      ),
    );

    final categoriesAsync = ref.watch(analysisCategoriesByIdProvider);
    final accountsAsync = ref.watch(analysisAccountsByIdProvider);
    final categoriesById =
        categoriesAsync.valueOrNull ?? const <int, Category>{};
    final accountsById = accountsAsync.valueOrNull ?? const {};

    final category = categoriesById[categoryId];
    final appBarTitle = category == null
        ? ''
        : categoryDisplayName(category, l10n);
    final lookupsReady = categoriesAsync.hasValue && accountsAsync.hasValue;

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.analysisErrorMessage)),
        data: (s) => switch (s) {
          DetailLoading() => const Center(child: CircularProgressIndicator()),
          DetailEmpty() => Center(child: Text(l10n.analysisNoResults)),
          DetailData(
            :final days,
            :final overallSumMinorUnits,
            :final currency,
          ) =>
            !lookupsReady || category == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.analysisSearchTotal,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              MoneyFormatter.formatSigned(
                                amountMinorUnits:
                                    category.type == CategoryType.income
                                    ? overallSumMinorUnits
                                    : -overallSumMinorUnits,
                                currency: currency,
                                locale: locale,
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: category.type == CategoryType.income
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: days.length,
                          itemBuilder: (ctx, dayIdx) {
                            final day = days[dayIdx];
                            final daySigned =
                                category.type == CategoryType.income
                                ? day.daySumMinorUnits
                                : -day.daySumMinorUnits;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat.yMMMd(
                                          locale,
                                        ).format(day.date),
                                        style: theme.textTheme.labelMedium,
                                      ),
                                      Text(
                                        MoneyFormatter.formatSigned(
                                          amountMinorUnits: daySigned,
                                          currency: currency,
                                          locale: locale,
                                        ),
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                for (final tx in day.transactions)
                                  TransactionSearchRow(
                                    transaction: tx,
                                    category: categoriesById[tx.categoryId],
                                    account: accountsById[tx.accountId],
                                    locale: locale,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
        },
      ),
    );
  }
}
