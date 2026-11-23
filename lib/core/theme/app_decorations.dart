import 'package:flutter/material.dart';

/// Reusable decorations shared across features.
class AppDecorations {
  AppDecorations._();

  /// Soft tinted rounded square used behind icons (auth, onboarding, empty states).
  static BoxDecoration tintedIconBox(Color color, {double radius = 16}) =>
      BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration gradientHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.primary, scheme.secondary],
      ),
    );
  }
}
