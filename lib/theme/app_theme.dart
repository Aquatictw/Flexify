import 'package:flutter/material.dart';

import 'tokens.dart';

/// "Forged iron" — ember-orange seed, vibrant scheme, heavy Manrope type.
const jlSeed = Color(0xFFFF5C1F);

// The old shipped default (deep purple) lives as a Drift column default we
// can't change without a migration, so remap it to the new identity here.
const _oldDefaultSeed = 0xFF673AB7;

/// The seed actually used for a stored setting value.
Color effectiveSeed(int storedSeed) =>
    storedSeed == _oldDefaultSeed ? jlSeed : Color(storedSeed);

ColorScheme jlScheme(int storedSeed, Brightness brightness) =>
    ColorScheme.fromSeed(
      seedColor: effectiveSeed(storedSeed),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );

ThemeData jlTheme(ColorScheme scheme) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Manrope',
  );
  final text = base.textTheme;
  return base.copyWith(
    textTheme: text.copyWith(
      displaySmall:
          text.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: text.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: text.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.25),
      titleLarge:
          text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: text.labelMedium
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      labelSmall: text.labelSmall
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: brMd),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: brSm),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: brPill),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: brSm),
      backgroundColor: scheme.inverseSurface,
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: brLg),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
      ),
      showDragHandle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: brPill),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: brLg),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
