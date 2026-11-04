import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/user_preferences_repository.dart';
import 'repository_providers.dart';

part 'splash_redirect_provider.g.dart';

/// Synchronous snapshot consumed by the router's redirect callback.
///
/// Bridge between Drift's reactive streams and go_router's synchronous
/// `redirect:`. Updated from long-lived stream subscriptions; notifies
/// listeners only when a field value actually changes (duplicate-value no-op).
class SplashGateSnapshot extends ChangeNotifier {
  SplashGateSnapshot.withInitial({
    required bool enabled,
    required DateTime? startDate,
  }) : splashEnabled = enabled,
       splashStartDate = startDate;

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

  /// Subscribes to [repo]'s splash streams and registers `ref.onDispose` to
  /// cancel both subscriptions and dispose this notifier. Returns `this`.
  SplashGateSnapshot bindTo(Ref ref, UserPreferencesRepository repo) {
    final sub1 = repo.watchSplashEnabled().listen(updateEnabled);
    final sub2 = repo.watchSplashStartDate().listen(updateStartDate);
    ref.onDispose(() {
      sub1.cancel();
      sub2.cancel();
      dispose();
    });
    return this;
  }
}

// Scope-overridable. Declares `userPreferencesRepository` so the static
// body's `ref.watch` satisfies the lint; bootstrap.dart's `overrideWith`
// replaces the body entirely with one that captures `preferencesRepo`
// directly (no `ref.watch`), so the override path is not bound by this
// declaration in production.
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Raw<SplashGateSnapshot> splashGateSnapshot(Ref ref) =>
    SplashGateSnapshot.withInitial(
      enabled: true,
      startDate: null,
    ).bindTo(ref, ref.watch(userPreferencesRepositoryProvider));

/// Stream of `splash_start_date` for reactive UI (e.g. `SplashScreen`).
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<DateTime?> splashStartDate(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchSplashStartDate();
