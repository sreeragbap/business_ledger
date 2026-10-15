import 'dart:math' as math;

import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const surfaces = {
    'background': AppColors.background,
    'surface': AppColors.surface,
    'surfaceRaised': AppColors.surfaceRaised,
  };

  // Text colours that must meet AA (4.5:1) on every surface.
  const text = {
    'textPrimary': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'textTertiary': AppColors.textTertiary,
    'accent': AppColors.accent,
    'income': AppColors.income,
    'expense': AppColors.expense,
    'warning': AppColors.warning,
    'info': AppColors.info,
    'error': AppColors.error,
    'refund': AppColors.refund,
    'swatchGreen': AppColors.swatchGreen,
    'swatchTeal': AppColors.swatchTeal,
    'swatchAmber': AppColors.swatchAmber,
    'swatchPurple': AppColors.swatchPurple,
    'swatchBlue': AppColors.swatchBlue,
    'swatchGrey': AppColors.swatchGrey,
    'swatchOrange': AppColors.swatchOrange,
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
    expect(contrast(AppColors.onAccent, AppColors.accent), greaterThan(4.5));
  });

  test('text on the destructive button meets AA', () {
    expect(contrast(AppColors.onError, AppColors.error), greaterThan(4.5));
  });

  test('status text on its own tint over a surface meets AA', () {
    for (final ink in [
      AppColors.income,
      AppColors.expense,
      AppColors.warning,
      AppColors.info,
      AppColors.accent,
    ]) {
      final tinted = Color.alphaBlend(AppColors.tint(ink), AppColors.surface);
      expect(contrast(ink, tinted), greaterThanOrEqualTo(4.5), reason: '$ink');
    }
  });
}
