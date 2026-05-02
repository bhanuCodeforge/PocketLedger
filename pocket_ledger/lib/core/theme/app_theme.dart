import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the light and dark ThemeData for PocketLedger.
abstract final class AppTheme {
  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.income,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.incomeLight,
      onTertiaryContainer: const Color(0xFF14532D),
      error: AppColors.expense,
      onError: Colors.white,
      errorContainer: AppColors.expenseLight,
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      shadow: AppColors.lightShadow,
      scrim: AppColors.lightScrim,
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.darkOnSurface,
      inversePrimary: AppColors.primaryLight,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF0C4A6E),
      onSecondaryContainer: const Color(0xFFE0F2FE),
      tertiary: const Color(0xFF4ADE80),
      onTertiary: const Color(0xFF052E16),
      tertiaryContainer: const Color(0xFF14532D),
      onTertiaryContainer: const Color(0xFFDCFCE7),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      shadow: AppColors.darkShadow,
      scrim: AppColors.darkScrim,
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.lightOnSurface,
      inversePrimary: AppColors.primary,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ── Shared builder ─────────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme cs, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: brightness,
      fontFamily: 'Inter',
      textTheme: _buildTextTheme(cs),

      // ── Scaffold / background ─────────────────────────────────────────────
      scaffoldBackgroundColor: isLight
          ? AppColors.lightBackground
          : AppColors.darkBackground,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: cs.onSurface,
        ),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.lightSurface,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.darkSurface,
              ),
      ),

      // ── Bottom navigation ─────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // ── Navigation bar (M3) ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 24);
          }
          return IconThemeData(color: cs.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: cs.primary);
          }
          return AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant);
        }),
        elevation: 3,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? AppColors.lightOutlineVariant : AppColors.darkOutlineVariant,
            width: 1,
          ),
        ),
        color: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // ── Input decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.lightSurfaceVariant : AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight ? AppColors.lightOutline : AppColors.darkOutline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: cs.error),
      ),

      // ── Elevated button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(88, 48),
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(88, 48),
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.lightSurfaceVariant : AppColors.darkSurfaceVariant,
        selectedColor: cs.primaryContainer,
        labelStyle: AppTextStyles.labelMedium,
        side: BorderSide(
          color: isLight ? AppColors.lightOutline : AppColors.darkOutline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: cs.onSurface),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        elevation: 6,
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: isLight ? AppColors.lightOutline : AppColors.darkOutline,
        elevation: 8,
      ),

      // ── List tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
        iconColor: cs.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.lightOutlineVariant : AppColors.darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primaryContainer : cs.surfaceContainerHighest),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primaryContainer,
        circularTrackColor: cs.primaryContainer,
      ),

      // ── Snackbar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: isLight ? Colors.white : const Color(0xFF0F172A),
        ),
        actionTextColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),

      // ── Popup menu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        textStyle: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme cs) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: cs.onSurface),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: cs.onSurface),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: cs.onSurface),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: cs.onSurface),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: cs.onSurface),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: cs.onSurface),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant),
    );
  }
}
