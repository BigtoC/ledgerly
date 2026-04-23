// TODO(M5): Settings screen per PRD -> MVP Screens. Theme toggle, language
// selector, default account, default currency, manage categories, splash
// screen settings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/repository_providers.dart';
import '../../app/providers/splash_redirect_provider.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final splashOn = ref.watch(splashEnabledProvider).value ?? true;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.settingsSplashEnabled),
            value: splashOn,
            onChanged: (v) =>
                ref.read(userPreferencesRepositoryProvider).setSplashEnabled(v),
          ),
        ],
      ),
    );
  }
}
