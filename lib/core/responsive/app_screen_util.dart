import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Initialises `flutter_screenutil` for the app: the single place `.w`, `.h`,
/// `.r` and `.sp` are configured, so a widget cannot lay out one way in the
/// app and another in a test.
///
/// Sits above `MaterialApp` and takes a [builder] because `ThemeData` reads
/// `.sp` while it is being constructed.
class AppScreenUtil extends StatelessWidget {
  const AppScreenUtil({required this.builder, super.key});

  /// The design frame every token is measured on.
  static const Size designSize = Size(393, 852);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      builder: (context, _) => builder(context),
    );
  }
}
