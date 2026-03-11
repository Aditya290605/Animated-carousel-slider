import 'dart:math';

import 'package:flutter/animation.dart';

/// A custom 3-phase spring-like animation curve.
///
/// The curve progresses through three distinct phases:
/// 1. **Quick start** (0.0–0.3): Fast initial movement using an ease-out power curve.
///    Covers ~35% of the total value range.
/// 2. **Smooth middle** (0.3–0.8): Steady progression with cubic ease-out.
///    Covers ~55% of the total value range.
/// 3. **Gentle settle** (0.8–1.0): Soft landing with quartic ease-out.
///    Covers the final ~10% for a natural deceleration feel.
///
/// This creates a spring-like feel without actual spring physics — fast initial
/// response followed by a smooth, cushioned settle.
class SpringCurve extends Curve {
  const SpringCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.3) {
      // Phase 1: Quick start — ease-out with power 2.5
      final phase1 = t / 0.3;
      return 0.35 * (1.0 - pow(1.0 - phase1, 2.5));
    } else if (t < 0.8) {
      // Phase 2: Smooth middle — cubic ease-out
      final phase2 = (t - 0.3) / 0.5;
      final easeOut = 1.0 - pow(1.0 - phase2, 3.0);
      return 0.35 + (0.55 * easeOut);
    } else {
      // Phase 3: Gentle settle — quartic ease-out
      final phase3 = (t - 0.8) / 0.2;
      final gentle = 1.0 - pow(1.0 - phase3, 4.0);
      return 0.9 + (0.1 * gentle);
    }
  }
}

/// Blended easing function that combines three ease-out variants for a
/// smooth, natural-feeling interpolation.
///
/// Blends:
/// - **easeOutQuart** (weight 0.3): `1 - (1-t)^4` — smooth deceleration
/// - **easeOutExpo** (weight 0.4): `1 - 2^(-8t)` — sharp initial move, fast settle
/// - **easeOutCirc** (weight 0.3): `√(1 - (t-1)²)` — circular arc deceleration
///
/// The weighted blend (`0.3 * quart + 0.4 * expo + 0.3 * circ`) produces a
/// versatile curve that feels responsive yet smooth.
///
/// [t] is the normalized progress (0.0 to 1.0).
/// [start] and [end] define the value range to interpolate between.
double smoothEase(double t, double start, double end) {
  final easeOutQuart = 1.0 - pow(1.0 - t, 4.0);
  final easeOutExpo = t == 1.0 ? 1.0 : 1.0 - pow(2.0, -8.0 * t);
  final easeOutCirc = sqrt(1.0 - pow(t - 1.0, 2.0));

  final blended =
      (0.3 * easeOutQuart) + (0.4 * easeOutExpo) + (0.3 * easeOutCirc);
  return start + (end - start) * blended;
}
