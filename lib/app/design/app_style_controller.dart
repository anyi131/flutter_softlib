import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';

/// 界面样式控制器
///
/// 优先级：**用户本地选择** > **后台下发的默认样式**
///
/// ★ 需求 #9：软件管理后台可切换美化风格；
///   同时保留用户在「外观设置」里的个人偏好。
class AppStyleController extends GetxController {
  AppStyleController._();
  static final AppStyleController instance = AppStyleController._();

  static const _kList = 'ui_list_style';
  static const _kDetail = 'ui_detail_style';

  /// 当前列表样式
  final listStyle = AppListStyle.glass.obs;

  /// 当前详情样式
  final detailStyle = AppDetailStyle.standard.obs;

  /// 后台下发的默认值（仅在用户没手动选过时生效）
  String _serverDefault = 'glass';

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  /// 读取本地偏好 + 后台默认
  Future<void> restore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final l = sp.getString(_kList);
      final d = sp.getString(_kDetail);
      if (l != null && l.isNotEmpty) {
        listStyle.value = parseListStyle(l);
      } else {
        listStyle.value = parseListStyle(_serverDefault);
      }
      if (d != null && d.isNotEmpty) {
        detailStyle.value = parseDetailStyle(d);
      }
    } catch (e) {
      debugPrint('[Softlib] style restore: $e');
    }
  }

  /// 应用后台下发的默认样式（用户没手动选过时才生效）
  Future<void> applyServerDefault(String? style) async {
    _serverDefault = (style ?? '').trim().isEmpty ? 'glass' : style!;
    try {
      final sp = await SharedPreferences.getInstance();
      // 用户本地有选择 → 不覆盖
      if ((sp.getString(_kList) ?? '').isNotEmpty) return;
      listStyle.value = parseListStyle(_serverDefault);
    } catch (_) {}
  }

  /// 用户手动切换列表样式
  Future<void> setListStyle(AppListStyle s) async {
    listStyle.value = s;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kList, s.key);
    } catch (_) {}
  }

  /// 用户手动切换详情样式
  Future<void> setDetailStyle(AppDetailStyle s) async {
    detailStyle.value = s;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kDetail, s.name);
    } catch (_) {}
  }
}
