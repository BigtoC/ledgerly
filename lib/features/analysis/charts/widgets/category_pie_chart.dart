import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../charts_state.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.slices,
    required this.currenciesByCode,
    required this.locale,
    this.grandTotalMinorUnits,
    this.displayCurrencyCode,
  });

  final List<ChartSlice> slices;
  final Map<String, Currency> currenciesByCode;
  final String locale;
  final int? grandTotalMinorUnits;
  final String? displayCurrencyCode;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const SizedBox(height: 200);
    }
    final showLabels = slices.first.fraction != null;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: _semanticsLabel(l10n),
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.4,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(enabled: false),
            sections: [
              for (final s in slices)
                PieChartSectionData(
                  value: s.totalMinorUnits.abs().toDouble(),
                  color: colorForIndex(s.colorIndex),
                  title: showLabels ? '${(s.fraction! * 100).round()}%' : '',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(AppLocalizations l10n) {
    final parts = <String>[l10n.chartsPieChart];
    for (final s in slices) {
      final currency =
          currenciesByCode[s.currencyCode] ??
          Currency(code: s.currencyCode, decimals: 2);
      final amount = MoneyFormatter.format(
        amountMinorUnits: s.totalMinorUnits,
        currency: currency,
        locale: locale,
      );
      if (s.fraction != null) {
        parts.add('${s.label} ${(s.fraction! * 100).round()}%, $amount');
      } else {
        parts.add('${s.label}: $amount');
      }
    }
    if (grandTotalMinorUnits != null && displayCurrencyCode != null) {
      final currency =
          currenciesByCode[displayCurrencyCode!] ??
          Currency(code: displayCurrencyCode!, decimals: 2);
      final total = MoneyFormatter.format(
        amountMinorUnits: grandTotalMinorUnits!,
        currency: currency,
        locale: locale,
      );
      parts.add('${l10n.chartsTotal} $total');
    }
    return parts.join('. ');
  }
}
