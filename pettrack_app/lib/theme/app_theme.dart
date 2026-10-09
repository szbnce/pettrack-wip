import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// PetTrack brand theme.
///
/// Type is bundled (see pubspec `fonts:`) — Plus Jakarta Sans for display and
/// headings, Be Vietnam Pro for reading text — so the app never fetches fonts
/// from the network.
class AppTheme {
  static const String _displayFamily = 'PlusJakartaSans';
  static const String _bodyFamily = 'BeVietnamPro';

  static TextStyle _display(
    double size,
    FontWeight weight,
    Color color, {
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _displayFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing ?? -0.02,
      height: 1.25,
    );
  }

  static TextStyle _body(
    double size,
    FontWeight weight,
    Color color, {
    double? letterSpacing,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme _textTheme({
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    return TextTheme(
      displayLarge: _display(40, FontWeight.w700, onSurface),
      displayMedium: _display(32, FontWeight.w700, onSurface),
      displaySmall: _display(28, FontWeight.w700, onSurface),
      headlineLarge: _display(26, FontWeight.w700, onSurface),
      headlineMedium: _display(24, FontWeight.w600, onSurface),
      headlineSmall: _display(20, FontWeight.w600, onSurface),
      titleLarge: _display(20, FontWeight.w600, onSurface),
      titleMedium: _body(16, FontWeight.w600, onSurface),
      titleSmall: _body(14, FontWeight.w600, onSurface),
      bodyLarge: _body(18, FontWeight.w400, onSurface),
      bodyMedium: _body(16, FontWeight.w400, onSurface),
      bodySmall: _body(14, FontWeight.w400, onSurfaceVariant),
      labelLarge: _body(14, FontWeight.w600, onSurface, letterSpacing: 0.05),
      labelMedium: _body(12, FontWeight.w600, onSurfaceVariant, letterSpacing: 0.05),
      labelSmall: _body(11, FontWeight.w500, onSurfaceVariant, letterSpacing: 0.05),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color primary,
    required Color onPrimary,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    final isDark = brightness == Brightness.dark;
    // The clock and the nav keys are ink too: dark on our light paper, light
    // on the dark one.
    final ink = isDark ? Brightness.light : Brightness.dark;
    final text = _textTheme(
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
    );
    // Soft brand-tinted scrim for buttons pressed states etc.
    final brandAlpha = primary.withValues(alpha: 0.12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: surface,
      fontFamily: _bodyFamily,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: onSurface),
        // Say the glyph tint instead of letting AppBar guess it from its own
        // background colour: the tab shell's bar is `Colors.transparent`, which
        // reads to that guess as pure black, so it asks for white icons over
        // our lightest paper. A bar over a live camera feed declares otherwise.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: ink,
          systemNavigationBarIconBrightness: ink,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHighest : AppColors.surfaceVariant,
        hintStyle: text.bodyMedium?.copyWith(color: onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerHigh : AppColors.onPrimary,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : surface,
        indicatorColor: brandAlpha,
        height: 68,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
          }
          return IconThemeData(color: onSurface);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return text.labelMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            );
          }
          return text.labelMedium;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? scheme.surfaceContainerHigh : AppColors.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? onSurface : AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : AppColors.onPrimary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : AppColors.onPrimary,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: brandAlpha,
        selectedColor: primary,
        labelStyle: text.labelMedium?.copyWith(color: onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: brandAlpha,
        circularTrackColor: brandAlpha,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return isDark ? scheme.outline : AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return scheme.surfaceContainerHighest;
        }),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.labelSmall?.copyWith(color: scheme.surface),
      ),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      tertiary: AppColors.warning,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      surfaceContainerLowest: AppColors.onPrimary,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceVariant,
      surfaceContainerHigh: AppColors.onPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
    );
    return _theme(
      brightness: Brightness.light,
      scheme: scheme,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      secondary: AppColors.darkSecondary,
      tertiary: AppColors.warning,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceVariant,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
    );
    return _theme(
      brightness: Brightness.dark,
      scheme: scheme,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    );
  }
}
