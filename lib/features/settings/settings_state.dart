// Settings slice state (plan §4).
//
// Freezed sealed union. The Settings tab projects the flat key/value
// shape of `user_preferences` into a single immutable `Data` variant,
// composed by `SettingsController` from multiple `UserPreferencesRepository`
// streams. Widgets read this shape directly; commands write through the
// controller, which in turn writes through the repository.
//
// No top-level `empty` variant: the bootstrap sequence guarantees
// `user_preferences` is populated (first-run seed) before the Settings
// tab can be rendered.

import 'package:flutter/material.dart' show ThemeMode, Locale;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  /// Pre-first-emission from the underlying preference streams.
  const factory SettingsState.loading() = SettingsLoading;

  /// Fully-resolved current preference values.
  ///
  /// `locale == null` means "follow system locale" (PRD 887).
  /// `defaultAccountId == null` means no default has been picked yet
  /// (first run until the user picks one).
  /// `splashDisplayText == null` / `splashButtonLabel == null` means
  /// "fall back to the localized default template" — the widget layer
  /// resolves to `splashSinceDate` / `splashEnter` at render time.
  const factory SettingsState.data({
    required ThemeMode themeMode,
    required Locale? locale,
    required String defaultCurrency,
    required int? defaultAccountId,
    required bool splashEnabled,
    required DateTime? splashStartDate,
    required String? splashDisplayText,
    required String? splashButtonLabel,
  }) = SettingsData;

  /// Upstream stream failure — e.g. `PreferenceDecodeException` from a
  /// corrupted `user_preferences` cell.
  const factory SettingsState.error(Object error, StackTrace stack) =
      SettingsError;
}
