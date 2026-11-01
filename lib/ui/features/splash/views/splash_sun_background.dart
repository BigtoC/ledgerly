// Splash sun background (plan §3.1, §5 layer 1).
//
// Renders a warm sun-tinted background behind the day counter. Tries to load
// `assets/splash/sun-splash.png` first; when the asset is missing
// (placeholder state during development — see `assets/splash/README.md`),
// falls back to a radial gradient that approximates the sun aesthetic.
// Either way a dark-to-black vertical gradient is layered on top to preserve
// contrast with the white day count and rainbow-gradient date per PRD §
// Accessibility.

import 'package:flutter/material.dart';

class SplashSunBackground extends StatelessWidget {
  const SplashSunBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base layer: procedural radial gradient approximating a sun.
        // This is the fallback when `sun-splash.png` is missing or unsuitable
        // stub — the real asset drops in as part of M6.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: <Color>[
                Color(0xFFFFE29A), // warm yellow (sun core)
                Color(0xFFFF9A5A), // orange glow
                Color(0xFFB8522E), // dusk red-brown
                Color(0xFF1B1930), // night edges
              ],
              stops: <double>[0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
        // Optional image overlay — `Image.asset` renders the real asset once
        // it ships; if the file does not resolve (placeholder state) the
        // errorBuilder keeps the gradient visible.
        Positioned.fill(
          child: Image.asset(
            'assets/splash/sun-splash.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        // Contrast overlay to protect the center text from mid-key asset
        // luminance (PRD → Accessibility / WCAG AA).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x33000000), Color(0x66000000)],
            ),
          ),
        ),
      ],
    );
  }
}
