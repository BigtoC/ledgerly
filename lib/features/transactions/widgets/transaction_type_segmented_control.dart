// `TransactionTypeSegmentedControl` — Wave 2 §4.1 / §7.
//
// Two-segment Material `SegmentedButton` for expense / income. Pre-
// category-selection it edits `pendingType` directly; post-selection
// it surfaces a confirm-then-clear dialog before swapping types. The
// dialog logic lives on the screen so this widget stays a value-in /
// callback-out segment selector.

import 'package:flutter/material.dart';

import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';

class TransactionTypeSegmentedControl extends StatelessWidget {
  const TransactionTypeSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CategoryType value;
  final ValueChanged<CategoryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<CategoryType>(
      segments: [
        ButtonSegment(
          value: CategoryType.expense,
          label: Text(l10n.transactionTypeExpense),
          icon: const Icon(Icons.south_west),
        ),
        ButtonSegment(
          value: CategoryType.income,
          label: Text(l10n.transactionTypeIncome),
          icon: const Icon(Icons.north_east),
        ),
      ],
      selected: {value},
      onSelectionChanged: (next) {
        if (next.isEmpty) return;
        onChanged(next.first);
      },
    );
  }
}
