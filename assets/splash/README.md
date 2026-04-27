# Splash assets

This directory hosts the sun-themed background art referenced by the
splash slice (`lib/features/splash/widgets/splash_sun_background.dart`).

## Current state

`sun-splash.png` is now committed in this directory. The Flutter splash
screen overlays that asset on top of the procedural gradient so the
gradient remains visible as a safety net if the image crop does not fit
every viewport cleanly.

## M6 follow-up

The final sun asset is produced as part of the M6 native-splash
regeneration pass per `docs/plans/implementation-plan.md` → M6. The
replacement must be:

- MIT-compatible (or original to this project).
- Referenced as `assets/splash/sun-splash.png` by both the runtime Flutter
  splash and the `flutter_native_splash` regeneration step.
- If higher-density variants are added later, keep the same base filename
  (`assets/splash/sun-splash.png`, `assets/splash/2.0x/sun-splash.png`,
  `assets/splash/3.0x/sun-splash.png`).
- Luminance-calibrated so white day-count text and the rainbow gradient
  retain WCAG AA contrast at every location (the splash widget applies
  an additional top-to-bottom dark overlay as a safety net).

The license and original source for the final asset must be recorded
here before the PR that ships it lands.
