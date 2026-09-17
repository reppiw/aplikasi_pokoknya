import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Neo-Brutalism Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

abstract final class NeoColors {
  /// Cream canvas — used at partial opacity over the background image.
  static const cream         = Color(0xFFFFFDF5);
  static const creemOverlay  = Color(0xD9FFFDF5); // ~85% opacity
  static const ink           = Color(0xFF000000);
  static const accent        = Color(0xFFFF6B6B); // Hot Red
  static const secondary     = Color(0xFFFFD93D); // Vivid Yellow
  static const muted         = Color(0xFFC4B5FD); // Soft Violet
  static const white         = Color(0xFFFFFFFF);

  /// Semi-transparent cream for card surfaces on top of the BG image.
  static const cardSurface   = Color(0xCCFFFDF5); // ~80% opacity cream

  /// Lighter card for inner elements.
  static const cardInner     = Color(0xF2FFFFFF); // ~95% white
}

abstract final class NeoShadows {
  static const small  = BoxShadow(color: NeoColors.ink, offset: Offset(4, 4));
  static const medium = BoxShadow(color: NeoColors.ink, offset: Offset(6, 6));
  static const large  = BoxShadow(color: NeoColors.ink, offset: Offset(8, 8));
  static const massive= BoxShadow(color: NeoColors.ink, offset: Offset(12, 12));

  static List<BoxShadow> get s   => const [small];
  static List<BoxShadow> get m   => const [medium];
  static List<BoxShadow> get l   => const [large];
  static List<BoxShadow> get xl  => const [massive];
}

abstract final class NeoRadius {
  static const none = BorderRadius.zero;
  static const full = BorderRadius.all(Radius.circular(999));
}

abstract final class NeoBorder {
  static const Border thick  = Border.fromBorderSide(BorderSide(color: NeoColors.ink, width: 4));
  static const Border thin   = Border.fromBorderSide(BorderSide(color: NeoColors.ink, width: 2));
  static const Border xthick = Border.fromBorderSide(BorderSide(color: NeoColors.ink, width: 6));
}

abstract final class NeoTextStyles {
  static const _family = 'SpaceGrotesk';

  /// Hero / display — outline effect via foreground paint
  static const display = TextStyle(
    fontFamily:  _family,
    fontSize:    72,
    fontWeight:  FontWeight.w900,
    color:       NeoColors.ink,
    letterSpacing: -2,
    height: 0.9,
  );

  static const h1 = TextStyle(
    fontFamily:  _family,
    fontSize:    48,
    fontWeight:  FontWeight.w900,
    color:       NeoColors.ink,
    letterSpacing: -1,
    height: 1.0,
  );

  static const h2 = TextStyle(
    fontFamily:  _family,
    fontSize:    32,
    fontWeight:  FontWeight.w900,
    color:       NeoColors.ink,
    letterSpacing: -0.5,
  );

  static const h3 = TextStyle(
    fontFamily:  _family,
    fontSize:    22,
    fontWeight:  FontWeight.w900,
    color:       NeoColors.ink,
    letterSpacing: 0,
  );

  static const bodyLarge = TextStyle(
    fontFamily:  _family,
    fontSize:    18,
    fontWeight:  FontWeight.w700,
    color:       NeoColors.ink,
  );

  static const body = TextStyle(
    fontFamily:  _family,
    fontSize:    15,
    fontWeight:  FontWeight.w700,
    color:       NeoColors.ink,
  );

  static const label = TextStyle(
    fontFamily:   _family,
    fontSize:     12,
    fontWeight:   FontWeight.w700,
    color:        NeoColors.ink,
    letterSpacing: 2.5,
  );

  static const button = TextStyle(
    fontFamily:   _family,
    fontSize:     14,
    fontWeight:   FontWeight.w900,
    color:        NeoColors.ink,
    letterSpacing: 1.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3:  true,
      fontFamily:    'SpaceGrotesk',
      scaffoldBackgroundColor: NeoColors.cream,
      colorScheme: ColorScheme.light(
        primary:    NeoColors.accent,
        secondary:  NeoColors.secondary,
        tertiary:   NeoColors.muted,
        surface:    NeoColors.cream,
        onPrimary:  NeoColors.ink,
        onSurface:  NeoColors.ink,
      ),

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:   NeoColors.cream,
        foregroundColor:   NeoColors.ink,
        elevation:         0,
        titleTextStyle:    NeoTextStyles.h3,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Text ──────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:  NeoTextStyles.display,
        headlineLarge: NeoTextStyles.h1,
        headlineMedium:NeoTextStyles.h2,
        headlineSmall: NeoTextStyles.h3,
        bodyLarge:     NeoTextStyles.bodyLarge,
        bodyMedium:    NeoTextStyles.body,
        labelLarge:    NeoTextStyles.button,
        labelSmall:    NeoTextStyles.label,
      ),

      // ── ElevatedButton → primary button ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  NeoColors.accent,
          foregroundColor:  NeoColors.white,
          elevation:        0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: const BorderSide(color: NeoColors.ink, width: 4),
          textStyle:        NeoTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
        ),
      ),

      // ── OutlinedButton → secondary ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor:  NeoColors.secondary,
          foregroundColor:  NeoColors.ink,
          elevation:        0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: const BorderSide(color: NeoColors.ink, width: 4),
          textStyle:        NeoTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NeoColors.ink,
          textStyle:       NeoTextStyles.button,
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   NeoColors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:   BorderSide(color: NeoColors.ink, width: 4),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:   BorderSide(color: NeoColors.ink, width: 4),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:   BorderSide(color: NeoColors.ink, width: 4),
        ),
        hintStyle:  NeoTextStyles.body.copyWith(
          color: NeoColors.ink.withValues(alpha: 0.35),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  NeoColors.cream,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: NeoColors.ink, width: 4),
        ),
        elevation: 0,
        titleTextStyle: NeoTextStyles.h3,
        contentTextStyle: NeoTextStyles.body,
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     NeoColors.ink,
        thickness: 2,
        space:     0,
      ),
    );
  }
}
