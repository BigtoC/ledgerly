// M4 §7.2 — `resolveChineseLocale` pure function unit tests (PRD 894–900).
//
// 8 cases covering Traditional Chinese, Simplified Chinese, bare `zh`, and
// non-Chinese passthrough.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/locale_provider.dart';

void main() {
  // Supported locales mirror `AppLocalizations.supportedLocales`.
  const supported = [
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];
  const device = Locale('en', 'US');

  group('resolveChineseLocale', () {
    test('zh_TW → Traditional Chinese (zh_TW)', () {
      expect(
        resolveChineseLocale(const Locale('zh', 'TW'), supported, device),
        const Locale('zh', 'TW'),
      );
    });

    test('zh_HK → Traditional Chinese (zh_TW)', () {
      expect(
        resolveChineseLocale(const Locale('zh', 'HK'), supported, device),
        const Locale('zh', 'TW'),
      );
    });

    test('zh_MO → Traditional Chinese (zh_TW)', () {
      expect(
        resolveChineseLocale(const Locale('zh', 'MO'), supported, device),
        const Locale('zh', 'TW'),
      );
    });

    test('zh_CN → Simplified Chinese (zh_CN)', () {
      expect(
        resolveChineseLocale(const Locale('zh', 'CN'), supported, device),
        const Locale('zh', 'CN'),
      );
    });

    test('zh_SG → Simplified Chinese (zh_CN)', () {
      expect(
        resolveChineseLocale(const Locale('zh', 'SG'), supported, device),
        const Locale('zh', 'CN'),
      );
    });

    test('zh bare (no script/region) → English fallback (PRD 898)', () {
      expect(
        resolveChineseLocale(const Locale('zh'), supported, device),
        const Locale('en'),
      );
    });

    test('zh_Hant* → Traditional Chinese (zh_TW)', () {
      expect(
        resolveChineseLocale(
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'HK',
          ),
          supported,
          device,
        ),
        const Locale('zh', 'TW'),
      );
    });

    test('en_US non-Chinese passthrough → en (supported)', () {
      expect(
        resolveChineseLocale(const Locale('en', 'US'), supported, device),
        const Locale('en', 'US'),
      );
    });

    test(
      'preferred == null with non-zh device → null (let Flutter default)',
      () {
        expect(
          resolveChineseLocale(null, supported, const Locale('en', 'US')),
          isNull,
        );
      },
    );

    test('preferred == null with zh_TW device → Traditional Chinese', () {
      expect(
        resolveChineseLocale(null, supported, const Locale('zh', 'TW')),
        const Locale('zh', 'TW'),
      );
    });

    test(
      'unsupported preferred → null (let Flutter default to first supported)',
      () {
        expect(
          resolveChineseLocale(const Locale('ja', 'JP'), supported, device),
          isNull,
        );
      },
    );
  });
}
