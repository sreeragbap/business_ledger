import 'dart:math' as math;

import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('switching themes blends the palettes instead of jumping', () {
    const dark = AppPalette.dark;
    const light = AppPalette.light;
    expect(dark.lerp(light, 0).background, dark.background);
    expect(dark.lerp(light, 1).background, light.background);
    final halfway = dark.lerp(light, 0.5);
    expect(
      halfway.background,
      Color.lerp(dark.background, light.background, .5),
    );
    expect(halfway.accent, isNot(anyOf(dark.accent, light.accent)));
  });

  for (final (name, p) in [
    ('dark', AppPalette.dark),
    ('light', AppPalette.light),
  ]) {
    group('$name palette', () {
      final surfaces = {
        'background': p.background,
        'surface': p.surface,
        'surfaceRaised': p.surfaceRaised,
      };

      // Text colours that must meet AA (4.5:1) on every surface.
      final text = {
        'textPrimary': p.textPrimary,
        'textSecondary': p.textSecondary,
        'textTertiary': p.textTertiary,
        'accent': p.accent,
        'income': p.income,
        'expense': p.expense,
        'warning': p.warning,
        'info': p.info,
        'error': p.error,
        'refund': p.refund,
        'swatchGreen': p.swatchGreen,
        'swatchTeal': p.swatchTeal,
        'swatchAmber': p.swatchAmber,
        'swatchPurple': p.swatchPurple,
        'swatchBlue': p.swatchBlue,
        'swatchGrey': p.swatchGrey,
        'swatchOrange': p.swatchOrange,
      };

      for (final surface in surfaces.entries) {
        for (final ink in text.entries) {
          test('${ink.key} on ${surface.key} meets AA', () {
            expect(
              contrast(ink.value, surface.value),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }

      test('text on the accent button meets AA', () {
        expect(contrast(p.onAccent, p.accent), greaterThan(4.5));
      });

      test('text on the destructive button meets AA', () {
        expect(contrast(p.onError, p.error), greaterThan(4.5));
      });

      test('status text on its own tint over a surface meets AA', () {
        for (final ink in [p.income, p.expense, p.warning, p.info, p.accent]) {
          final tinted = Color.alphaBlend(AppColors.tint(ink), p.surface);
          expect(
            contrast(ink, tinted),
            greaterThanOrEqualTo(4.5),
            reason: '$ink',
          );
        }
      });
    });
  }
}
