import 'package:flutter/material.dart';

/// Centralized app colors for consistent theming throughout the application
class AppColors {
  AppColors._();

  // Primary Colors - Indigo/Purple Theme
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFFE0E7FF);

  // Secondary Colors - Emerald/Green
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryContainer = Color(0xFFD1FAE5);

  // Tertiary Colors - Amber/Orange
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryLight = Color(0xFFFBBF24);
  static const Color tertiaryContainer = Color(0xFFFEF3C7);

  // Error Colors - Red
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Surface & Background Colors - Premium purple tint
  static const Color surface = Color(0xFFFAFAFF);
  static const Color surfaceContainer = Color(0xFFF0F0FF);
  static const Color scaffoldBackground = Color(0xFFF5F5FF);
  
  // Card Background - Slight purple tint
  static const Color cardBackground = Color(0xFFFAFAFF);
  static const Color cardBackgroundElevated = Color(0xFFFCFCFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [surfaceContainer, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF8F8FF), cardBackground],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Colors (for drug categories)
  static const Color bronchodilator = Color(0xFF3B82F6);   // Blue
  static const Color corticosteroid = Color(0xFFF59E0B);   // Amber
  static const Color anticholinergic = Color(0xFF14B8A6);  // Teal
  static const Color leukotrieneModifier = Color(0xFF8B5CF6); // Purple
  static const Color antihistamine = Color(0xFFEC4899);    // Pink
  static const Color mucolytic = Color(0xFF10B981);        // Green
  static const Color combination = Color(0xFF6366F1);      // Indigo
  static const Color antibiotic = Color(0xFFEF4444);       // Red
  static const Color antifibrotic = Color(0xFF78716C);     // Stone

  // Status Colors  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color pending = Color(0xFFF59E0B);
  static const Color taken = Color(0xFF10B981);
  static const Color missed = Color(0xFFEF4444);
}
