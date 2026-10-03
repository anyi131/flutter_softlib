import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../generated/assets.dart';
import '../../../routes/app_pages.dart';
import '../../navigate/navigate_logic.dart';

/// 我的 - 个人中心（SonPro 风格复刻）
class MineComponent extends StatelessWidget {
  const MineComponent({super.key});

  void _toast(String msg) {
    Get.snackbar('提示', msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Get.theme.colorScheme.surfaceContainerHighest);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF222222) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ===== 品牌渐变头部（吉祥物头像）=====
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF465CFF), Color(0xFF7B8CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                // 吉祥物头像
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    Assets.imagesMascot,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '未登录',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '登录后体验完整功能',
                          style: TextStyle(
                              color: Colors.white.withAlpha(230),
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withAlpha(179)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ===== VIP 会员横幅（SonPro 标志性元素）=====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: InkWell(
              onTap: () => _toast('会员功能即将上线'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F1F1F), Color(0xFF3D3A2E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFFFFD666), size: 30),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('开通会员',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          SizedBox(height: 2),
                          Text('畅享全部特权 · 尽享高速下载',
                              style: TextStyle(
                                  color: Color(0xFFFFD666), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD666), Color(0xFFFFB84D)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('立即开通',
                          style: TextStyle(
                              color: Color(0xFF1F1F1F),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ===== 统计行 =====
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: '0', label: '我的发布'),
                _StatItem(value: '0', label: '我的点赞'),
                _StatItem(value: '0', label: '我的收藏'),
                _StatItem(value: '0', label: '浏览记录'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== 服务功能宫格（全部可点）=====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('我的服务',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87)),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: Row(
              children: [
                _gridItem(context, Icons.rocket_launch_outlined, '我的帖子',
                    () => Get.find<NavigateLogic>().changePage(2)),
                _gridItem(context, Icons.download_rounded, '下载管理',
                    () => Get.toNamed(Routes.appDownload)),
                _gridItem(context, Icons.search_rounded, '搜索',
                    () => Get.toNamed(Routes.appSearch)),
                _gridItem(context, Icons.tips_and_updates_outlined, '线报',
                    () => Get.find<NavigateLogic>().changePage(3)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: Row(
              children: [
                _gridItem(context, Icons.favorite_border_rounded, '我的收藏',
                    () => _toast('收藏功能即将上线')),
                _gridItem(context, Icons.comment_outlined, '我的评论',
                    () => _toast('评论管理即将上线')),
                _gridItem(context, Icons.settings_outlined, '设置',
                    () => _toast('设置页即将上线')),
                _gridItem(context, Icons.info_outline_rounded, '关于',
                    () => showAboutDialog(
                        context: context,
                        applicationName: '软件库 App',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'SonPro 风格开源软件库')),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _gridItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF465CFF), size: 24),
            ),
            const SizedBox(height: 7),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF465CFF))),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
