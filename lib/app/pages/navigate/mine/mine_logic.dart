import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/user_service.dart';
import '../../../utils/jump_util.dart';
import '../../../utils/toast_util.dart';

/// 我的页逻辑：本地资料（昵称/账号/积分/签到/会员到期）
class MineLogic extends GetxController {
  static const _kNichname = 'mine_nickname';
  static const _kUid = 'mine_uid';
  static const _kPoints = 'mine_points';
  static const _kSignDate = 'mine_sign_date';
  static const _kVipExpire = 'mine_vip_expire';
  static const _kAvatar = 'mine_avatar';

  String nickname = '';
  String uid = '';
  int points = 1005;
  String vipExpire = '';
  String avatarPath = '';
  /// 网络头像（QQ头像 / 自定义）
  String avatarUrl = '';
  bool isVipMember = false;
  String signedDate = '';

  int messageCount = 1;
  int followCount = 0;
  int fansCount = 0;

  final UserService _userService = UserService.instance;

  /// 已登录用户（为空则未登录）
  UserInfo? get account => _userService.user;
  bool get isLoggedIn => _userService.isLoggedIn;

  /// 是否管理员（仅管理员显示"后台管理"入口）
  bool get isAdmin => _userService.user?.isAdmin == true;

  /// 打开管理后台（Web）
  void openAdminPanel() {
    JumpUtil.openUrl('https://flrjk.52yfx.cn/admin/index.php');
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// 打开登录页，登录成功后刷新
  Future<void> openLogin() async {
    await Get.toNamed('/login');
    await load();
  }

  /// 打开个人资料编辑
  Future<void> openProfileEdit() async {
    if (!isLoggedIn) return openLogin();
    final u = account;
    final nickCtrl = TextEditingController(text: u?.nickname ?? '');
    final qqCtrl = TextEditingController(text: u?.qq ?? '');
    final avatarPreview = ValueNotifier<String>(u?.avatar ?? '');
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('编辑资料'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('修改 QQ 号会自动同步 QQ 头像',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: nickCtrl,
                  maxLength: 20,
                  decoration: const InputDecoration(
                      labelText: '昵称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qqCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'QQ 号', border: OutlineInputBorder()),
                  onChanged: (v) async {
                    if (RegExp(r'^\d{5,12}$').hasMatch(v.trim())) {
                      final url = await _userService.fetchQqAvatar(v.trim());
                      if (url != null) avatarPreview.value = url;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _userService.updateProfile({
        'nickname': nickCtrl.text.trim(),
        'qq': qqCtrl.text.trim(),
      });
      await load();
      ToastUtil.success('资料已更新');
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _userService.logout();
    _clearToGuest();
    update();
    ToastUtil.success('已退出登录');
  }

  bool get isVip {
    if (isVipMember) return true;
    if (vipExpire.isEmpty) return false;
    final d = DateTime.tryParse(vipExpire.replaceAll(' ', 'T'));
    return d != null && d.isAfter(DateTime.now());
  }

  bool get signedToday {
    final today = _today();
    return signedDate == today;
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    await _userService.restore();
    if (_userService.isLoggedIn) {
      final info = await _userService.refreshProfile();
      final u = info ?? _userService.user;
      if (u != null) {
        nickname = u.nickname;
        uid = u.account.isEmpty ? u.id.toString() : u.account;
        points = u.score;
        vipExpire = u.isVip ? u.vipExpire : '';
        avatarUrl = u.avatar;
        isVipMember = u.isVip;
        update();
        return;
      }
    }
    // 未登录：清空为游客态（不展示任何伪造账号/昵称/积分）
    _clearToGuest();
    update();
  }

  /// 重置为游客状态
  void _clearToGuest() {
    nickname = '';
    uid = '';
    points = 0;
    vipExpire = '';
    avatarUrl = '';
    avatarPath = '';
    isVipMember = false;
    signedDate = '';
    followCount = 0;
    fansCount = 0;
    messageCount = 0;
  }

  void toast(String msg) {
    Get.snackbar('提示', msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  /// 改名
  Future<void> rename() async {
    final ctrl = TextEditingController(text: nickname);
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 16,
          decoration: const InputDecoration(hintText: '请输入新昵称'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          FilledButton(
            onPressed: () => Get.back(result: ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    nickname = result;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kNichname, nickname);
    update();
    ToastUtil.success('昵称已修改');
  }

  /// 签到
  Future<void> signIn() async {
    if (!_userService.isLoggedIn) {
      return openLogin();
    }
    if (signedToday) {
      toast('今天已经签到过啦');
      return;
    }
    signedDate = _today();
    points += 10;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSignDate, signedDate);
    await sp.setInt(_kPoints, points);
    update();
    ToastUtil.success('签到成功 +10 积分');
  }

  /// 使用卡密
  Future<void> redeem() async {
    if (!_userService.isLoggedIn) return openLogin();
    final ctrl = TextEditingController();
    final code = await Get.dialog<String>(
      AlertDialog(
        title: const Text('使用卡密'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入卡密'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          FilledButton(
            onPressed: () => Get.back(result: ctrl.text.trim()),
            child: const Text('兑换'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    toast('卡密兑换通道对接中，请联系管理员');
  }

  void pickAvatar() {
    toast('更换头像功能即将上线');
  }

  void joinGroup() {
    Clipboard.setData(const ClipboardData(text: 'https://flrjk.52yfx.cn'));
    toast('已复制官方地址，请前往查看通知群');
  }

  void about(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '安逸软件库',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Copyright © 安逸软件库',
    );
  }

  void showAgreement(String title, String content) {
    Get.dialog(AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('我知道了')),
      ],
    ));
  }
}
