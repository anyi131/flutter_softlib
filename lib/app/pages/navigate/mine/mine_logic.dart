import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/api_host.dart';
import '../../../api/soft_service.dart';
import '../../../api/user_service.dart';
import '../../../utils/jump_util.dart';
import '../../../utils/toast_util.dart';

/// 我的页逻辑：登录态 + 本地资料
class MineLogic extends GetxController {
  static const _kSignDate = 'mine_sign_date';

  final UserService _userService = UserService.instance;

  String nickname = '';
  String uid = '';
  int points = 0;
  String vipExpire = '';
  String avatarUrl = '';
  bool isVipMember = false;
  String signedDate = '';

  int messageCount = 0;
  int followCount = 0;
  int fansCount = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool get isLoggedIn => _userService.isLoggedIn;
  bool get isAdmin => _userService.user?.isAdmin == true;
  UserInfo? get account => _userService.user;

  bool get isVip {
    if (isVipMember) return true;
    if (vipExpire.isEmpty) return false;
    final d = DateTime.tryParse(vipExpire.replaceAll(' ', 'T'));
    return d != null && d.isAfter(DateTime.now());
  }

  bool get signedToday => signedDate == _today();

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
        final sp = await SharedPreferences.getInstance();
        signedDate = sp.getString(_kSignDate) ?? '';
        update();
        return;
      }
    }
    _clearToGuest();
    update();
  }

  /// 重置为游客状态（不展示任何伪造数据）
  void _clearToGuest() {
    nickname = '';
    uid = '';
    points = 0;
    vipExpire = '';
    avatarUrl = '';
    isVipMember = false;
    signedDate = '';
    followCount = 0;
    fansCount = 0;
    messageCount = 0;
  }

  /// 轻提示（用 SnackBar，避免 iOS 底部弹窗遮挡按钮）
  void toast(String msg) {
    ToastUtil.info(msg);
  }

  Future<void> openLogin() async {
    await Get.toNamed('/login');
    await load();
  }

  Future<void> openRegister() async {
    await Get.toNamed('/register');
    await load();
  }

  /// 编辑资料（昵称 + QQ，改 QQ 自动同步头像）
  Future<void> openProfileEdit() async {
    if (!isLoggedIn) return openLogin();
    final u = account;
    final nickCtrl = TextEditingController(text: u?.nickname ?? '');
    final qqCtrl = TextEditingController(text: u?.qq ?? '');
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
                const SizedBox(height: 4),
                TextField(
                  controller: qqCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'QQ 号', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('保存')),
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
      toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// 退出登录
  Future<void> logout() async {
    final yes = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('退出')),
        ],
      ),
    );
    if (yes != true) return;
    await _userService.logout();
    _clearToGuest();
    update();
    ToastUtil.success('已退出登录');
  }

  /// 签到 +5（后端落库，每天一次）
  Future<void> signIn() async {
    if (!isLoggedIn) return openLogin();
    if (signedToday) return toast('今天已经签到过啦');
    try {
      final score = await _userService.signIn();
      signedDate = _today();
      points = score;
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kSignDate, signedDate);
      update();
      ToastUtil.success('签到成功 +5 积分');
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// 使用卡密
  Future<void> redeem() async {
    if (!isLoggedIn) return openLogin();
    final ctrl = TextEditingController();
    final code = await Get.dialog<String>(
      AlertDialog(
        title: const Text('使用卡密'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: '请输入卡密', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: ctrl.text.trim()),
              child: const Text('兑换')),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    toast('卡密兑换通道对接中，请联系管理员');
  }

  /// 打开内嵌管理系统（App 内，不跳浏览器）
  void openAdminPanel() {
    Get.toNamed('/admin');
  }

  /// 加入 QQ 通知群
  void joinGroup() {
    const url = ApiHost.base;
    Clipboard.setData(ClipboardData(text: url));
    toast('官方地址已复制：$url');
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
      content: SingleChildScrollView(child: Text(content, style: const TextStyle(height: 1.7))),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('我知道了')),
      ],
    ));
  }

  /// 用户协议（后台可配）
  Future<void> showAgreementPage(String type) async {
    final cfg = await SoftService.instance.fetchConfig();
    final isPrivacy = type == 'privacy';
    final title = isPrivacy ? '隐私政策' : '用户协议';
    final content = isPrivacy
        ? (cfg?.privacy ?? '')
        : (cfg?.agreement ?? '');
    Get.dialog(AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          content.isEmpty ? '$title 内容待管理员在后台配置。' : content,
          style: const TextStyle(height: 1.7, fontSize: 14),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('我知道了')),
      ],
    ));
  }

  /// 赞助排行榜
  void sponsorRank() => toast('赞助排行榜即将上线');

  /// 积分兑换
  void pointsExchange() => toast('积分兑换即将上线');

  /// 替换开屏
  void replaceSplash() => toast('替换开屏功能即将上线');
}
