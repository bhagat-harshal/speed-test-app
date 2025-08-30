import 'package:flutter/material.dart';

@immutable
class NeonTheme extends ThemeExtension<NeonTheme> {
  final Color ringTrack;
  final Color cardOutline;
  final Color glow;

  const NeonTheme({
    required this.ringTrack,
    required this.cardOutline,
    required this.glow,
  });

  @override
  NeonTheme copyWith({
    Color? ringTrack,
    Color? cardOutline,
    Color? glow,
  }) {
    return NeonTheme(
      ringTrack: ringTrack ?? this.ringTrack,
      cardOutline: cardOutline ?? this.cardOutline,
      glow: glow ?? this.glow,
    );
  }

  @override
  ThemeExtension<NeonTheme> lerp(ThemeExtension<NeonTheme>? other, double t) {
    if (other is! NeonTheme) return this;
    return NeonTheme(
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
      cardOutline: Color.lerp(cardOutline, other.cardOutline, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

class AppTheme {
  // Dark neon theme inspired by the provided design
  static ThemeData dark() {
    const accent = Color(0xFF21E6C1); // neon teal
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF121826), // cards/surfaces
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B101B),

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0B101B),
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF111827),
        selectedItemColor: scheme.primary,
        unselectedItemColor: Colors.white.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withValues(alpha: 0.08)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
        space: 0,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),

      iconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.9)),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface.withValues(alpha: 0.9),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          hoverColor: scheme.primary.withValues(alpha: 0.08),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        bodySmall: TextStyle(color: Color(0xFF9AA3B2)),
      ),

      // Extra colors used by custom widgets like the circular gauge ring track, outlines, etc.
      extensions: const <ThemeExtension<dynamic>>[
        NeonTheme(
          ringTrack: Color(0xFF233042),
          cardOutline: Color(0xFF2A3A4E),
          glow: Color(0x8021E6C1),
        ),
      ],
    );
  }
}
