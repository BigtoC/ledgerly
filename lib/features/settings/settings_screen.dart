// Settings screen (plan §3.1, §5).
//
// Layout: `CustomScrollView` with one `SliverToBoxAdapter` per section.
// Sections (order):
//   1. Appearance — theme segmented control + language selector.
//   2. General — default account, default currency.
//   3. Splash — splash settings subsection (plan §6).
//   4. Data management — Manage Categories entry tile.
//
// The screen is purely a projection of `settingsControllerProvider` — it
// never reads repositories directly, and no data transformation happens
// in `build()` (PRD → Controller Contract).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';
import 'settings_providers.dart';
import 'settings_state.dart';
import 'widgets/default_account_tile.dart';
import 'widgets/default_currency_tile.dart';
import 'widgets/language_selector.dart';
import 'widgets/manage_categories_tile.dart';
import 'widgets/settings_section.dart';
import 'widgets/splash_settings_section.dart';
import 'widgets/theme_mode_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: switch (state) {
        AsyncData<SettingsState>(value: final SettingsData data) =>
          _SettingsBody(data: data),
        AsyncData<SettingsState>(value: SettingsError()) ||
        AsyncError() => const _ErrorSurface(),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.data});

  final SettingsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    const EdgeInsets cardPadding = EdgeInsets.symmetric(
      horizontal: homePageCardHorizontalPadding - 16,
    );
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: SettingsSection(
              title: l10n.settingsSectionAppearance,
              children: [
                ThemeModeSelector(value: data.themeMode),
                LanguageSelector(value: data.locale),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: SettingsSection(
              title: l10n.settingsSectionGeneral,
              children: [
                DefaultAccountTile(defaultAccountId: data.defaultAccountId),
                DefaultCurrencyTile(defaultCurrency: data.defaultCurrency),
                const ManageCategoriesTile(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: cardPadding,
          sliver: SliverToBoxAdapter(
            child: SplashSettingsSection(
              splashEnabled: data.splashEnabled,
              splashStartDate: data.splashStartDate,
              splashDisplayText: data.splashDisplayText,
              splashButtonLabel: data.splashButtonLabel,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 32),
            child: Center(
              child: GestureDetector(
                onTap: () => context.push('/settings/about'),
                child: Text(
                  packageInfo
                          .whenData(
                            (info) => 'v${info.version}+${info.buildNumber}',
                          )
                          .valueOrNull ??
                      '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.errorSnackbarGeneric),
      ),
    );
  }
}
