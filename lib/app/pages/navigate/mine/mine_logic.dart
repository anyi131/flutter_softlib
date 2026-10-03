import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String signedDate = '';

  int messageCount = 1;
  int followCount = 0;
  int fansCount = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool get isVip {
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
    final sp = await SharedPreferences.getInstance();
    nickname = sp.getString(_kNichname) ?? '';
    uid = sp.getString(_kUid) ?? '';
    points = sp.getInt(_kPoints) ?? 1005;
    vipExpire = sp.getString(_kVipExpire) ?? '';
    avatarPath = sp.getString(_kAvatar) ?? '';
    signedDate = sp.getString(_kSignDate) ?? '';
    if (uid.isEmpty) {
      // 首次进入生成一个演示账号
      uid = (262475940 + DateTime.now().millisecondsSinceEpoch % 100000).toString();
      await sp.setString(_kUid, uid);
    }
    update();
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
