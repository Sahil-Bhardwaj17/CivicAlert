import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF1A73E8);       // Civic Blue
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4A9EF5);

  // Secondary - Alert Red
  static const Color secondary = Color(0xFFE53935);
  static const Color secondaryDark = Color(0xFFC62828);
  static const Color secondaryLight = Color(0xFFEF5350);

  // Accent - Safety Green
  static const Color accent = Color(0xFF00C853);
  static const Color accentDark = Color(0xFF00952C);
  static const Color accentLight = Color(0xFF5EFF9E);

  // Warning Orange
  static const Color warning = Color(0xFFFB8C00);
  static const Color warningLight = Color(0xFFFFCC80);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFAFBFE);

  // Text
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF5F6B7A);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Severity Colors
  static const Color severityLow = Color(0xFF4CAF50);     // Green
  static const Color severityMedium = Color(0xFFFF9800);  // Orange
  static const Color severityHigh = Color(0xFFF44336);    // Red
  static const Color severityCritical = Color(0xFF9C27B0);// Purple

  // Status Colors
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusInProgress = Color(0xFF2196F3);
  static const Color statusResolved = Color(0xFF4CAF50);
  static const Color statusRejected = Color(0xFFF44336);

  // Disaster Alert Colors
  static const Color alertFlood = Color(0xFF0288D1);
  static const Color alertStorm = Color(0xFF6A1B9A);
  static const Color alertFire = Color(0xFFD84315);
  static const Color alertEarthquake = Color(0xFF5D4037);

  // Divider & Border
  static const Color divider = Color(0xFFE8EDF2);
  static const Color border = Color(0xFFD1D9E0);
  static const Color borderFocused = Color(0xFF1A73E8);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);

  // Map Colors
  static const Color mapMarkerRoad = Color(0xFFFF6F00);
  static const Color mapMarkerDisaster = Color(0xFFD32F2F);
  static const Color mapSafeZone = Color(0xFF388E3C);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFF880E4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1A73E8), Color(0xFF42A5F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
