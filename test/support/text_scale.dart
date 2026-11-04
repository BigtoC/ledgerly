import 'package:flutter/widgets.dart';

/// `MaterialApp.builder` that forces a linear text scale, for the 2×
/// text-scale checks AGENTS.md requires.
TransitionBuilder textScaleBuilder(double scale) =>
    (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    );
