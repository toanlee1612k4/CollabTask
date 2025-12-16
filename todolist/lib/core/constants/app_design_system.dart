import 'package:flutter/material.dart';

/// Modern app colors - Purple/Violet theme (different from Jira blue)
class AppColors {
  // Primary colors - Purple gradient
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5B4FFF);
  static const Color primaryLight = Color(0xFF8B84FF);
  
  // Accent colors
  static const Color accent = Color(0xFF00D9FF); // Teal/Cyan
  static const Color accentDark = Color(0xFF00B8D4);
  
  // Status colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFF9100);
  static const Color error = Color(0xFFFF3D71);
  static const Color info = Color(0xFF00D9FF);
  
  // Task status colors
  static const Color todoColor = Color(0xFF9E9E9E);
  static const Color inProgressColor = Color(0xFF6C63FF);
  static const Color codeReviewColor = Color(0xFFFF9100);
  static const Color doneColor = Color(0xFF00E676);
  
  // Priority colors
  static const Color priorityLow = Color(0xFF81C784);
  static const Color priorityMedium = Color(0xFFFFB74D);
  static const Color priorityHigh = Color(0xFFFF7043);
  static const Color priorityUrgent = Color(0xFFE53935);
  
  // Background colors
  static const Color background = Color(0xFFF8F9FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D2D44);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C6C80);
  static const Color textHint = Color(0xFF9E9EB0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Border colors
  static const Color borderLight = Color(0xFFE0E0E8);
  static const Color borderMedium = Color(0xFFCCCCD6);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
  );
}

/// Responsive breakpoints
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wide = 1600;
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius constants
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

/// Typography scale
class AppTypography {
  static const String fontFamily = 'Inter';
  
  // Font sizes
  static const double displayLarge = 48;
  static const double displayMedium = 36;
  static const double displaySmall = 32;
  
  static const double headlineLarge = 28;
  static const double headlineMedium = 24;
  static const double headlineSmall = 20;
  
  static const double titleLarge = 18;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 10;
}

/// Elevation levels
class AppElevation {
  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
  static const double higher = 12;
}

/// Animation durations
class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
