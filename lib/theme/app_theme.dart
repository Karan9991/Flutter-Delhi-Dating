import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color brandDark = Color(0xFF1A1B2E);
  static const Color brandSurface = Color(0xFFFFF5FD);
  static const Color brandError = Color(0xFFFF5CAB);
  static const Color defaultAccent = Color(0xFFFF00FF);

  static ThemeData lightTheme({required Color accent}) {
    final effectiveAccent = _accentForLightUi(accent);
    final secondary = _tint(effectiveAccent, 0.58);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: effectiveAccent,
          brightness: Brightness.light,
          surface: brandSurface,
        ).copyWith(
          primary: effectiveAccent,
          onPrimary: _onColor(effectiveAccent),
          secondary: secondary,
          onSecondary: _onColor(secondary),
          surface: brandSurface,
          onSurface: effectiveAccent,
          error: brandError,
          onError: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.leckerliOne().fontFamily,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F5F2),
      textTheme: GoogleFonts.leckerliOneTextTheme(
        base.textTheme,
      ).apply(bodyColor: effectiveAccent, displayColor: effectiveAccent),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: effectiveAccent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 10,
        shadowColor: brandDark.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: effectiveAccent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: effectiveAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.leckerliOne(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: effectiveAccent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.leckerliOne(
            color: effectiveAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveAccent,
          side: BorderSide(color: effectiveAccent, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: secondary.withValues(alpha: 0.25),
        labelStyle: TextStyle(color: effectiveAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData darkTheme({required Color accent}) {
    const darkSurface = Color(0xFF101225);
    const darkBackground = Color(0xFF090B17);
    const darkCard = Color(0xFF161A2C);

    final effectiveAccent = _accentForDarkUi(accent);
    final secondary = _tint(effectiveAccent, 0.34);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: effectiveAccent,
          brightness: Brightness.dark,
          surface: darkSurface,
        ).copyWith(
          primary: effectiveAccent,
          onPrimary: _onColor(effectiveAccent),
          secondary: secondary,
          onSecondary: _onColor(secondary),
          surface: darkSurface,
          onSurface: effectiveAccent,
          error: brandError,
          onError: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.leckerliOne().fontFamily,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.leckerliOneTextTheme(
        base.textTheme,
      ).apply(bodyColor: effectiveAccent, displayColor: effectiveAccent),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: effectiveAccent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF20253A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: effectiveAccent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkCard,
          foregroundColor: effectiveAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.leckerliOne(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: darkSurface,
        indicatorColor: effectiveAccent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.leckerliOne(
            color: effectiveAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveAccent,
          side: BorderSide(color: effectiveAccent, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF20253A),
        selectedColor: secondary.withValues(alpha: 0.25),
        labelStyle: TextStyle(color: effectiveAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static Color _accentForLightUi(Color color) {
    final hsl = HSLColor.fromColor(_opaque(color));
    final adjusted = hsl
        .withSaturation(hsl.saturation < 0.35 ? 0.35 : hsl.saturation)
        .withLightness(hsl.lightness.clamp(0.18, 0.52));
    return adjusted.toColor();
  }

  static Color _accentForDarkUi(Color color) {
    final hsl = HSLColor.fromColor(_opaque(color));
    final adjusted = hsl
        .withSaturation(hsl.saturation < 0.3 ? 0.3 : hsl.saturation)
        .withLightness(hsl.lightness.clamp(0.58, 0.88));
    return adjusted.toColor();
  }

  static Color _tint(Color color, double amount) {
    final hsl = HSLColor.fromColor(_opaque(color));
    return hsl
        .withLightness(
          (hsl.lightness + (1 - hsl.lightness) * amount).clamp(0, 1),
        )
        .toColor();
  }

  static Color _onColor(Color color) {
    return color.computeLuminance() > 0.48 ? Colors.black : Colors.white;
  }

  static Color _opaque(Color color) {
    return color.withAlpha(0xFF);
  }
}
