import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Corner radii. The doubles are design units; the [BorderRadius] getters are
/// already scaled with `.r` (the smaller axis ratio, so corners stay round).
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(lg.r);
  static BorderRadius get input => BorderRadius.circular(md.r);
  static BorderRadius get button => BorderRadius.circular(md.r);
  static BorderRadius get chip => BorderRadius.circular(pill);
  static BorderRadius get dialog => BorderRadius.circular(xl.r);

  /// Top corners only: a bottom sheet runs off the bottom of the screen.
  static BorderRadius get sheet =>
      BorderRadius.vertical(top: Radius.circular(xl.r));
}
