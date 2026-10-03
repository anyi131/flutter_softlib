import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式控制器（浅色 / 深色 / 跟随系统）
class ThemeController extends GetxController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'app_theme_mode';
  final Rx<ThemeMode> mode = ThemeMode.light.obs;

  Future<void> restore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = sp.getString(_key);
      mode.value = switch (v) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
          _key,
          switch (m) {
            ThemeMode.dark => 'dark',
            ThemeMode.system => 'system',
            _ => 'light',
          });
    } catch (_) {}
  }

  String get label => switch (mode.value) {
        ThemeMode.dark => '深色',
        ThemeMode.system => '跟随系统',
        _ => '浅色',
      };
}
