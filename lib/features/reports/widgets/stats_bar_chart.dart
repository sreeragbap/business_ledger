import 'dart:math' as math;

import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which pair of figures the chart compares.
enum ChartSeries {
  incomeExpense('Income', 'Expenses'),
  cash('Cash received', 'Cash paid');

  const ChartSeries(this.primaryLabel, this.secondaryLabel);
  final String primaryLabel;
  final String secondaryLabel;

  int primary(StatsBucket bucket) =>
      this == incomeExpense ? bucket.incomeMinor : bucket.cashInMinor;

  int secondary(StatsBucket bucket) =>
      this == incomeExpense ? bucket.expenseMinor : bucket.cashOutMinor;
}

/// Paired bars per bucket (in vs out), drawn with a [CustomPainter] and
/// grown in on first paint and on every data change.
///
/// Tap a bar group to read its exact figures below the chart; the whole
/// series is also summarised for screen readers.
class StatsBarChart extends StatefulWidget {
  const StatsBarChart({
    required this.buckets,
    required this.currency,
    this.series = ChartSeries.incomeExpense,
    this.height = 180,
    super.key,
  });

  final List<StatsBucket> buckets;
  final Currency currency;
  final ChartSeries series;

  /// Design units.
  final double height;

  @override
  State<StatsBarChart> createState() => _StatsBarChartState();
}

class _StatsBarChartState extends State<StatsBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(StatsBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null && _selected! >= widget.buckets.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    final series = widget.series;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final selected = _selected == null ? null : buckets[_selected!];

    final primaryTotal = buckets.fold<int>(0, (s, b) => s + series.primary(b));
    final secondaryTotal = buckets.fold<int>(
      0,
      (s, b) => s + series.secondary(b),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              'Bar chart, ${buckets.length} periods. '
              '${series.primaryLabel} '
              '${Money.format(primaryTotal, widget.currency)}, '
              '${series.secondaryLabel} '
              '${Money.format(secondaryTotal, widget.currency)}.',
          excludeSemantics: true,
          child: SizedBox(
            height: widget.height.h,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _select(
                  details.localPosition.dx,
                  constraints.maxWidth,
                ),
                child: TweenAnimationBuilder<double>(
                  // Keyed on the data so a new period grows in again.
                  key: ValueKey(Object.hashAll(buckets)),
                  tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                  duration: reduceMotion ? Duration.zero : AppMotion.slow * 2,
                  curve: AppMotion.emphasized,
                  builder: (context, progress, _) => CustomPaint(
                    size: Size(constraints.maxWidth, widget.height.h),
                    painter: _BarChartPainter(
                      palette: context.colors,
                      primary: [for (final b in buckets) series.primary(b)],
                      secondary: [for (final b in buckets) series.secondary(b)],
                      labels: [for (final b in buckets) b.label],
                      progress: progress,
                      selected: _selected,
                      currency: widget.currency,
                      labelStyle: textTheme.labelSmall!.copyWith(
                        color: context.colors.textTertiary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Row(
            key: ValueKey(_selected),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.lg.w,
                  runSpacing: AppSpacing.xs.h,
                  children: [
                    _Legend(
                      colour: context.colors.income,
                      label: series.primaryLabel,
                      value: Money.format(
                        selected == null
                            ? primaryTotal
                            : series.primary(selected),
                        widget.currency,
                      ),
                    ),
                    _Legend(
                      colour: context.colors.expense,
                      label: series.secondaryLabel,
                      value: Money.format(
                        selected == null
                            ? secondaryTotal
                            : series.secondary(selected),
                        widget.currency,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Text(selected?.label ?? 'Total', style: textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }

  void _select(double dx, double width) {
    final count = widget.buckets.length;
    if (count == 0 || width <= 0) return;
    const plotLeft = _BarChartPainter.axisWidth;
    final slot = (width - plotLeft) / count;
    final index = ((dx - plotLeft) / slot).floor();
    setState(() {
      _selected = index < 0 || index >= count || index == _selected
          ? null
          : index;
    });
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.colour,
    required this.label,
    required this.value,
  });

  final Color colour;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        SizedBox(width: AppSpacing.xs.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelSmall),
            Text(value, style: textTheme.labelMedium),
          ],
        ),
      ],
    );
  }
}

/// Geometry only: amounts become doubles here, to place pixels, and nowhere
/// else.
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.primary,
    required this.secondary,
    required this.labels,
    required this.progress,
    required this.selected,
    required this.currency,
    required this.labelStyle,
    required this.palette,
  });

  static const double axisWidth = 40;
  static const double labelHeight = 18;

  final List<int> primary;
  final List<int> secondary;
  final List<String> labels;
  final double progress;
  final int? selected;
  final Currency currency;
  final TextStyle labelStyle;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final count = primary.length;
    final plot = Rect.fromLTRB(
      axisWidth,
      4,
      size.width,
      size.height - labelHeight,
    );
    final maxValue = [
      ...primary,
      ...secondary,
    ].fold<int>(0, math.max);

    final grid = Paint()
      ..color = palette.divider
      ..strokeWidth = 1;
    // Three gridlines: 0, half, max.
    for (var step = 0; step <= 2; step++) {
      final y = plot.bottom - plot.height * step / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      if (maxValue > 0 || step == 0) {
        _text(
          canvas,
          Money.compact(maxValue * step ~/ 2, currency),
          Offset(0, y - 6),
          maxWidth: axisWidth - 4,
        );
      }
    }
    if (count == 0) return;

    final slot = plot.width / count;
    final barWidth = math.min(14, slot * 0.32).toDouble();
    final gap = math.min(3, slot * 0.06).toDouble();
    final radius = Radius.circular(math.min(4, barWidth / 2));
    final income = Paint()..color = palette.income;
    final expense = Paint()..color = palette.expense;
    final faded = selected != null;

    for (var i = 0; i < count; i++) {
      final centre = plot.left + slot * i + slot / 2;
      final dim = faded && selected != i;
      if (selected == i) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              centre - slot / 2 + 1,
              plot.top,
              centre + slot / 2 - 1,
              plot.bottom,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = palette.surfaceHigh,
        );
      }
      for (final (value, paint, left) in [
        (primary[i], income, centre - gap / 2 - barWidth),
        (secondary[i], expense, centre + gap / 2),
      ]) {
        if (value <= 0 || maxValue <= 0) continue;
        final height = plot.height * (value / maxValue) * progress;
        final colour = paint.color.withValues(alpha: dim ? 0.35 : 1);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, plot.bottom - height, barWidth, height),
            topLeft: radius,
            topRight: radius,
          ),
          Paint()..color = colour,
        );
      }
    }

    // As many x labels as fit, evenly spaced, always including the first.
    final every = math.max(1, (count * 48 / plot.width).ceil());
    for (var i = 0; i < count; i += every) {
      final centre = plot.left + slot * i + slot / 2;
      _text(
        canvas,
        labels[i],
        Offset(centre, plot.bottom + 4),
        maxWidth: slot * every,
        centred: true,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required double maxWidth,
    bool centred = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, maxWidth));
    painter.paint(
      canvas,
      centred ? at.translate(-painter.width / 2, 0) : at,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      !listEquals(old.labels, labels) ||
      !listEquals(old.primary, primary) ||
      !listEquals(old.secondary, secondary) ||
      old.palette != palette;
}
