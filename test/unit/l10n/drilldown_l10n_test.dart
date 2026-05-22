import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Future<AppLocalizations> _resolve(Locale locale) async {
  const delegate = AppLocalizations.delegate;
  expect(delegate.isSupported(locale), isTrue);
  return delegate.load(locale);
}

void main() {
  test('English: drilldown empty / original amount / stale rates', () async {
    final l10n = await _resolve(const Locale('en'));
    expect(l10n.analysisDrilldownEmpty, isNotEmpty);
    expect(l10n.analysisOriginalAmount, isNotEmpty);
    expect(l10n.analysisRatesStale, isNotEmpty);
  });

  test('zh-CN keys resolve to non-empty strings', () async {
    final l10n = await _resolve(const Locale('zh', 'CN'));
    expect(l10n.analysisDrilldownEmpty, isNotEmpty);
    expect(l10n.analysisOriginalAmount, isNotEmpty);
    expect(l10n.analysisRatesStale, isNotEmpty);
  });

  test('zh-TW keys resolve to non-empty strings', () async {
    final l10n = await _resolve(const Locale('zh', 'TW'));
    expect(l10n.analysisDrilldownEmpty, isNotEmpty);
    expect(l10n.analysisOriginalAmount, isNotEmpty);
    expect(l10n.analysisRatesStale, isNotEmpty);
  });

  test('base zh fallback exists (codegen smoke)', () async {
    final l10n = await _resolve(const Locale('zh'));
    expect(l10n.appTitle, isNotEmpty);
  });

  // Suppress unused-import lints.
  Localizations.localeOf;
  GlobalMaterialLocalizations.delegate;
}
