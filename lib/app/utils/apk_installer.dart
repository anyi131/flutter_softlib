import 'dart:io';

import 'package:flutter/services.dart';

/// 调用系统安装器安装 APK
///
/// 说明：open_filex 走的是通用「查看文件」意图，系统会弹「打开方式」选择器。
/// 这里改用原生 PackageInstaller 意图，只有真正的安装器能响应。
class ApkInstaller {
  ApkInstaller._();

  static const MethodChannel _ch = MethodChannel('softlib/installer');

  /// 是否已获得「安装未知应用」权限
  static Future<bool> canInstall() async {
    if (!Platform.isAndroid) return true;
    try {
      final ok = await _ch.invokeMethod<bool>('canRequestPackageInstalls');
      return ok ?? true;
    } catch (_) {
      return true;
    }
  }

  /// 打开系统「安装未知应用」权限设置页
  static Future<void> openInstallSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  /// 安装 APK（返回是否成功唤起安装器）
  static Future<bool> install(String path) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _ch.invokeMethod<bool>('installApk', {'path': path});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
