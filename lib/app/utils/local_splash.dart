import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地开屏图存储
///
/// ★ 需求（用户 #9）：
///   · 用户「我的 → 替换开屏」选过图片 → 启动时走**本地图片**（秒开、不怕断网）
///   · 没选过 → 走**服务器下发的配置开屏图**
///
/// 做法：选图时把图片复制到 App 私有目录，并把路径记在 SharedPreferences。
///       启动时优先读本地文件；文件不存在（被清理/换机）时自动回退服务器配置。
class LocalSplash {
  LocalSplash._();

  static const _kPath = 'local_splash_path';

  /// 保存本地开屏图（sourcePath = 用户选中的图片路径）
  /// 返回保存后的本地路径；失败返回空串
  static Future<String> save(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(sourcePath);
      if (!await f.exists()) return '';
      // 固定文件名，覆盖旧图，避免越攒越多
      final ext = sourcePath.contains('.')
          ? sourcePath.substring(sourcePath.lastIndexOf('.'))
          : '.jpg';
      final target = File('${dir.path}/custom_splash$ext');
      // 先删掉可能存在的其它扩展名旧文件
      for (final e in ['.jpg', '.jpeg', '.png', '.webp']) {
        final old = File('${dir.path}/custom_splash$e');
        if (await old.exists()) {
          try {
            await old.delete();
          } catch (_) {}
        }
      }
      await f.copy(target.path);
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kPath, target.path);
      return target.path;
    } catch (_) {
      return '';
    }
  }

  /// 取本地开屏图路径（不存在返回空串）
  static Future<String> get() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final p = sp.getString(_kPath) ?? '';
      if (p.isEmpty) return '';
      if (await File(p).exists()) return p;
      // 文件已丢失 → 清理记录，回退服务器
      await sp.remove(_kPath);
      return '';
    } catch (_) {
      return '';
    }
  }

  /// 同步版（启动瞬间用，避免闪一下默认图）
  /// 注意：只能在 SharedPreferences 已初始化过一次后调用才可靠，
  /// 所以启动页会 await 异步版。
  static Future<bool> has() async => (await get()).isNotEmpty;

  /// 清除本地开屏图
  static Future<void> clear() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final p = sp.getString(_kPath) ?? '';
      if (p.isNotEmpty) {
        final f = File(p);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      await sp.remove(_kPath);
    } catch (_) {}
  }
}
