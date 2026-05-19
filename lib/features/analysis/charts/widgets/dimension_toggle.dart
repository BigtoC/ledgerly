import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class DimensionToggle extends StatelessWidget {
  const DimensionToggle({
    super.key,
    required this.dimension,
    required this.onChanged,
  });

  final ChartDimension dimension;
  final ValueChanged<ChartDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<ChartDimension>(
      segments: [
        ButtonSegment(
          value: ChartDimension.category,
          label: Text(l10n.chartsDimensionCategory),
        ),
        ButtonSegment(
          value: ChartDimension.account,
          label: Text(l10n.chartsDimensionAccount),
        ),
        ButtonSegment(
          value: ChartDimension.currency,
          label: Text(l10n.chartsDimensionCurrency),
        ),
      ],
      selected: {dimension},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
