import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/assets.dart';
import '../../../design/adaptive.dart';
import '../../../design/ui.dart';
import '../../../routes/app_pages.dart';
import '../../navigate/navigate_logic.dart';
import 'mine_logic.dart';

/// 我的 —— 沉浸式个人中心
///
/// 结构：
///  ① 头像卡（玻璃 + 极光描边 + 积分/VIP 徽标）
///  ② 数据条（消息/关注/粉丝/签到）
///  ③ 会员横幅（金色渐变，独立视觉重量）
///  ④ 服务宫格（4 列，渐变图标）
///  ⑤ 退出/登录按钮
class MineComponent extends StatelessWidget {
  const MineComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: GetBuilder<MineLogic>(
              init: Get.put(MineLogic(), tag: 'mine'),
              tag: 'mine',
              builder: (logic) {
                return RefreshIndicator(
                  onRefresh: logic.load,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.pagePadding, 12, context.pagePadding, context.tabSpace + 40),
                    children: [
                      _title(context),
                      const SizedBox(height: 16),
                      _profileCard(context, logic),
                      const SizedBox(height: 14),
                      _statsRow(context, logic),
                      const SizedBox(height: 14),
                      _vipBanner(context, logic),
                      const SizedBox(height: 20),
                      _sectionTitle(context, '我的服务'),
                      const SizedBox(height: 10),
                      _serviceGrid(context, logic),
                      const SizedBox(height: 18),
                      _actionButton(context, logic),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Row(
      children: [
        Text('我的', style: Ty.display.copyWith(color: context.t1)),
        const Spacer(),
        GestureDetector(
          onTap: () => Get.find<NavigateLogic>().changePage(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withAlpha(12) : Colors.white,
              borderRadius: BorderRadius.circular(R.full),
              border: Border.all(
                color: context.isDark
                    ? Colors.white.withAlpha(18)
                    : Colors.black.withAlpha(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.home_rounded, size: 14, color: context.t3),
                const SizedBox(width: 5),
                Text('回首页', style: Ty.tiny.copyWith(color: context.t3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────── ① 头像卡 ─────────
  Widget _profileCard(BuildContext context, MineLogic logic) {
    final logged = logic.isLoggedIn;
    return Deco.glass(
      context,
      radius: R.xl,
      alpha: 0.07,
      padding: const EdgeInsets.all(18),
      glow: C.brand,
      child: Row(
        children: [
          // 头像 + 光晕环
          GestureDetector(
            onTap: () =>
                logged ? logic.openProfileEdit() : logic.openLogin(),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: logged ? Deco.goldGradient : Deco.brandGradient,
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.isDark ? C.bg2 : Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: logic.avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logic.avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _defaultAvatar(),
                        errorWidget: (_, __, ___) => _defaultAvatar(),
                      )
                    : _defaultAvatar(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      logged ? logic.openProfileEdit() : logic.openLogin(),
                  child: Text(
                    logic.nickname.isEmpty ? '点击登录' : logic.nickname,
                    style: Ty.h1.copyWith(color: context.t1, fontSize: 21),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        logged ? '账号 ${logic.uid}' : '登录后享受完整功能',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ty.small.copyWith(color: context.t3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: C.brand.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('v1.0.2',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: C.brandBright)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (logged) ...[
                      _badge(context, '积分 ${logic.points}', C.violet),
                      const SizedBox(width: 7),
                    ],
                    _badge(
                      context,
                      logic.isVip ? 'VIP 会员' : '未开通 VIP',
                      logic.isVip ? C.amber : C.t3,
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.t3, size: 22),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => Container(
        color: const Color(0xFFEDF0F7),
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, size: 34, color: C.brandBright),
      );

  Widget _badge(BuildContext context, String text, Color color,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(context.isDark ? 38 : 26),
        borderRadius: BorderRadius.circular(R.full),
        border: Border.all(color: color.withAlpha(80), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ───────── ② 数据条 ─────────
  Widget _statsRow(BuildContext context, MineLogic logic) {
    final items = [
      ('消息', logic.isLoggedIn ? '${logic.messageCount}' : '-',
          Icons.chat_bubble_rounded, C.brandBright),
      ('关注', logic.isLoggedIn ? '${logic.followCount}' : '-',
          Icons.person_add_rounded, C.cyan),
      ('粉丝', logic.isLoggedIn ? '${logic.fansCount}' : '-',
          Icons.groups_rounded, C.mint),
      ('签到', !logic.isLoggedIn
          ? '-'
          : (logic.signedToday ? '已签' : '签到'),
          Icons.verified_rounded, C.amber),
    ];
    return Deco.glass(
      context,
      radius: R.lg,
      alpha: 0.055,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 26,
                color: context.isDark
                    ? Colors.white.withAlpha(14)
                    : Colors.black.withAlpha(8),
              ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!logic.isLoggedIn) {
                    logic.openLogin();
                    return;
                  }
                  if (items[i].$1 == '签到') logic.signIn();
                },
                child: Column(
                  children: [
                    Icon(items[i].$3, size: 19, color: items[i].$4),
                    const SizedBox(height: 7),
                    Text(items[i].$2,
                        style: Ty.h3.copyWith(color: context.t1, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(items[i].$1,
                        style: Ty.tiny.copyWith(color: context.t3)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────── ③ 会员横幅 ─────────
  Widget _vipBanner(BuildContext context, MineLogic logic) {
    return GestureDetector(
      onTap: () =>
          logic.isLoggedIn ? Get.toNamed(Routes.vip) : logic.openLogin(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
        decoration: BoxDecoration(
          gradient: Deco.goldGradient,
          borderRadius: BorderRadius.circular(R.lg),
          boxShadow: [
            BoxShadow(
              color: C.amber.withAlpha(context.isDark ? 60 : 45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFF3A2E10), size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('赞助会员',
                      style: TextStyle(
                          color: Color(0xFF3A2E10),
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    !logic.isLoggedIn
                        ? '登录后可开通会员'
                        : (logic.vipExpire.isEmpty
                            ? '开通享全部特权'
                            : '有效期至 ${logic.vipExpire}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xCC3A2E10), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2410),
                borderRadius: BorderRadius.circular(R.full),
              ),
              child: const Text('立即开通',
                  style: TextStyle(
                      color: Color(0xFFF7D57A),
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── ④ 服务宫格 ─────────
  Widget _sectionTitle(BuildContext context, String t) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: Deco.aurora(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(t, style: Ty.h3.copyWith(color: context.t1, fontSize: 16)),
      ],
    );
  }

  Widget _serviceGrid(BuildContext context, MineLogic logic) {
    final items = <_S>[
      _S('赞助排行', Icons.emoji_events_rounded, C.amber,
          () => logic.sponsorRank()),
      _S('使用卡密', Icons.confirmation_number_rounded, C.rose,
          () => logic.redeem()),
      _S('下载管理', Icons.download_rounded, C.mint,
          () => Get.toNamed(Routes.appDownload)),
      _S('QQ通知群', Icons.forum_rounded, C.cyan, () => logic.joinGroup()),
      _S('积分兑换', Icons.monetization_on_rounded, C.accentOrange,
          () => logic.pointsExchange()),
      _S('关于软件', Icons.info_rounded, C.brandBright,
          () => logic.about(context)),
      _S('用户协议', Icons.description_rounded, C.violet,
          () => logic.showAgreementPage('agreement')),
      _S('隐私政策', Icons.privacy_tip_rounded, C.pink,
          () => logic.showAgreementPage('privacy')),
      _S('外观设置', Icons.brightness_6_rounded, C.brandBright,
          () => logic.switchTheme()),
      _S('替换开屏', Icons.image_rounded, C.mint, () => logic.replaceSplash()),
      if (logic.isAdmin)
        _S('后台管理', Icons.admin_panel_settings_rounded, C.rose,
            () => logic.openAdminPanel()),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withAlpha(14)
            : Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withAlpha(18)
              : Colors.black.withAlpha(8),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i += context.serviceCols)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  for (int j = i; j < i + context.serviceCols; j++)
                    Expanded(
                      child: j < items.length
                          ? _gridCell(context, items[j])
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridCell(BuildContext context, _S s) {
    return GestureDetector(
      onTap: s.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: s.color.withAlpha(context.isDark ? 34 : 24),
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: s.color.withAlpha(60), width: 0.8),
              ),
              child: Icon(s.icon, color: s.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(s.label,
                style: Ty.tiny.copyWith(
                    color: context.t2, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ───────── ⑤ 底部按钮 ─────────
  Widget _actionButton(BuildContext context, MineLogic logic) {
    final logged = logic.isLoggedIn;
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:
              logged ? C.rose.withAlpha(30) : C.brand,
          foregroundColor: logged ? C.rose : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(R.full)),
        ),
        onPressed: () => logged ? logic.logout() : logic.openLogin(),
        child: Text(
          logged ? '退出登录' : '登录 / 注册',
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _S {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _S(this.label, this.icon, this.color, this.onTap);
}
