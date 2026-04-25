// SplashController (plan §3.1, §5).
//
// Consumes `splash_start_date`, `splash_display_text`, and
// `splash_button_label` from `UserPreferencesRepository` and emits
// `SplashState.data(...)` with the resolved day count and the pre-formatted
// display text. Template substitution (`{date}` / `{days}`) happens here,
// **not** in `build()` of the widget, per PRD → Controller Contract.
//
// Day-count math delegates to `DateHelpers.daysSince` — the controller
// simply carries that helper's value through, including negative values for
// future start dates (no clamp).
//
// Command surface per plan §3.1 is minimal: `setStartDate(DateTime)` for
// the PRD cold-start date-picker path. The Enter button is pure navigation
// and stays on the widget.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/locale_provider.dart';
import '../../app/providers/repository_providers.dart';
import '../../app/providers/splash_redirect_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/repositories/user_preferences_repository.dart';
import 'splash_state.dart';

part 'splash_controller.g.dart';

/// Injectable `DateTime.now()` for deterministic day-count tests.
/// Production reads the real clock; tests override via
/// `splashClockProvider.overrideWithValue(() => fixedNow)`.
@Riverpod(keepAlive: true)
DateTime Function() splashClock(Ref ref) => DateTime.now;

@riverpod
class SplashController extends _$SplashController {
  @override
  Stream<SplashState> build() async* {
    final repo = ref.watch(userPreferencesRepositoryProvider);
    final clock = ref.watch(splashClockProvider);
    final locale = ref.watch(userLocalePreferenceProvider);
    final localeTag = _localeTag(locale?.toLanguageTag());
    // First-frame hydrated start date so the launch transition does not
    // flicker loading → data while the repo stream warms up. Mirrors the
    // widget's own `stream.valueOrNull ?? snapshot.splashStartDate` read.
    final snapshotStartDate = ref
        .read(splashGateSnapshotProvider)
        .splashStartDate;

    yield* _combine3(
      repo.watchSplashStartDate(),
      repo.watchSplashDisplayText(),
      repo.watchSplashButtonLabel(),
    ).map((values) {
      final startDate = values.$1 ?? snapshotStartDate;
      final rawText = values.$2;
      final buttonLabel = values.$3;

      if (startDate == null) {
        return const SplashState.loading();
      }
      final now = clock();
      final dayCount = DateHelpers.daysSince(startDate: startDate, now: now);
      final template = _resolveTemplate(rawText);
      final formatted = DateHelpers.applySplashTemplate(
        template: template,
        startDate: startDate,
        now: now,
        locale: localeTag,
      );
      final formattedStartDate = DateHelpers.formatDisplayDate(
        startDate,
        localeTag,
      );
      return SplashState.data(
        startDate: startDate,
        dayCount: dayCount,
        formattedStartDate: formattedStartDate,
        formattedDisplayText: formatted,
        buttonLabel: buttonLabel,
      );
    });
  }

  /// Writes `splash_start_date` via the repository. Called from the
  /// launch-time start-date prompt; Settings owns ongoing edits per
  /// wave-0 §2.3.
  Future<void> setStartDate(DateTime date) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setSplashStartDate(date);
  }

  /// Empty / whitespace-only custom text falls back to the seed default
  /// (`Since {date}`), matching the PRD contract that the default
  /// template is always visible until the user writes something.
  static String _resolveTemplate(String raw) {
    if (raw.trim().isEmpty) return kDefaultSplashDisplayText;
    return raw;
  }

  /// Normalizes locale tags for `intl`. `intl` wants underscored tags
  /// (`zh_TW`) whereas Flutter emits BCP-47 (`zh-TW`). Falls back to
  /// `en_US` when the preferred locale is unset.
  static String _localeTag(String? tag) {
    if (tag == null || tag.isEmpty) return 'en_US';
    return tag.replaceAll('-', '_');
  }
}

/// Combines three broadcast streams into a stream of 3-tuples that emits
/// whenever any source emits (after each has produced at least one value).
Stream<(A, B, C)> _combine3<A, B, C>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
) async* {
  final controller = StreamController<(A, B, C)>();

  late A latestA;
  late B latestB;
  late C latestC;
  var seenA = false;
  var seenB = false;
  var seenC = false;

  void maybeEmit() {
    if (seenA && seenB && seenC) {
      controller.add((latestA, latestB, latestC));
    }
  }

  final subA = a.listen((v) {
    latestA = v;
    seenA = true;
    maybeEmit();
  }, onError: controller.addError);
  final subB = b.listen((v) {
    latestB = v;
    seenB = true;
    maybeEmit();
  }, onError: controller.addError);
  final subC = c.listen((v) {
    latestC = v;
    seenC = true;
    maybeEmit();
  }, onError: controller.addError);

  try {
    yield* controller.stream;
  } finally {
    await subA.cancel();
    await subB.cancel();
    await subC.cancel();
    await controller.close();
  }
}
