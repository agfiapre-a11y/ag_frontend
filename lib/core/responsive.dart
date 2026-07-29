import 'package:flutter/material.dart';

/// Responsive design helper for adaptive layouts across mobile, tablet, and desktop.
///
/// Breakpoints:
/// - Mobile:  < 600px
/// - Tablet:  600–1024px
/// - Desktop: > 1024px
class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Max content width for large screens to prevent over-stretching.
  static const double maxContentWidth = 1200;

  /// Returns the current screen width.
  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// True if the screen is mobile-sized (< 600px).
  static bool isMobile(BuildContext context) =>
      width(context) < mobileBreakpoint;

  /// True if the screen is tablet-sized (600–1024px).
  static bool isTablet(BuildContext context) =>
      width(context) >= mobileBreakpoint && width(context) < tabletBreakpoint;

  /// True if the screen is desktop-sized (>= 1024px).
  static bool isDesktop(BuildContext context) =>
      width(context) >= tabletBreakpoint;

  /// Returns the appropriate number of grid columns based on screen width.
  ///
  /// [baseCount] is the count used on mobile. It scales up on larger screens.
  /// Override with [mobile], [tablet], and [desktop] for fine control.
  static int gridColumns(
    BuildContext context, {
    int baseCount = 2,
    int? mobile,
    int? tablet,
    int? desktop,
  }) {
    final w = width(context);
    if (w >= desktopBreakpoint) return desktop ?? (baseCount * 3);
    if (w >= tabletBreakpoint) return desktop ?? (baseCount * 2);
    if (w >= mobileBreakpoint) return tablet ?? (baseCount + 1);
    return mobile ?? baseCount;
  }

  /// Returns adaptive stat grid column count.
  /// Mobile: 2, Tablet: 4, Desktop: 6
  static int statGridColumns(BuildContext context) {
    final w = width(context);
    if (w >= desktopBreakpoint) return 6;
    if (w >= tabletBreakpoint) return 4;
    if (w >= mobileBreakpoint) return 4;
    return 2;
  }

  /// Returns adaptive quick-action grid column count.
  /// Mobile: 3, Tablet: 4, Desktop: 6
  static int actionGridColumns(BuildContext context) {
    final w = width(context);
    if (w >= desktopBreakpoint) return 6;
    if (w >= tabletBreakpoint) return 4;
    if (w >= mobileBreakpoint) return 4;
    return 2;
  }

  /// Returns adaptive padding based on screen size.
  static EdgeInsets padding(BuildContext context) {
    final w = width(context);
    if (w >= desktopBreakpoint) return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    if (w >= tabletBreakpoint) return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    if (w >= mobileBreakpoint) return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  /// Returns the appropriate navigation type for the current screen.
  /// - Desktop: permanent drawer
  /// - Tablet/Desktop: permanent drawer
  /// - Mobile: temporary drawer (hamburger menu)
  static bool shouldShowPermanentDrawer(BuildContext context) =>
      width(context) >= tabletBreakpoint;

  /// Wraps content in a centered max-width container for large screens.
  /// On mobile/tablet, returns the child as-is.
  static Widget centerContent(
    BuildContext context,
    Widget child, {
    double maxWidth = maxContentWidth,
  }) {
    final w = width(context);
    if (w <= maxWidth + 32) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Returns adaptive cross-axis spacing for grids.
  static double gridSpacing(BuildContext context) {
    final w = width(context);
    if (w >= tabletBreakpoint) return 16;
    return 12;
  }

  /// Returns adaptive child aspect ratio for stat cards.
  static double statCardAspectRatio(BuildContext context) {
    final w = width(context);
    if (w >= desktopBreakpoint) return 1.2;
    if (w >= tabletBreakpoint) return 1.5;
    return 1.6;
  }
}
