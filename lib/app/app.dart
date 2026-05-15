import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/repository_providers.dart';
import 'providers/theme_provider.dart';
import 'router.dart';

typedef SchedulePostFrameCallbackFn = void Function(VoidCallback callback);

void _defaultSchedulePostFrameCallback(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback((_) => callback());
}

class App extends ConsumerStatefulWidget {
  const App({
    super.key,
    this.onFirstFrame,
    this.schedulePostFrameCallback = _defaultSchedulePostFrameCallback,
  });

  final VoidCallback? onFirstFrame;
  final SchedulePostFrameCallbackFn schedulePostFrameCallback;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _ranFirstFrameCallback = false;

  @override
  void initState() {
    super.initState();
    widget.schedulePostFrameCallback(_runFirstFrameCallback);
  }

  void _runFirstFrameCallback() {
    if (_ranFirstFrameCallback || !mounted) return;
    _ranFirstFrameCallback = true;
    widget.onFirstFrame?.call();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final preferredLocale = ref.watch(userLocalePreferenceProvider);
    // Force instantiation of the keep-alive exchange-rate repository so
    // its DAO + defaultCurrency listeners register on first build.
    ref.watch(exchangeRateRepositoryProvider);
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: preferredLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (device, supported) => resolveChineseLocale(
        preferredLocale,
        supported,
        device ?? const Locale('en', 'US'),
      ),
      routerConfig: router,
    );
  }
}
