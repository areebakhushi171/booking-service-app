import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized spacing, radius and dimension values (ScreenUtil based).
/// Use these instead of hard-coded numbers in new/updated screens.
class AppSizes {
  AppSizes._();

  // Spacing scale
  static double get s4 => 4.w;
  static double get s8 => 8.w;
  static double get s12 => 12.w;
  static double get s16 => 16.w;
  static double get s20 => 20.w;
  static double get s24 => 24.w;
  static double get s32 => 32.w;

  // Radius
  static double get radiusS => 10.r;
  static double get radiusM => 14.r;
  static double get radiusL => 18.r;
  static double get radiusXL => 24.r;

  // Screen paddings
  static EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h);
  static EdgeInsets get authPadding =>
      EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h);

  // Components
  static double get buttonHeight => 52.h;
  static double get iconM => 22.sp;
  static double get avatarL => 88.r;
  static double get maxFormWidth => 440; // logical px, for tablets/web
}
