/// App-wide constants
class AppConstants {
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  
  // Touch targets (WCAG AA)
  static const double minTouchTarget = 48.0;
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
  
  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXl = 48.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Grid
  static const int gridCrossAxisCountMobile = 1;
  static const int gridCrossAxisCountTablet = 2;
  static const int gridCrossAxisCountDesktop = 3;
}

/// Screen size helper
enum ScreenSize { mobile, tablet, desktop }

ScreenSize getScreenSize(double width) {
  if (width < AppConstants.mobileBreakpoint) {
    return ScreenSize.mobile;
  } else if (width < AppConstants.tabletBreakpoint) {
    return ScreenSize.tablet;
  }
  return ScreenSize.desktop;
}

int getGridCrossAxisCount(ScreenSize size) {
  switch (size) {
    case ScreenSize.mobile:
      return AppConstants.gridCrossAxisCountMobile;
    case ScreenSize.tablet:
      return AppConstants.gridCrossAxisCountTablet;
    case ScreenSize.desktop:
      return AppConstants.gridCrossAxisCountDesktop;
  }
}
