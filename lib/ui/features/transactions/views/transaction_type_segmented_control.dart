// `TransactionTypeSegmentedControl` — Wave 2 §4.1 / §7.
//
// Two-segment Material `SegmentedButton` for expense / income, kept as
// a value-in / callback-out segment selector.

import 'package:material_ui/material_ui.dart';

import '../../../../domain/models/category.dart';
import '../../../../l10n/app_localizations.dart';

class const TransactionTypeSegmentedControl({
  super.key,
  required final CategoryType value,
  required final ValueChanged<CategoryType> onChanged,
}) extends StatelessWidget {
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
      onSelectionChanged: (next) => onChanged(next.first),
    );
  }
}
