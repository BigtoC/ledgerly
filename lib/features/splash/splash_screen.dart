// Splash screen — hnotes-style day counter (PRD → Splash Screen).
//
// Composition (plan §5 bottom → top):
//   1. `SplashSunBackground` — full-viewport sun image + contrast overlay.
//   2. Center content column — day count, "days" label, rainbow-gradient
//      start date, optional custom display text.
//   3. Bottom-center `SplashEnterButton` — navigates to `/home` via the
//      existing fade transition wired in `app/router.dart`.
//
// When `splash_start_date` is missing, the screen renders the launch-time
// "Set start date" action inline on the same route (plan §4 — no separate
// state-machine variant). Choosing a date writes the preference and
// rebuilds into the day-counter view on the same frame.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/splash_redirect_provider.dart';
import '../../l10n/app_localizations.dart';
import 'splash_controller.dart';
import 'splash_state.dart';
import 'widgets/splash_day_count.dart';
import 'widgets/splash_enter_button.dart';
import 'widgets/splash_rainbow_gradient_text.dart';
import 'widgets/splash_sun_background.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key, this.previewMode = false});

  /// When `true`, the Enter button pops the current route instead of
  /// going to `/home`. Set by the `/splash/preview` route reached from
  /// Settings → Splash → "Preview splash screen".
  final bool previewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // The launch-time start-date prompt is selected upstream of the
    // controller's sealed state because it is driven by a raw pref, not
    // by the computed day-counter state (plan §4). We consult both the
    // first-frame snapshot (set during bootstrap) and the live stream.
    final initialStartDate = ref
        .read(splashGateSnapshotProvider)
        .splashStartDate;
    final startDate =
        ref.watch(splashStartDateProvider).valueOrNull ?? initialStartDate;

    if (startDate == null) {
      return _LaunchTimeStartDatePrompt(label: l10n.splashSetStartDate);
    }

    final state = ref.watch(splashControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SplashSunBackground(),
          SafeArea(
            child: switch (state) {
              AsyncData(value: final SplashData data) => _SplashContent(
                data: data,
                previewMode: previewMode,
              ),
              AsyncData(value: SplashError()) => const _SplashErrorSurface(),
              AsyncError() => const _SplashErrorSurface(),
              _ => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.data, required this.previewMode});

  final SplashData data;
  final bool previewMode;

  @override
  Widget build(BuildContext context) {
    // The bottom Enter button is pinned outside the scroll viewport so that
    // long custom display text at 2× text scale reflows inside a scrollable
    // region rather than pushing the CTA off screen (PRD → Layout
    // Primitives → Constraint rule; plan §3.4 variant 3).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  SplashDayCount(
                    count: data.dayCount,
                    startDate: data.startDate,
                  ),
                  const SizedBox(height: 24),
                  SplashRainbowGradientText(text: data.formattedStartDate),
                  const SizedBox(height: 16),
                  Text(
                    data.formattedDisplayText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                      shadows: <Shadow>[
                        Shadow(color: Color(0xCC000000), blurRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          SplashEnterButton(label: data.buttonLabel, previewMode: previewMode),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SplashErrorSurface extends StatelessWidget {
  const _SplashErrorSurface();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.error_outline, size: 48, color: Colors.white),
    );
  }
}

class _LaunchTimeStartDatePrompt extends ConsumerWidget {
  const _LaunchTimeStartDatePrompt({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(splashClockProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SplashSunBackground(),
          SafeArea(
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: () async {
                  final initial = clock();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(9999, 12, 31),
                  );
                  if (picked == null) return;
                  if (!context.mounted) return;
                  await ref
                      .read(splashControllerProvider.notifier)
                      .setStartDate(picked);
                },
                child: Text(label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
