import 'package:flutter/material.dart';

class ResponsiveSpacing {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 600 && width < 900;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 900;
  }

  // Horizontal spacing
  static Widget horizontalSpacing(BuildContext context, {double? customSize}) {
    if (customSize != null) {
      return SizedBox(width: customSize);
    }

    if (isPortrait(context)) {
      if (isSmallScreen(context)) {
        return const SizedBox(
          width: 8,
        ); // Smaller spacing in portrait on small screens
      } else {
        return const SizedBox(
          width: 12,
        ); // Medium spacing in portrait on larger screens
      }
    } else {
      // Landscape mode
      if (isSmallScreen(context)) {
        return const SizedBox(width: 12);
      } else if (isMediumScreen(context)) {
        return const SizedBox(width: 16);
      } else {
        return const SizedBox(width: 20); // Larger spacing on big screens
      }
    }
  }

  // Vertical spacing
  static Widget verticalSpacing(BuildContext context, {double? customSize}) {
    if (customSize != null) {
      return SizedBox(height: customSize);
    }

    if (isPortrait(context)) {
      return const SizedBox(height: 12);
    } else {
      return const SizedBox(height: 8);
    }
  }

  // Padding values
  static EdgeInsets getPadding(BuildContext context) {
    if (isPortrait(context)) {
      if (isSmallScreen(context)) {
        return const EdgeInsets.all(12.0);
      } else {
        return const EdgeInsets.all(16.0);
      }
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  // Icon sizes
  static double getIconSize(BuildContext context, {bool isLarge = false}) {
    if (isPortrait(context) && isSmallScreen(context)) {
      return isLarge ? 22 : 18;
    } else {
      return isLarge ? 24 : 20;
    }
  }

  // Font sizes
  static double getSmallFontSize(BuildContext context) {
    return isPortrait(context) && isSmallScreen(context) ? 10 : 12;
  }

  static double getMediumFontSize(BuildContext context) {
    return isPortrait(context) && isSmallScreen(context) ? 14 : 16;
  }
}
