import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra Premium Barber Theme - Antigravity Style
class PremiumBarberTheme {
  // ═══════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════
  
  // Primary Colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFF1E1E1E);
  
  // Accent Colors
  static const Color primary = Color(0xFF00D4FF);     // Turkuaz
  static const Color secondary = Color(0xFFFFD700);   // Altın
  static const Color accent = Color(0xFFFF6B35);      // Turuncu
  
  // Status Colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFD700);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00D4FF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF707070);

  // ═══════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00FF88)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF0D1117), Color(0xFF161B22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════
  
  static List<BoxShadow> glowShadow(Color color, {double blur = 15, double spread = 0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.4),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primary.withOpacity(0.15),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // TEXT STYLES
  // ═══════════════════════════════════════════════════════════
  
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 2,
  );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.5,
  );

  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle get bodyMedium => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle get labelLarge => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primary,
    letterSpacing: 1,
  );

  static TextStyle get buttonText => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.5,
  );

  // ═══════════════════════════════════════════════════════════
  // DECORATIONS
  // ═══════════════════════════════════════════════════════════
  
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: primary.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: cardShadow,
  );

  static BoxDecoration premiumCardDecoration({Color? glowColor}) => BoxDecoration(
    color: surfaceLight.withOpacity(0.8),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: (glowColor ?? primary).withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: glowShadow(glowColor ?? primary),
  );

  // ═══════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════
  
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onError: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineMedium,
      iconTheme: const IconThemeData(color: textPrimary),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primary.withOpacity(0.2)),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: buttonText,
      ),
    ),

    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: buttonText,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: buttonText.copyWith(color: primary),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error),
      ),
      labelStyle: bodyMedium,
      hintStyle: bodyMedium.copyWith(color: textMuted),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 8,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: primary.withOpacity(0.1),
      thickness: 1,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: primary,
      size: 24,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelLarge: labelLarge,
    ),

    // Page Transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceLight,
      contentTextStyle: bodyMedium.copyWith(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: primary.withOpacity(0.2)),
      ),
      titleTextStyle: headlineMedium,
      contentTextStyle: bodyLarge,
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
