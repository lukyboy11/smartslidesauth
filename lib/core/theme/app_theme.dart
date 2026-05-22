import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SmartSlides Design System
/// Teal + white brand palette with light and dark modes

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondary;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color onTertiary;
  final Color onTertiaryContainer;
  final Color error;
  final Color errorContainer;
  final Color onError;
  final Color onErrorContainer;
  final Color surface;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color outline;
  final Color outlineVariant;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixed;
  final Color onSecondaryFixedVariant;
  final Color background;
  final Color onBackground;
  final Color glassBackground;
  final Color glassBorder;

  const AppPalette({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onTertiary,
    required this.onTertiaryContainer,
    required this.error,
    required this.errorContainer,
    required this.onError,
    required this.onErrorContainer,
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.outline,
    required this.outlineVariant,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.background,
    required this.onBackground,
    required this.glassBackground,
    required this.glassBorder,
  });

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? secondaryContainer,
    Color? onSecondary,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? onTertiary,
    Color? onTertiaryContainer,
    Color? error,
    Color? errorContainer,
    Color? onError,
    Color? onErrorContainer,
    Color? surface,
    Color? surfaceDim,
    Color? surfaceBright,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? inverseSurface,
    Color? inverseOnSurface,
    Color? inversePrimary,
    Color? outline,
    Color? outlineVariant,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? background,
    Color? onBackground,
    Color? glassBackground,
    Color? glassBorder,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondary: onSecondary ?? this.onSecondary,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiary: onTertiary ?? this.onTertiary,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onError: onError ?? this.onError,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      onPrimaryFixedVariant:
          onPrimaryFixedVariant ?? this.onPrimaryFixedVariant,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      secondaryFixedDim: secondaryFixedDim ?? this.secondaryFixedDim,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      onSecondaryFixedVariant:
          onSecondaryFixedVariant ?? this.onSecondaryFixedVariant,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSecondaryContainer:
          Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryContainer:
          Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      onTertiaryContainer:
          Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      onErrorContainer:
          Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      surfaceContainerLowest:
          Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(
          surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseOnSurface: Color.lerp(inverseOnSurface, other.inverseOnSurface, t)!,
      inversePrimary: Color.lerp(inversePrimary, other.inversePrimary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      primaryFixedDim: Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      onPrimaryFixedVariant:
          Color.lerp(onPrimaryFixedVariant, other.onPrimaryFixedVariant, t)!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      secondaryFixedDim:
          Color.lerp(secondaryFixedDim, other.secondaryFixedDim, t)!,
      onSecondaryFixed:
          Color.lerp(onSecondaryFixed, other.onSecondaryFixed, t)!,
      onSecondaryFixedVariant: Color.lerp(
          onSecondaryFixedVariant, other.onSecondaryFixedVariant, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

class AppPalettes {
  static const AppPalette light = AppPalette(
    primary: Color(0xFF008E9A),
    primaryContainer: Color(0xFFB2EBF2),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF00363A),
    secondary: Color(0xFF006E78),
    secondaryContainer: Color(0xFF8EE2EA),
    onSecondary: Color(0xFFFFFFFF),
    onSecondaryContainer: Color(0xFF00363A),
    tertiary: Color(0xFF008E9A),
    tertiaryContainer: Color(0xFFE6F7F9),
    onTertiary: Color(0xFF00363A),
    onTertiaryContainer: Color(0xFF00363A),
    error: Color(0xFF008E9A),
    errorContainer: Color(0xFF006E78),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFF2F8F9),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5FBFC),
    surfaceContainer: Color(0xFFEFF7F8),
    surfaceContainerHigh: Color(0xFFE6F3F5),
    surfaceContainerHighest: Color(0xFFDDEFF1),
    surfaceVariant: Color(0xFFDDEFF1),
    onSurface: Color(0xFF0B1F22),
    onSurfaceVariant: Color(0xFF3B5B5F),
    inverseSurface: Color(0xFF003238),
    inverseOnSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF66D0D9),
    outline: Color(0xFF87C8CE),
    outlineVariant: Color(0xFFB9E1E6),
    primaryFixed: Color(0xFF66D0D9),
    primaryFixedDim: Color(0xFF33B8C3),
    onPrimaryFixed: Color(0xFF001C1F),
    onPrimaryFixedVariant: Color(0xFF003238),
    secondaryFixed: Color(0xFF66D0D9),
    secondaryFixedDim: Color(0xFF33B8C3),
    onSecondaryFixed: Color(0xFF001C1F),
    onSecondaryFixedVariant: Color(0xFF003238),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF0B1F22),
    glassBackground: Color(0xCCFFFFFF),
    glassBorder: Color(0x33008E9A),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFF008E9A),
    primaryContainer: Color(0xFF33B8C3),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF008E9A),
    secondaryContainer: Color(0xFF006C74),
    onSecondary: Color(0xFFFFFFFF),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF008E9A),
    tertiaryContainer: Color(0xFFFFFFFF),
    onTertiary: Color(0xFF008E9A),
    onTertiaryContainer: Color(0xFF008E9A),
    error: Color(0xFF008E9A),
    errorContainer: Color(0xFF006C74),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFFFFFFFF),
    surface: Color(0xFF001C1F),
    surfaceDim: Color(0xFF001C1F),
    surfaceBright: Color(0xFF0C3A3F),
    surfaceContainerLowest: Color(0xFF001417),
    surfaceContainerLow: Color(0xFF001F23),
    surfaceContainer: Color(0xFF00272C),
    surfaceContainerHigh: Color(0xFF003238),
    surfaceContainerHighest: Color(0xFF003D44),
    surfaceVariant: Color(0xFF003D44),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFFFFFFFF),
    inverseOnSurface: Color(0xFF00272C),
    inversePrimary: Color(0xFF008E9A),
    outline: Color(0xFF66D0D9),
    outlineVariant: Color(0xFF004B53),
    primaryFixed: Color(0xFF66D0D9),
    primaryFixedDim: Color(0xFF33B8C3),
    onPrimaryFixed: Color(0xFF001C1F),
    onPrimaryFixedVariant: Color(0xFF00272C),
    secondaryFixed: Color(0xFF66D0D9),
    secondaryFixedDim: Color(0xFF33B8C3),
    onSecondaryFixed: Color(0xFF001C1F),
    onSecondaryFixedVariant: Color(0xFF00272C),
    background: Color(0xFF001C1F),
    onBackground: Color(0xFFFFFFFF),
    glassBackground: Color(0xB300272C),
    glassBorder: Color(0x33008E9A),
  );
}

class AppTheme {
  static ThemeData get lightTheme =>
      _buildTheme(AppPalettes.light, Brightness.light);
  static ThemeData get darkTheme =>
      _buildTheme(AppPalettes.dark, Brightness.dark);

  static void applySystemUiForTheme(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      systemUiOverlayStyle(
        isDark ? AppPalettes.dark : AppPalettes.light,
        isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  static ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        primaryContainer: palette.primaryContainer,
        onPrimaryContainer: palette.onPrimaryContainer,
        secondary: palette.secondary,
        onSecondary: palette.onSecondary,
        secondaryContainer: palette.secondaryContainer,
        onSecondaryContainer: palette.onSecondaryContainer,
        tertiary: palette.tertiary,
        onTertiary: palette.onTertiary,
        tertiaryContainer: palette.tertiaryContainer,
        onTertiaryContainer: palette.onTertiaryContainer,
        error: palette.error,
        onError: palette.onError,
        errorContainer: palette.errorContainer,
        onErrorContainer: palette.onErrorContainer,
        surface: palette.surface,
        onSurface: palette.onSurface,
        surfaceContainerHighest: palette.surfaceContainerHighest,
        onSurfaceVariant: palette.onSurfaceVariant,
        outline: palette.outline,
        outlineVariant: palette.outlineVariant,
        shadow: Colors.black,
        scrim: isDark ? Colors.black54 : Colors.black12,
        inverseSurface: palette.inverseSurface,
        onInverseSurface: palette.inverseOnSurface,
        inversePrimary: palette.inversePrimary,
        surfaceTint: palette.primaryFixedDim,
      ),
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: palette.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: palette.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: palette.onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: palette.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: palette.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01,
          color: palette.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: palette.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: palette.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: palette.onSurfaceVariant,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: palette.onSurfaceVariant,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: palette.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: palette.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: palette.onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05,
          color: palette.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        hintStyle: TextStyle(
          color: palette.onSurfaceVariant,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceContainerHigh,
        selectedColor: palette.secondaryContainer,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: palette.onSurfaceVariant,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: palette.onSecondaryContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        side: BorderSide.none,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.onSurface,
          letterSpacing: -0.02,
        ),
        iconTheme: IconThemeData(
          color: palette.onSurfaceVariant,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surfaceContainerLow,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }

  static BoxDecoration glassDecoration(AppPalette palette) {
    return BoxDecoration(
      color: palette.glassBackground,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: palette.glassBorder,
        width: 1,
      ),
    );
  }

  static BoxDecoration primaryButtonGradient(AppPalette palette) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [palette.primary, palette.primaryContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: palette.primary.withOpacity(0.2),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration(AppPalette palette) {
    return BoxDecoration(
      color: palette.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
    );
  }

  static SystemUiOverlayStyle systemUiOverlayStyle(
    AppPalette palette,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: palette.surfaceContainerLow,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }
}

extension ThemeContextExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppPalette get appColors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalettes.dark;
}
