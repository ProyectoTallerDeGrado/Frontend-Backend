import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

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
          // Los roles que `fromSeed` inventaría se fijan a la paleta: así ningún
          // componente de Material aparece con un tono ajeno a la marca.
          secondary: AppColors.navy900,
          onSecondary: AppColors.onNavy,
          secondaryContainer: AppColors.blue50,
          onSecondaryContainer: AppColors.blue800,
          tertiary: AppColors.accent,
          onTertiary: AppColors.onNavy,
          primaryContainer: AppColors.blue100,
          onPrimaryContainer: AppColors.blue800,
          errorContainer: AppColors.accentTint,
          onErrorContainer: AppColors.accentOn,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.borderStrong,
          outlineVariant: AppColors.border,
          surfaceTint: Colors.transparent,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.surface,
          surfaceContainer: AppColors.surface,
          surfaceContainerHigh: AppColors.surface,
          surfaceContainerHighest: AppColors.neutralFill,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
    );
    final text = _textTheme(base.textTheme, useGoogleFonts);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      // Android: las rutas de detalle entran con fundido y un leve desplazamiento.
      // iOS conserva su transición nativa (la que usa Flutter por defecto).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onNavy,
          minimumSize: const Size(64, 48),
          shape: controlShape,
          textStyle: text.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
          shape: controlShape,
          textStyle: text.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: text.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.muted),
        border: inputBorder(AppColors.borderStrong),
        enabledBorder: inputBorder(AppColors.borderStrong),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
        disabledBorder: inputBorder(AppColors.border),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.blue50
              : AppColors.surface,
        ),
        checkmarkColor: AppColors.primary,
        labelStyle: text.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.muted,
        textColor: AppColors.ink,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.navy950.withValues(alpha: 0.55),
        dragHandleColor: AppColors.borderStrong,
        dragHandleSize: const Size(44, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppColors.navy950.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        ),
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.45,
          color: AppColors.ink2,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.blue100,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        contentTextStyle: const TextStyle(
          color: AppColors.onNavy,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
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
