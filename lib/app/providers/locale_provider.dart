import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<Locale?> _userLocalePreferenceStream(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchLocale();

@riverpod
Locale? userLocalePreference(Ref ref) =>
    ref.watch(_userLocalePreferenceStreamProvider).value;

/// Pure function implementing PRD 894–900 Chinese locale resolution.
///
/// - `zh_TW`, `zh_HK`, `zh_MO`, `zh_Hant*` → Traditional Chinese (`zh_TW`).
/// - `zh_CN`, `zh_SG`, `zh_Hans*` → Simplified Chinese (`zh_CN`).
/// - `zh` bare (no script/region) → English fallback (`en`), per PRD 898.
/// - Non-Chinese: returns `preferred` if supported, else `null`.
/// - `preferred == null`: falls through to `deviceLocale` for zh resolution,
///   returns `null` for non-Chinese (let Flutter pick the default locale).
Locale? resolveChineseLocale(
  Locale? preferred,
  Iterable<Locale> supported,
  Locale deviceLocale,
) {
  final effective = preferred ?? deviceLocale;

  if (effective.languageCode != 'zh') {
    if (preferred == null) return null;
    final hasMatch = supported.any(
      (s) =>
          s.languageCode == preferred.languageCode &&
          (s.countryCode == null || s.countryCode == preferred.countryCode),
    );
    return hasMatch ? preferred : null;
  }

  final country = effective.countryCode;
  final script = effective.scriptCode;

  if (country == 'TW' ||
      country == 'HK' ||
      country == 'MO' ||
      script == 'Hant') {
    return const Locale('zh', 'TW');
  }

  if (country == 'CN' || country == 'SG' || script == 'Hans') {
    return const Locale('zh', 'CN');
  }

  return const Locale('en');
}
