// Settings slice controller (plan §3.1, §3.3).
//
// The controller composes eight preference streams from
// `UserPreferencesRepository` into a single [SettingsState] and exposes
// typed command methods for every preference mutation. Widgets never call
// the repository directly (PRD → Controller Contract); each command
// writes via `UserPreferencesRepository.set*` and the repo stream
// re-emits to drive the UI.
//
// The splash_display_text and splash_button_label preferences are stored
// as non-nullable `String` at the repository layer (with default values
// like `kDefaultSplashDisplayText`). The controller normalizes those
// fallback defaults back to `null` in the projected state so the
// settings UI can render the localized default as a placeholder without
// echoing the seed literal.

import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode, Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/repositories/user_preferences_repository.dart';
import 'settings_state.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  @override
  Stream<SettingsState> build() {
    final repo = ref.watch(userPreferencesRepositoryProvider);
    final composer = _SettingsComposer(repo);
    ref.onDispose(composer.dispose);
    return composer.stream;
  }

  // ---------- Commands ----------

  Future<void> setThemeMode(ThemeMode mode) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setThemeMode(mode);
  }

  Future<void> setLocale(Locale? locale) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setLocale(locale);
  }

  Future<void> setDefaultCurrency(String code) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setDefaultCurrency(code);
  }

  Future<void> setDefaultAccountId(int? id) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setDefaultAccountId(id);
  }

  Future<void> setSplashEnabled(bool enabled) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setSplashEnabled(enabled);
  }

  Future<void> setSplashStartDate(DateTime? date) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setSplashStartDate(date);
  }

  /// Writes the custom splash display-text template. Empty / whitespace-only
  /// input clears the override so the localized default (`splashSinceDate`)
  /// is used at render time.
  Future<void> setSplashDisplayText(String text) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    final normalized = text.trim().isEmpty ? kDefaultSplashDisplayText : text;
    await repo.setSplashDisplayText(normalized);
  }

  /// Writes the custom splash button label. Empty / whitespace-only input
  /// clears the override so the localized default (`splashEnter`) is used
  /// at render time.
  Future<void> setSplashButtonLabel(String label) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    final normalized = label.trim().isEmpty
        ? kDefaultSplashButtonLabel
        : label;
    await repo.setSplashButtonLabel(normalized);
  }
}

// ---------- Internal stream composition ----------

/// Wires the eight upstream preference streams into a single
/// `SettingsState` stream. Emits `SettingsState.data` once every upstream
/// has produced at least one value; subsequent emissions re-emit the
/// projected state.
///
/// Kept in a plain class (not a closure) so `ref.onDispose` can cancel
/// subscriptions deterministically — the same pattern Accounts uses.
class _SettingsComposer {
  _SettingsComposer(this._repo) {
    _out = StreamController<SettingsState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final UserPreferencesRepository _repo;
  late final StreamController<SettingsState> _out;

  StreamSubscription<ThemeMode>? _themeSub;
  StreamSubscription<Locale?>? _localeSub;
  StreamSubscription<String>? _defaultCurrencySub;
  StreamSubscription<int?>? _defaultAccountSub;
  StreamSubscription<bool>? _splashEnabledSub;
  StreamSubscription<DateTime?>? _splashStartDateSub;
  StreamSubscription<String>? _splashDisplayTextSub;
  StreamSubscription<String>? _splashButtonLabelSub;

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  String _defaultCurrency = 'USD';
  int? _defaultAccountId;
  bool _splashEnabled = true;
  DateTime? _splashStartDate;
  String _splashDisplayText = kDefaultSplashDisplayText;
  String _splashButtonLabel = kDefaultSplashButtonLabel;

  bool _seenTheme = false;
  bool _seenLocale = false;
  bool _seenDefaultCurrency = false;
  bool _seenDefaultAccount = false;
  bool _seenSplashEnabled = false;
  bool _seenSplashStartDate = false;
  bool _seenSplashDisplayText = false;
  bool _seenSplashButtonLabel = false;

  Stream<SettingsState> get stream => _out.stream;

  void _start() {
    _themeSub = _repo.watchThemeMode().listen(
      (v) {
        _themeMode = v;
        _seenTheme = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _localeSub = _repo.watchLocale().listen(
      (v) {
        _locale = v;
        _seenLocale = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _defaultCurrencySub = _repo.watchDefaultCurrency().listen(
      (v) {
        _defaultCurrency = v;
        _seenDefaultCurrency = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _defaultAccountSub = _repo.watchDefaultAccountId().listen(
      (v) {
        _defaultAccountId = v;
        _seenDefaultAccount = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _splashEnabledSub = _repo.watchSplashEnabled().listen(
      (v) {
        _splashEnabled = v;
        _seenSplashEnabled = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _splashStartDateSub = _repo.watchSplashStartDate().listen(
      (v) {
        _splashStartDate = v;
        _seenSplashStartDate = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _splashDisplayTextSub = _repo.watchSplashDisplayText().listen(
      (v) {
        _splashDisplayText = v;
        _seenSplashDisplayText = true;
        _emitIfReady();
      },
      onError: _onError,
    );
    _splashButtonLabelSub = _repo.watchSplashButtonLabel().listen(
      (v) {
        _splashButtonLabel = v;
        _seenSplashButtonLabel = true;
        _emitIfReady();
      },
      onError: _onError,
    );
  }

  Future<void> _stop() async {
    await _themeSub?.cancel();
    _themeSub = null;
    await _localeSub?.cancel();
    _localeSub = null;
    await _defaultCurrencySub?.cancel();
    _defaultCurrencySub = null;
    await _defaultAccountSub?.cancel();
    _defaultAccountSub = null;
    await _splashEnabledSub?.cancel();
    _splashEnabledSub = null;
    await _splashStartDateSub?.cancel();
    _splashStartDateSub = null;
    await _splashDisplayTextSub?.cancel();
    _splashDisplayTextSub = null;
    await _splashButtonLabelSub?.cancel();
    _splashButtonLabelSub = null;
  }

  Future<void> dispose() async {
    await _stop();
    if (!_out.isClosed) await _out.close();
  }

  void _onError(Object error, StackTrace stack) {
    if (_out.isClosed) return;
    _out.add(SettingsState.error(error, stack));
  }

  void _emitIfReady() {
    if (_out.isClosed) return;
    if (!_seenTheme ||
        !_seenLocale ||
        !_seenDefaultCurrency ||
        !_seenDefaultAccount ||
        !_seenSplashEnabled ||
        !_seenSplashStartDate ||
        !_seenSplashDisplayText ||
        !_seenSplashButtonLabel) {
      return;
    }
    _out.add(
      SettingsState.data(
        themeMode: _themeMode,
        locale: _locale,
        defaultCurrency: _defaultCurrency,
        defaultAccountId: _defaultAccountId,
        splashEnabled: _splashEnabled,
        splashStartDate: _splashStartDate,
        splashDisplayText: _splashDisplayText == kDefaultSplashDisplayText
            ? null
            : _splashDisplayText,
        splashButtonLabel: _splashButtonLabel == kDefaultSplashButtonLabel
            ? null
            : _splashButtonLabel,
      ),
    );
  }
}
