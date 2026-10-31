import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema de la app. Títulos en Sora y cuerpo en DM Sans (ver `design.md` §3.2).
abstract final class AppTheme {
  /// [useGoogleFonts] se desactiva en los tests para no descargar fuentes.
  static ThemeData light({bool useGoogleFonts = true}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onNavy,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.error,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, useGoogleFonts),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        contentTextStyle: const TextStyle(
          color: AppColors.onNavy,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, bool useGoogleFonts) {
    if (!useGoogleFonts) {
      return base.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
    }
    TextStyle? dm(TextStyle? s) => s == null
        ? null
        : GoogleFonts.dmSans(textStyle: s, color: AppColors.ink);
    final body = base.copyWith(
      displayLarge: dm(base.displayLarge),
      displayMedium: dm(base.displayMedium),
      displaySmall: dm(base.displaySmall),
      headlineLarge: dm(base.headlineLarge),
      headlineMedium: dm(base.headlineMedium),
      headlineSmall: dm(base.headlineSmall),
      titleLarge: dm(base.titleLarge),
      titleMedium: dm(base.titleMedium),
      titleSmall: dm(base.titleSmall),
      bodyLarge: dm(base.bodyLarge),
      bodyMedium: dm(base.bodyMedium),
      bodySmall: dm(base.bodySmall),
      labelLarge: dm(base.labelLarge),
      labelMedium: dm(base.labelMedium),
      labelSmall: dm(base.labelSmall),
    );
    TextStyle sora(TextStyle? s, double size, FontWeight w, double spacing) =>
        GoogleFonts.sora(
          textStyle: s,
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          color: AppColors.ink,
        );
    return body.copyWith(
      headlineLarge: sora(body.headlineLarge, 32, FontWeight.w700, -0.64),
      headlineMedium: sora(body.headlineMedium, 26, FontWeight.w700, -0.52),
      titleLarge: sora(body.titleLarge, 22, FontWeight.w700, -0.22),
      titleMedium: sora(body.titleMedium, 18, FontWeight.w600, 0),
    );
  }
}
