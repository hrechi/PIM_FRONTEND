import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Provides breakpoints and adaptive values for mobile, tablet, and desktop
class Responsive {
  /// Standard breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get number of grid columns based on screen size
  static int gridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    return value(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Get horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    return value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);
  }

  /// Get vertical padding based on screen size
  static double verticalPadding(BuildContext context) {
    return value(context, mobile: 16.0, tablet: 20.0, desktop: 24.0);
  }

  /// Get max content width for centered layouts
  static double maxContentWidth(BuildContext context) {
    return value(context, mobile: double.infinity, tablet: 800.0, desktop: 1200.0);
  }

  /// Get card padding based on screen size
  static double cardPadding(BuildContext context) {
    return value(context, mobile: 16.0, tablet: 20.0, desktop: 24.0);
  }

  /// Get font scale factor based on screen size
  static double fontScale(BuildContext context) {
    return value(context, mobile: 1.0, tablet: 1.05, desktop: 1.1);
  }

  /// Get chart height based on screen size
  static double chartHeight(BuildContext context) {
    return value(context, mobile: 220.0, tablet: 280.0, desktop: 320.0);
  }

  /// Get card height based on screen size
  static double cardHeight(BuildContext context) {
    return value(context, mobile: 140.0, tablet: 160.0, desktop: 180.0);
  }

  /// Wrap content with max width constraint for large screens
  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    final width = maxWidth ?? maxContentWidth(context);
    if (width == double.infinity) {
      return child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }

  /// Get adaptive spacing based on screen size
  static double spacing(BuildContext context, {double mobile = 8.0, double tablet = 12.0, double desktop = 16.0}) {
    return value(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Get icon size based on screen size
  static double iconSize(BuildContext context, {double mobile = 24.0, double tablet = 28.0, double desktop = 32.0}) {
    return value(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }
}
