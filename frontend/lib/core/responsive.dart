import 'package:flutter/material.dart';

class Responsive {
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 700 && width < 1024;
  }

  static bool showSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= 960;
  }

  static double contentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1280) return 24;
    if (width >= 960) return 20;
    if (width >= 700) return 16;
    return 14;
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
