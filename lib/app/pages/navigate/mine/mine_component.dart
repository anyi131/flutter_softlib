import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../design/app_theme.dart';
import 'package:get/get.dart';

import '../../../../generated/assets.dart';
import '../../../routes/app_pages.dart';
import '../../navigate/navigate_logic.dart';
import '../../../widgets/tab_bottom_pad.dart';
import 'mine_logic.dart';

/// 我的 - 个人中心（按用户截图复刻：用户信息 / 积分VIP / 统计 / 会员卡 / 服务宫格）
class MineComponent extends StatelessWidget {
  const MineComponent({super.key});
  static const Color kVipGold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColor.bgDark : AppColor.bgLight;
    final cardBg = isDark ? const Color(0xFF222222) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: GetBuilder<MineLogic>(
        init: Get.put(MineLogic(), tag: 'mine'),
        tag: 'mine',
        builder: (logic) {
          return RefreshIndicator(
            onRefresh: logic.load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(context, logic, isDark),
                const SizedBox(height: 12),
                _buildStats(context, logic, cardBg, isDark),
                const SizedBox(height: 12),
                _buildVipBar(context, logic),
                const SizedBox(height: 14),
                _buildServiceGrid(context, logic, cardBg, isDark),
                SizedBox(height: tabBottomPadding(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== 顶部：头像 + 昵称 + 账号 + 积分/改名 =====
  Widget _buildHeader(BuildContext context, MineLogic logic, bool isDark) {
    final light = isDark ? const Color(0xFF222222) : Colors.white;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: light,
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('个人主页',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.grey[500]),
            ],
          ),
          const SizedBox(height: 4),
          Text('欢迎使用安逸软件库',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: [
              // 头像
              GestureDetector(
                onTap: () => logic.isLoggedIn
                    ? logic.openProfileEdit()
                    : logic.openLogin(),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEDEFF5),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: logic.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logic.avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _defaultAvatar(scheme),
                          errorWidget: (_, __, ___) => _defaultAvatar(scheme),
                        )
                      : _defaultAvatar(scheme),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => logic.isLoggedIn
                          ? logic.openProfileEdit()
                          : logic.openLogin(),
                      child: Text(
                        logic.nickname.isEmpty ? '点击登录' : logic.nickname,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      logic.isLoggedIn ? '账号：${logic.uid}' : '登录后享受完整功能',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (logic.isLoggedIn) ...[
                          // 积分胶囊（仅登录后展示）
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '当前积分：${logic.points}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // 会员标识
                        _vipBadge(logic),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => logic.isLoggedIn
                    ? logic.openProfileEdit()
                    : logic.openLogin(),
                child: Text(logic.isLoggedIn ? '编辑' : '登录',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 未登录/无头像时的默认头像（干净的人形图标）
  Widget _defaultAvatar(ColorScheme scheme) {
    return Container(
      color: const Color(0xFFEEF1F8),
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, size: 34, color: scheme.primary.withAlpha(170)),
    );
  }

  Widget _vipBadge(MineLogic logic) {
    final active = logic.isVip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(colors: [Color(0xFF2B2B2B), Color(0xFF4A3E22)])
            : null,
        color: active ? null : const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: 13, color: active ? const Color(0xFFF5D283) : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            active ? 'VIP 会员' : '未开通VIP',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFFF5D283) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 统计行：消息 / 关注 / 粉丝 / 签到 =====
  Widget _buildStats(
      BuildContext context, MineLogic logic, Color cardBg, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _statItem('消息', logic.isLoggedIn ? logic.messageCount.toString() : '-',
              badge: logic.isLoggedIn && logic.messageCount > 0,
              icon: Icons.mark_chat_unread_outlined,
              color: const Color(0xFFEF4444),
              onTap: () => logic.toast('消息中心即将上线')),
          _statItem('关注', logic.isLoggedIn ? logic.followCount.toString() : '-',
              icon: Icons.person_add_alt_outlined,
              color: const Color(0xFFF59E0B),
              onTap: () => logic.toast('关注列表即将上线')),
          _statItem('粉丝', logic.isLoggedIn ? logic.fansCount.toString() : '-',
              icon: Icons.groups_outlined,
              color: const Color(0xFF3B82F6),
              onTap: () => logic.toast('粉丝列表即将上线')),
          _statItem('签到', !logic.isLoggedIn ? '-' : (logic.signedToday ? '✓' : '签到'),
              icon: Icons.check_circle_outline,
              color: const Color(0xFFEF4444),
              onTap: logic.signIn),
        ],
      ),
    );
  }

  Widget _statItem(
    String label,
    String value, {
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool badge = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color),
                if (badge)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('1',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ===== 会员卡横幅（深蓝渐变 + 到期时间 + 续费） =====
  Widget _buildVipBar(BuildContext context, MineLogic logic) {
    return GestureDetector(
      onTap: () => logic.isLoggedIn
          ? Get.toNamed(Routes.vip)
          : logic.openLogin(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B4FE0), Color(0xFF2B36B8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withAlpha(70),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD666), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('赞助会员',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    !logic.isLoggedIn
                        ? '登录后可开通会员'
                        : (logic.vipExpire.isEmpty
                            ? '未开通'
                            : '到期时间 ${logic.vipExpire}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withAlpha(215), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('续费会员',
                  style: TextStyle(
                      color: Color(0xFF2B36B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 服务宫格（四列，两组） =====
  Widget _buildServiceGrid(
      BuildContext context, MineLogic logic, Color cardBg, bool isDark) {
    final items = <_GridItem>[
      _GridItem('赞助排行榜', Icons.emoji_events, const Color(0xFFF59E0B),
          () => logic.toast('赞助排行榜即将上线')),
      _GridItem('使用卡密', Icons.confirmation_number, const Color(0xFFEF4444),
          () => logic.redeem()),
      _GridItem('下载管理', Icons.download_rounded, const Color(0xFF10B981),
          () => Get.toNamed(Routes.appDownload)),
      _GridItem('QQ通知群', Icons.forum, const Color(0xFF22C55E),
          () => logic.joinGroup()),
      _GridItem('积分兑换', Icons.monetization_on_outlined, const Color(0xFFF97316),
          () => logic.toast('积分兑换即将上线')),
      _GridItem('关于软件', Icons.info_outline, const Color(0xFF3B82F6),
          () => logic.about(context)),
      _GridItem('用户协议', Icons.description_outlined, const Color(0xFF0EA5E9),
          () => logic.showAgreementPage('agreement')),
      _GridItem('隐私政策', Icons.privacy_tip_outlined, const Color(0xFFB45309),
          () => logic.showAgreementPage('privacy')),
      _GridItem('替换开屏', Icons.image_outlined, const Color(0xFF8B5CF6),
          () => logic.toast('替换开屏功能即将上线')),
      // ★ 仅管理员可见
      if (logic.isAdmin)
        _GridItem('后台管理', Icons.admin_panel_settings,
            const Color(0xFFDC2626), () => logic.openAdminPanel()),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i += 4)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  for (int j = i; j < i + 4; j++)
                    Expanded(
                      child: j < items.length
                          ? _gridCell(items[j], isDark)
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isDark ? const Color(0xFF1A1A1A) : const Color(0xFF23262B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: BorderSide.none,
                ),
                onPressed: () => logic.isLoggedIn
                    ? logic.logout()
                    : logic.openLogin(),
                child: Text(logic.isLoggedIn ? '退出登录' : '登录 / 注册',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridCell(_GridItem item, bool isDark) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.color.withAlpha(isDark ? 46 : 26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 23),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _GridItem(this.label, this.icon, this.color, this.onTap);
}
