import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  static EdgeInsets getScreenPaddingWithBottom(BuildContext context) {
    final basePadding = getScreenPadding(context);
    final bottomPadding = getBottomSafeArea(context);
    return EdgeInsets.fromLTRB(
      basePadding.left,
      basePadding.top,
      basePadding.right,
      basePadding.bottom + bottomPadding,
    );
  }

  static double getBottomSafeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final viewInsets = mediaQuery.viewInsets.bottom;

    // Add extra padding for bottom navigation or floating action buttons
    double extraPadding = 0;
    if (isMobile(context) && isPortrait(context)) {
      extraPadding = 100; // Increased padding for bottom navigation bar
    } else if (isMobile(context) && isLandscape(context)) {
      extraPadding = 60; // Extra padding for landscape mode
    } else {
      extraPadding = 40; // Base padding for tablet/desktop
    }

    return bottomPadding + viewInsets + extraPadding;
  }

  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = getBottomSafeArea(context);
    final appBarHeight = getAppBarHeight(context);

    return screenHeight - topPadding - bottomPadding - appBarHeight;
  }

  static double getGridCrossAxisCount(
    BuildContext context, {
    double itemWidth = 200,
  }) {
    final screenWidth = getScreenWidth(context);
    final padding = getScreenPadding(context);
    final availableWidth = screenWidth - (padding.left + padding.right);
    return (availableWidth / itemWidth).floor().toDouble().clamp(1, 6);
  }

  static double getCardWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth - 32; // Full width minus padding
    } else if (isTablet(context)) {
      return (screenWidth - 48) / 2; // Two columns
    } else {
      return (screenWidth - 64) / 3; // Three columns
    }
  }

  static int getBottomNavType(BuildContext context) {
    if (isMobile(context) && isPortrait(context)) {
      return 0; // Fixed bottom navigation
    } else if (isMobile(context) && isLandscape(context)) {
      return 1; // Drawer only
    } else {
      return 2; // Side navigation rail
    }
  }

  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else {
      return kToolbarHeight + 8;
    }
  }

  static TextStyle getHeadingStyle(BuildContext context) {
    if (isMobile(context)) {
      return const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    } else if (isTablet(context)) {
      return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    } else {
      return const TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
    }
  }

  static TextStyle getBodyStyle(BuildContext context) {
    if (isMobile(context)) {
      return const TextStyle(fontSize: 14);
    } else if (isTablet(context)) {
      return const TextStyle(fontSize: 16);
    } else {
      return const TextStyle(fontSize: 18);
    }
  }

  static double getIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 24;
    } else if (isTablet(context)) {
      return 28;
    } else {
      return 32;
    }
  }

  static EdgeInsets getDialogPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  static double getDialogWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return screenWidth * 0.7;
    } else {
      return screenWidth * 0.5;
    }
  }

  static BoxConstraints getDialogConstraints(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    final screenHeight = getScreenHeight(context);

    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.95,
        maxHeight: screenHeight * 0.8,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.8,
        maxHeight: screenHeight * 0.85,
      );
    } else {
      return BoxConstraints(
        maxWidth: screenWidth * 0.6,
        maxHeight: screenHeight * 0.9,
      );
    }
  }

  static Widget adaptiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
  }) {
    return Container(
      padding: padding ?? getScreenPadding(context),
      margin: margin,
      width: width,
      height: height,
      child: child,
    );
  }

  static Widget responsiveRow({
    required BuildContext context,
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool forceColumn = false,
  }) {
    if (isMobile(context) || forceColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
  }

  static Widget responsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double itemWidth = 200,
    double spacing = 16,
    bool shrinkWrap = true,
  }) {
    final crossAxisCount = getGridCrossAxisCount(context, itemWidth: itemWidth);

    return GridView.count(
      crossAxisCount: crossAxisCount.toInt(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: children,
    );
  }

  static SliverGridDelegate getResponsiveGridDelegate(
    BuildContext context, {
    double itemWidth = 200,
    double spacing = 16,
    double childAspectRatio = 1.0,
  }) {
    final crossAxisCount = getGridCrossAxisCount(context, itemWidth: itemWidth);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount.toInt(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return builder(context, isMobile, isTablet, isDesktop);
  }
}

class ResponsiveOrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isPortrait, bool isLandscape)
  builder;

  const ResponsiveOrientationBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isPortrait = ResponsiveHelper.isPortrait(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return builder(context, isPortrait, isLandscape);
  }
}
