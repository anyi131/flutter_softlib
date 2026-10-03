import 'package:flutter/material.dart';

/// 全局设计系统（配色 + 圆角 + 阴影 + 间距）
class AppColor {
  AppColor._();

  // 主色：品牌蓝紫
  static const primary = Color(0xFF4B5EF5);
  static const primaryLight = Color(0xFF6E7DFF);
  static const primaryDark = Color(0xFF3A4BD8);

  // 强调色
  static const accent = Color(0xFFFF6B35);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFFC9A227);

  // 中性色（浅色模式）
  static const bgLight = Color(0xFFF4F5F9);
  static const cardLight = Colors.white;
  static const textPrimaryLight = Color(0xFF1A1D26);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textTertiaryLight = Color(0xFF9CA3AF);
  static const dividerLight = Color(0xFFEFF0F4);

  // 中性色（深色模式）
  static const bgDark = Color(0xFF0F1115);
  static const cardDark = Color(0xFF1A1D23);
  static const textPrimaryDark = Color(0xFFF3F4F6);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const dividerDark = Color(0xFF262A33);
}

/// 圆角
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double pill = 999;
}

/// 间距
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
}

/// 常用装饰
class AppDeco {
  AppDeco._();

  /// 卡片（浅色/深色自适应）
  static BoxDecoration card(BuildContext context,
      {double radius = AppRadius.lg}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColor.cardDark : AppColor.cardLight,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: const Color(0xFF1A1D26).withAlpha(16),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  /// 主色渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColor.primaryLight, AppColor.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 金色渐变（会员）
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF3A3226), Color(0xFF241F18)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 主色阴影
  static List<BoxShadow> primaryShadow(BuildContext context) => [
        BoxShadow(
          color: AppColor.primary
              .withAlpha(Theme.of(context).brightness == Brightness.dark ? 55 : 38),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];
}

/// 文字样式快捷方法
extension AppText on BuildContext {
  bool get _dark => Theme.of(this).brightness == Brightness.dark;
  TextStyle get t1 => const TextStyle(
      fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6, height: 1.2);
  TextStyle get t2 => const TextStyle(
      fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.25);
  TextStyle get t3 =>
      const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.2);
  TextStyle get tbody => TextStyle(
      fontSize: 14,
      height: 1.6,
      color: _dark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight);
  TextStyle get tsub => TextStyle(
      fontSize: 12.5,
      color: _dark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight);
  TextStyle get ttiny => TextStyle(
      fontSize: 11,
      color: _dark ? AppColor.textSecondaryDark : AppColor.textTertiaryLight);
}

/// 主题构建
ThemeData buildAppTheme({required bool dark}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColor.primary,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColor.primary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark ? AppColor.bgDark : AppColor.bgLight,
    cardColor: dark ? AppColor.cardDark : AppColor.cardLight,
    dividerColor: dark ? AppColor.dividerDark : AppColor.dividerLight,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: dark ? AppColor.bgDark : AppColor.bgLight,
      foregroundColor:
          dark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: dark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColor.primary,
        side: BorderSide(color: AppColor.primary.withAlpha(80)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF23262E) : const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFF4B5EF5), width: 1.5),
      ),
      hintStyle: TextStyle(
        fontSize: 13.5,
        color: dark ? AppColor.textSecondaryDark : AppColor.textTertiaryLight,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColor.primary,
      labelColor: AppColor.primary,
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      unselectedLabelStyle:
          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      backgroundColor: dark ? AppColor.cardDark : Colors.white,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? AppColor.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      side: BorderSide.none,
    ),
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
