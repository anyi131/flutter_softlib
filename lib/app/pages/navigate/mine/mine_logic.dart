import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/api_host.dart';
import '../../../design/theme_controller.dart';
import '../../../api/soft_service.dart';
import '../../../api/post_service.dart';
import '../../../api/message_service.dart';
import '../../../api/user_service.dart';
import '../../../utils/jump_util.dart';
import '../../../utils/local_splash.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/toast_util.dart';

/// 我的页逻辑：登录态 + 本地资料
class MineLogic extends GetxController {
  static const _kSignDate = 'mine_sign_date';

  final UserService _userService = UserService.instance;

  String nickname = '';
  String uid = '';
  int points = 0;
  String money = '0.00';
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
        money = u.money;
        vipExpire = u.isVip ? u.vipExpire : '';
        avatarUrl = u.avatar;
        isVipMember = u.isVip;
        final sp = await SharedPreferences.getInstance();
        signedDate = sp.getString(_kSignDate) ?? '';
        // 未读消息数（「消息」格子红点）
        messageCount = await MessageService.instance.unread();
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
    money = '0.00';
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

  /// 打开消息中心
  Future<void> openMessages() async {
    if (!isLoggedIn) return openLogin();
    await Get.toNamed(Routes.message);
    // 回来后刷新未读数
    messageCount = await MessageService.instance.unread();
    update();
  }

  /// 充值余额 —— 打开会员中心（复用现有支付通道）
  Future<void> recharge() async {
    if (!isLoggedIn) return openLogin();
    Get.toNamed(Routes.recharge);
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
    try {
      final msg = await _userService.redeem(code);
      await load();
      ToastUtil.success(msg);
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// 切换浅色 / 深色主题
  Future<void> switchTheme() async {
    final tc = ThemeController.instance;
    final next = await Get.dialog<ThemeMode>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.brightness_6_rounded, size: 21, color: Color(0xFF7B8CFF)),
            SizedBox(width: 9),
            Text('外观设置',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(ThemeMode.light, '浅色模式',
                Icons.light_mode_rounded, tc.mode.value == ThemeMode.light),
            _themeOption(ThemeMode.dark, '深色模式', Icons.dark_mode_rounded,
                tc.mode.value == ThemeMode.dark),
            _themeOption(ThemeMode.system, '跟随系统',
                Icons.settings_brightness_rounded,
                tc.mode.value == ThemeMode.system),
          ],
        ),
      ),
    );
    if (next != null) await tc.setMode(next);
  }

  Widget _themeOption(
      ThemeMode m, String label, IconData icon, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => Get.back(result: m),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF5B6CFF).withAlpha(26)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF5B6CFF).withAlpha(120)
                  : Colors.grey.withAlpha(40),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19,
                  color: selected ? const Color(0xFF5B6CFF) : Colors.grey),
              const SizedBox(width: 11),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500)),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 19, color: Color(0xFF5B6CFF)),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开内嵌管理系统（App 内，不跳浏览器）
  void openAdminPanel() {
    Get.toNamed('/admin');
  }

  /// 加入 QQ 通知群
  void joinGroup() {
    final url = _userService.user?.qq.isNotEmpty == true
        ? 'https://qun.qq.com/'
        : ApiHost.base;
    Clipboard.setData(ClipboardData(text: url));
    toast('链接已复制，可在浏览器打开');
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
  Future<void> sponsorRank() async {
    final list = await _userService.donateRank();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 9),
                  const Text('赞助排行榜',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: Get.back),
                ],
              ),
              const SizedBox(height: 6),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text('还没有赞助记录，欢迎成为第一位支持者',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (c, i) {
                      final r = list[i];
                      final rank = int.tryParse('${r['rank']}') ?? (i + 1);
                      final medal = rank == 1
                          ? '🥇'
                          : (rank == 2 ? '🥈' : (rank == 3 ? '🥉' : '$rank'));
                      return ListTile(
                        dense: true,
                        leading: SizedBox(
                          width: 28,
                          child: Center(
                            child: Text('$medal',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        title: Text('${r['nickname']}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        trailing: Text('¥${r['amount']}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFBBF24))),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 积分兑换
  Future<void> pointsExchange() async {
    if (!isLoggedIn) return openLogin();
    final goodsList = await _userService.exchangeGoods();
    final goods = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on_rounded,
                color: Color(0xFFFB923C), size: 21),
            SizedBox(width: 9),
            Text('积分兑换',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前积分：$points',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            for (final g in goodsList)
              _exchangeItem(
                '${g['key']}',
                '${g['name']}',
                int.tryParse('${g['cost']}') ?? 100,
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
        ],
      ),
    );
    if (goods == null) return;
    try {
      final msg = await _userService.exchange(goods);
      await load();
      ToastUtil.success(msg);
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _exchangeItem(String goods, String label, int cost) {
    final enough = points >= cost;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: enough ? () => Get.back(result: goods) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: enough
                ? const Color(0xFFFFF8E6)
                : Colors.grey.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enough
                  ? const Color(0xFFFBBF24).withAlpha(120)
                  : Colors.grey.withAlpha(40),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  size: 18, color: Color(0xFFFBBF24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Text('$cost 积分',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: enough
                          ? const Color(0xFFC9A227)
                          : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  /// 设置自定义称号（广场展示）
  Future<void> setCustomTitle() async {
    if (!isLoggedIn) return openLogin();
    final ctrl = TextEditingController(text: account?.title ?? '');
    final v = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('自定义称号',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              maxLength: 12,
              decoration: const InputDecoration(
                hintText: '如：技术大佬 / 热心网友',
                labelText: '称号',
              ),
            ),
            Text('称号会显示在你的广场动态旁',
                style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: ctrl.text.trim()),
              child: const Text('保存')),
        ],
      ),
    );
    if (v == null) return;
    try {
      await _userService.setTitle(v);
      await load();
      ToastUtil.success(v.isEmpty ? '已清除称号' : '称号已更新');
    } catch (e) {
      toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// 替换开屏（上传自定义开屏图）
  Future<void> replaceSplash() async {
    if (!isLoggedIn) return openLogin();
    final action = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('替换开屏',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          _userService.user?.splashImage.isNotEmpty == true
              ? '当前已设置自定义开屏图'
              : '未设置（使用默认开屏）',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          if (_userService.user?.splashImage.isNotEmpty == true)
            TextButton(
                onPressed: () => Get.back(result: 'reset'),
                child: const Text('恢复默认')),
          TextButton(onPressed: Get.back, child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: 'upload'),
              child: const Text('选择图片')),
        ],
      ),
    );
    if (action == null) return;
    if (action == 'reset') {
      try {
        // ★ 同时清除本地自定义开屏图（否则本地优先还会显示旧图）
        await LocalSplash.clear();
        await _userService.saveSplash('');
        await load();
        ToastUtil.success('已恢复默认开屏');
      } catch (e) {
        ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (picked == null) return;
      // ★ 先存本地（启动时优先用本地图，秒开且不依赖网络）——用户 #9 的要求
      final localPath = await LocalSplash.save(picked.path);
      if (localPath.isEmpty) {
        ToastUtil.error('本地保存失败，请检查存储权限');
      }
      // 再上传服务器（换机/重装后仍能恢复）
      try {
        final up = await PostService.instance.uploadImage(File(picked.path));
        await _userService.saveSplash(up);
      } catch (e) {
        // 上传失败也不影响本地生效
        debugPrint('开屏图上传失败: $e');
      }
      await load();
      ToastUtil.success('开屏图已更新，下次启动生效');
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
