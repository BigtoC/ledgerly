import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'splash_redirect_provider.g.dart';

/// Synchronous snapshot consumed by the router's redirect callback.
///
/// Bridge between Drift's reactive streams and go_router's synchronous
/// `redirect:`. Updated from long-lived stream subscriptions; notifies
/// listeners only when a field value actually changes (duplicate-value no-op).
class SplashGateSnapshot extends ChangeNotifier {
  SplashGateSnapshot._({bool enabled = true, DateTime? startDate})
    : splashEnabled = enabled,
      splashStartDate = startDate;

  factory SplashGateSnapshot.withInitial({
    required bool enabled,
    required DateTime? startDate,
  }) => SplashGateSnapshot._(enabled: enabled, startDate: startDate);

  bool splashEnabled;
  DateTime? splashStartDate;

  void updateEnabled(bool v) {
    if (v == splashEnabled) return;
    splashEnabled = v;
    notifyListeners();
  }

  void updateStartDate(DateTime? v) {
    if (v == splashStartDate) return;
    splashStartDate = v;
    notifyListeners();
  }
}

// Scope-overridable. Declares `userPreferencesRepository` so the static
// body's `ref.watch` satisfies the lint; bootstrap.dart's `overrideWith`
// replaces the body entirely with one that captures `preferencesRepo`
// directly (no `ref.watch`), so the override path is not bound by this
// declaration in production.
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
SplashGateSnapshot splashGateSnapshot(Ref ref) {
  final notifier = SplashGateSnapshot._();
  final repo = ref.watch(userPreferencesRepositoryProvider);

  final sub1 = repo.watchSplashEnabled().listen(notifier.updateEnabled);
  final sub2 = repo.watchSplashStartDate().listen(notifier.updateStartDate);

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    notifier.dispose();
  });

  return notifier;
}

/// Stream of `splash_enabled` for reactive UI (e.g. `SettingsScreen`).
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<bool> splashEnabled(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchSplashEnabled();

/// Stream of `splash_start_date` for reactive UI (e.g. `SplashScreen`).
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<DateTime?> splashStartDate(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchSplashStartDate();
