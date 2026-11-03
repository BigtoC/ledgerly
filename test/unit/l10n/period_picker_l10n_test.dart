// Renders every period picker string in each shipped locale so a missing or
// untranslated entry fails here. Values come from the spec's "Strings" table
// (docs/superpowers/specs/2026-11-03-analysis-period-picker-design.md).

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
    expect(l10n.chartsPickDay, 'Choose a day');
    expect(l10n.chartsPickWeek, 'Choose a week');
    expect(l10n.chartsPickMonth, 'Choose a month');
    expect(l10n.chartsPickYear, 'Choose a year');
    expect(l10n.chartsPickerSelected('June 2026'), 'Selected: June 2026');
    expect(
      l10n.chartsPickerOpenLabel('Choose a week', 'Oct 26–Nov 1, 2026'),
      'Choose a week. Selected: Oct 26–Nov 1, 2026',
    );
    expect(l10n.chartsPickerWeekColumn, 'Wk');
    expect(l10n.chartsPickerWeekNumber(43), 'W43');
    expect(
      l10n.chartsPickerWeekRow(43, 'Oct 19–Oct 25, 2026'),
      'Week 43, Oct 19–Oct 25, 2026',
    );
    expect(
      l10n.chartsPickerChooseMonth('October 2026'),
      'Choose month, showing October 2026',
    );
    expect(l10n.chartsPickerChooseYear('2026'), 'Choose year, showing 2026');
    expect(l10n.chartsPickerPreviousMonth, 'Previous month');
    expect(l10n.chartsPickerNextMonth, 'Next month');
    expect(l10n.chartsPickerPreviousYear, 'Previous year');
    expect(l10n.chartsPickerNextYear, 'Next year');
    expect(
      l10n.chartsPickerRecordsStart('Jan 6, 2025'),
      'Records start Jan 6, 2025.',
    );
  });

  test('zh-TW', () async {
    final l10n = await _resolve(const Locale('zh', 'TW'));
    expect(l10n.chartsPickDay, '選擇日期');
    expect(l10n.chartsPickWeek, '選擇週');
    expect(l10n.chartsPickMonth, '選擇月份');
    expect(l10n.chartsPickYear, '選擇年份');
    expect(l10n.chartsPickerSelected('2026年6月'), '已選：2026年6月');
    expect(l10n.chartsPickerOpenLabel('選擇週', 'X'), '選擇週，已選：X');
    expect(l10n.chartsPickerWeekColumn, '週');
    expect(l10n.chartsPickerWeekNumber(43), '43週');
    expect(l10n.chartsPickerWeekRow(43, 'X'), '第 43 週，X');
    expect(l10n.chartsPickerChooseMonth('2026年10月'), '選擇月份，目前為 2026年10月');
    expect(l10n.chartsPickerChooseYear('2026'), '選擇年份，目前為 2026');
    expect(l10n.chartsPickerPreviousMonth, '上個月');
    expect(l10n.chartsPickerNextMonth, '下個月');
    expect(l10n.chartsPickerPreviousYear, '上一年');
    expect(l10n.chartsPickerNextYear, '下一年');
    expect(l10n.chartsPickerRecordsStart('2025年1月6日'), '記錄始於 2025年1月6日。');
  });

  test('zh-CN', () async {
    final l10n = await _resolve(const Locale('zh', 'CN'));
    expect(l10n.chartsPickDay, '选择日期');
    expect(l10n.chartsPickWeek, '选择周');
    expect(l10n.chartsPickMonth, '选择月份');
    expect(l10n.chartsPickYear, '选择年份');
    expect(l10n.chartsPickerSelected('2026年6月'), '已选：2026年6月');
    expect(l10n.chartsPickerOpenLabel('选择周', 'X'), '选择周，已选：X');
    expect(l10n.chartsPickerWeekColumn, '周');
    expect(l10n.chartsPickerWeekNumber(43), '43周');
    expect(l10n.chartsPickerWeekRow(43, 'X'), '第 43 周，X');
    expect(l10n.chartsPickerChooseMonth('2026年10月'), '选择月份，当前为 2026年10月');
    expect(l10n.chartsPickerChooseYear('2026'), '选择年份，当前为 2026');
    expect(l10n.chartsPickerPreviousMonth, '上个月');
    expect(l10n.chartsPickerNextMonth, '下个月');
    expect(l10n.chartsPickerPreviousYear, '上一年');
    expect(l10n.chartsPickerNextYear, '下一年');
    expect(l10n.chartsPickerRecordsStart('2025年1月6日'), '记录始于 2025年1月6日。');
  });
}
