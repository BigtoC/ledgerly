import 'package:flutter/material.dart';

import '../../../../data/models/category.dart';
import '../../../../l10n/app_localizations.dart';

class TypeToggle extends StatelessWidget {
  const TypeToggle({super.key, required this.type, required this.onChanged});

  final CategoryType type;
  final ValueChanged<CategoryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<CategoryType>(
      segments: [
        ButtonSegment(
          value: CategoryType.expense,
          label: Text(l10n.chartsTypeExpense),
        ),
        ButtonSegment(
          value: CategoryType.income,
          label: Text(l10n.chartsTypeIncome),
        ),
      ],
      selected: {type},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
