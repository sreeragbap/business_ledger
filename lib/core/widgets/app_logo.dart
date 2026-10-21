import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The app mark until a designed logo lands: an accent tile with a ledger
/// glyph. Wrapped in a [Hero] so it flies from the splash to sign-in.
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 72, super.key});

  /// Design units.
  final double size;

  static const String heroTag = 'app-logo';

  @override
  Widget build(BuildContext context) {
    final side = size.r;
    return Hero(
      tag: heroTag,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((AppRadius.lg * size / 72).r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.colors.accent, context.colors.accentPressed],
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.accent.withValues(alpha: 0.25),
              blurRadius: side * 0.45,
              spreadRadius: -side * 0.1,
              offset: Offset(0, side * 0.12),
            ),
          ],
        ),
        child: Icon(
          Icons.menu_book_rounded,
          size: side * 0.5,
          color: context.colors.onAccent,
        ),
      ),
    );
  }
}
