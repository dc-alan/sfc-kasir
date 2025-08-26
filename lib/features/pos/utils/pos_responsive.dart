import 'package:flutter/material.dart';
import '../../../utils/responsive_helper.dart';

class POSResponsive {
  static bool isMobile(BuildContext context) =>
      ResponsiveHelper.isMobile(context);

  static bool isTablet(BuildContext context) =>
      ResponsiveHelper.isTablet(context);

  static bool isDesktop(BuildContext context) =>
      ResponsiveHelper.isDesktop(context);

  static double getProductGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double getProductItemHeight(BuildContext context) {
    if (isDesktop(context)) return 180;
    if (isTablet(context)) return 160;
    return 140;
  }
}
