import 'package:flutter/material.dart';

/// Central place for all app-wide constants.
class AppConstants {
  AppConstants._();

  // ── Environment Toggle ─────────────────────────────────────────────────────
  // Set to 'true' when testing locally in VS Code.
  // Set to 'false' before pushing to GitHub for production!
  static const bool isDevelopment = false;

  // ── Backend URL ────────────────────────────────────────────────────────────
  // The app will automatically choose the correct URL based on the toggle above.
  static const String apiBaseUrl = isDevelopment 
      ? 'http://localhost:8000' // Local testing (change to http://10.0.2.2:8000 for Android Emulator)
      : 'https://activeglow.onrender.com'; // Live production URL

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color brandGreen      = Color(0xFF2ECC8A);   // Primary green
  static const Color brandGreenDark  = Color(0xFF1A9E67);   // Darker green for gradients
  static const Color brandGreenLight = Color(0xFFE8FBF3);   // Tint for user bubble
  static const Color accentTeal      = Color(0xFF00B4D8);
  static const Color scaffoldBg      = Color(0xFFF7F9FC);
  static const Color surfaceColor    = Color(0xFFFFFFFF);
  static const Color textPrimary     = Color(0xFF1A1D23);
  static const Color textSecondary   = Color(0xFF6B7280);
  static const Color dividerColor    = Color(0xFFE5E7EB);

  // Bot bubble
  static const Color botBubbleBg    = Color(0xFFFFFFFF);
  static const Color botBubbleText  = Color(0xFF1A1D23);
  // User bubble
  static const Color userBubbleBg   = Color(0xFF2ECC8A);
  static const Color userBubbleText = Color(0xFFFFFFFF);

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double paddingXS  = 4.0;
  static const double paddingS   = 8.0;
  static const double paddingM   = 16.0;
  static const double paddingL   = 24.0;
  static const double paddingXL  = 32.0;
  static const double radiusM    = 16.0;
  static const double radiusL    = 24.0;

  // ── Typography ─────────────────────────────────────────────────────────────
  static const String fontFamily = 'Inter'; // via google_fonts

  // ── App strings ────────────────────────────────────────────────────────────
  static const String appName         = 'ActiveGlow';
  static const String botName         = 'Skye';
  static const String botSubtitle     = 'Skincare AI Assistant';
  static const String inputHint       = 'Ask Skye about your skin goals…';
  static const String welcomeMessage  =
      "Hi there! 👋 I'm **Skye**, your personal skincare assistant from **ActiveGlow**.\n\n"
      "I'm here to help you find the right products, routines, and tips for your active lifestyle.\n\n"
      "What skin concern can I help you with today?";
}

/// App-wide Material theme.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.brandGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppConstants.scaffoldBg,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppConstants.textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            borderSide: const BorderSide(color: AppConstants.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            borderSide: const BorderSide(color: AppConstants.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            borderSide: const BorderSide(
              color: AppConstants.brandGreen,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingM,
          ),
        ),
      );
}
