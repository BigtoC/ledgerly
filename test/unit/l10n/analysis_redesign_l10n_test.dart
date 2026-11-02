// Renders a sample of the Analysis redesign strings in every shipped
// locale so a missing or untranslated entry fails here. Values come from
// the spec's "Strings" table and plan § 4 D9
// (docs/superpowers/specs/2026-11-02-analysis-redesign-design.md).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Future<AppLocalizations> _resolve(Locale locale) async {
  const delegate = AppLocalizations.delegate;
  expect(delegate.isSupported(locale), isTrue);
  return delegate.load(locale);
}

void main() {
  test('English', () async {
    final l10n = await _resolve(const Locale('en'));
    expect(l10n.chartsNetThisMonth, 'Net this month');
    expect(l10n.chartsPeriodAll, 'All');
    expect(l10n.analysisSearchHint, 'Search memos');
    expect(l10n.chartsCategoryCount(1), '1 category');
    expect(l10n.chartsCategoryCount(3), '3 categories');
    expect(l10n.chartsShareOfIncome('12.5%'), '12.5% of income');
    expect(
      l10n.chartsEmptyTitleAccountExpense('Cash'),
      'No expense on Cash in this period',
    );
    expect(l10n.chartsAvgPerDay(r'HK$10.00'), r'Avg HK$10.00 / day');
  });

  test('zh-TW', () async {
    final l10n = await _resolve(const Locale('zh', 'TW'));
    expect(l10n.chartsNetThisMonth, '本月淨額');
    expect(l10n.chartsPeriodAll, '全部');
    expect(l10n.analysisSearchHint, '搜尋備註');
    expect(l10n.chartsCategoryCount(1), '1 個類別');
    expect(l10n.chartsCategoryCount(3), '3 個類別');
    expect(l10n.chartsShareOfIncome('12.5%'), '佔收入 12.5%');
    expect(l10n.chartsEmptyTitleAccountExpense('Cash'), 'Cash 此期間沒有支出');
    expect(l10n.chartsAvgPerDay(r'HK$10.00'), r'平均每日 HK$10.00');
  });

  test('zh-CN', () async {
    final l10n = await _resolve(const Locale('zh', 'CN'));
    expect(l10n.chartsNetThisMonth, '本月净额');
    expect(l10n.chartsPeriodAll, '全部');
    expect(l10n.analysisSearchHint, '搜索备注');
    expect(l10n.chartsCategoryCount(1), '1 个类别');
    expect(l10n.chartsCategoryCount(3), '3 个类别');
    expect(l10n.chartsShareOfIncome('12.5%'), '占收入 12.5%');
    expect(l10n.chartsEmptyTitleAccountExpense('Cash'), 'Cash 此期间没有支出');
    expect(l10n.chartsAvgPerDay(r'HK$10.00'), r'平均每日 HK$10.00');
  });
}
