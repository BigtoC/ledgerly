# Splash assets

This directory hosts the sun-themed background art referenced by the
splash slice (`lib/features/splash/widgets/splash_sun_background.dart`).

## Current state (M5 Wave 1)

No image file is committed yet. The splash screen renders a procedural
radial-gradient background that visually approximates the final sun
aesthetic. When an image file named `sun_background.png` is dropped
into this directory, `Image.asset(...)` will overlay it on top of the
gradient (the gradient remains visible around the image as a safety net
until the final asset's aspect ratio matches every viewport).

## M6 follow-up

The final sun asset is produced as part of the M6 native-splash
regeneration pass per `docs/plans/implementation-plan.md` → M6. The
replacement must be:

- MIT-compatible (or original to this project).
- Provided in `1x`, `2x`, and `3x` density variants per Flutter asset
  conventions (`assets/splash/sun_background.png`,
  `assets/splash/2.0x/sun_background.png`,
  `assets/splash/3.0x/sun_background.png`).
- Luminance-calibrated so white day-count text and the rainbow gradient
  retain WCAG AA contrast at every location (the splash widget applies
  an additional top-to-bottom dark overlay as a safety net).

The license and original source for the final asset must be recorded
here before the PR that ships it lands.
