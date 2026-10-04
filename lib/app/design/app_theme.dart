import 'package:flutter/material.dart';

import 'ui.dart';

/// ═══════════════════════════════════════════════════════════════
///  兼容层 —— 仅作转发，禁止在此定义任何新色值 / 新圆角
///
///  唯一真源：design/ui.dart（C / R / Ty / Deco）
///  此文件保留只是为了不破坏历史页面的 import；新代码请直接用 C / R / Ty。
/// ═══════════════════════════════════════════════════════════════

/// 配色（全部转发到 C）
class AppColor {
  AppColor._();

  static const primary = C.brand;
  static const primaryLight = C.brandBright;
  static const primaryDark = C.brandDeep;

  static const accent = C.accentOrange;
  static const success = C.success;
  static const warning = C.warning;
  static const danger = C.danger;
  static const gold = C.gold;

  // 中性色（浅色模式）
  static const bgLight = C.lbg0;
  static const cardLight = Colors.white;
  static const textPrimaryLight = C.lt1;
  static const textSecondaryLight = C.lt2;
  static const textTertiaryLight = C.lt3;
  static const dividerLight = Color(0xFFEFF0F4);

  // 中性色（深色模式）
  static const bgDark = C.bg0;
  static const cardDark = C.bg2;
  static const textPrimaryDark = C.t1;
  static const textSecondaryDark = C.t2;
  static const dividerDark = Color(0xFF262A33);
}

/// 圆角（转发到 R）
class AppRadius {
  AppRadius._();
  static const double sm = R.sm;
  static const double md = R.md;
  static const double lg = R.lg;
  static const double xl = R.xl;
  static const double pill = R.full;
}
