// Splash rainbow-gradient text (plan §5 layer 2, PRD → Splash Visual Design).
//
// Horizontal rainbow `ShaderMask` over the formatted start date.
// Contrast fallback: the text is rendered with a solid white shadow behind
// the gradient to guarantee WCAG AA contrast against the darkest regions
// of the sun background (plan §7 + §12 risk 2).

import 'package:flutter/material.dart';

class SplashRainbowGradientText extends StatelessWidget {
  const SplashRainbowGradientText({required this.text, this.style, super.key});

  final String text;
  final TextStyle? style;

  static const List<Color> _rainbow = <Color>[
    Color(0xFFE53935), // red
    Color(0xFFFB8C00), // orange
    Color(0xFFFDD835), // yellow
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFF3949AB), // indigo
    Color(0xFF8E24AA), // violet
  ];

  @override
  Widget build(BuildContext context) {
    final effective =
        (style ??
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ))
            .copyWith(
              shadows: const <Shadow>[
                // Subtle dark shadow behind the gradient guards contrast against
                // the light sun core and the dark night edges alike.
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
              color: Colors.white,
            );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: _rainbow,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, textAlign: TextAlign.center, style: effective),
    );
  }
}
