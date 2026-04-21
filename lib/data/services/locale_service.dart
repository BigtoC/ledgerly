import 'dart:io' show Platform;

/// Thin wrapper around the device locale. M1 stub.
///
/// Consumed by the M3 first-run seed / M4 bootstrap path to expose the
/// raw device locale string. The locale-to-currency lookup policy lives
/// alongside seeding once the seeded currency set is available.
/// Swapped for a fake in tests via Riverpod override (M4 smoke-test
/// template, §5.5 of implementation-plan.md).
class LocaleService {
  const LocaleService();

  /// BCP 47-ish locale string as reported by the platform
  /// (e.g. `en_US`, `zh_TW`, `ja_JP`). Returns `'en_US'` if `Platform`
  /// lookup throws (test environments, headless Linux without LANG set).
  String get deviceLocale {
    try {
      return Platform.localeName;
    } catch (_) {
      return 'en_US';
    }
  }
}
