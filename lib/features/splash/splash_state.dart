// Splash state machine (plan §4).
//
// Freezed sealed union with `loading | data | error` variants. No
// `needsStartDate` variant — per plan §4 the launch-time prompt is a
// specialized widget render path driven by `splashStartDateProvider`, not
// a separate state machine branch.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/date_helpers.dart';

part 'splash_state.freezed.dart';

@freezed
sealed class SplashState with _$SplashState {
  /// Pre-first-emission from the underlying preference streams.
  const factory SplashState.loading() = SplashLoading;

  /// Fully-resolved day counter ready to render.
  ///
  /// [displayTextSegments] is the resolved splash display template split
  /// into runs of plain text and date text. The widget renders the date
  /// runs (`isDate: true`) with the rainbow gradient and the rest as
  /// plain white text. Substitution and the auto-prepend rule for
  /// missing `{date}` happen in the controller, never in `build()`.
  const factory SplashState.data({
    required DateTime startDate,
    required int dayCount,
    required List<SplashTextSegment> displayTextSegments,
    required String buttonLabel,
  }) = SplashData;

  /// Upstream stream failure — e.g. `PreferenceDecodeException` from a
  /// corrupted `user_preferences` cell.
  const factory SplashState.error(Object error, StackTrace stack) = SplashError;
}
