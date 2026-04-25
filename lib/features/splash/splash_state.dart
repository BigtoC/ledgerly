// Splash state machine (plan §4).
//
// Freezed sealed union with `loading | data | error` variants. No
// `needsStartDate` variant — per plan §4 the launch-time prompt is a
// specialized widget render path driven by `splashStartDateProvider`, not
// a separate state machine branch.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_state.freezed.dart';

@freezed
sealed class SplashState with _$SplashState {
  /// Pre-first-emission from the underlying preference streams.
  const factory SplashState.loading() = SplashLoading;

  /// Fully-resolved day counter ready to render.
  ///
  /// [formattedDisplayText] has `{date}` and `{days}` template tokens
  /// already substituted per plan §5 ("Substitution happens in the
  /// controller, not the widget").
  const factory SplashState.data({
    required DateTime startDate,
    required int dayCount,
    required String formattedStartDate,
    required String formattedDisplayText,
    required String buttonLabel,
  }) = SplashData;

  /// Upstream stream failure — e.g. `PreferenceDecodeException` from a
  /// corrupted `user_preferences` cell.
  const factory SplashState.error(Object error, StackTrace stack) = SplashError;
}
