import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

/// 我的 - 个人中心（SonPro 风格复刻）
class MineComponent extends StatefulWidget {
  const MineComponent({super.key});

  @override
  State<MineComponent> createState() => _MineComponentState();
}

class _MineComponentState extends State<MineComponent> {
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
          // 顶部用户卡（品牌色渐变背景）
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF465CFF), Color(0xFF6B7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // 头像
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(128), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person, color: Colors.white, size: 36),
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
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '登录后体验完整功能',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // 登录按钮
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '去登录',
                    style: TextStyle(
                      color: Color(0xFF465CFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 统计行
          Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark
                  ? null
                  : [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
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
          // 功能菜单
          _buildMenuGroup(cardBg, isDark, [
            _MenuItem(Icons.download_rounded, '下载管理', () => Get.toNamed(Routes.appDownload)),
            _MenuItem(Icons.search_rounded, '搜索', () => Get.toNamed(Routes.appSearch)),
            _MenuItem(Icons.article_outlined, '线报文章', null),
            _MenuItem(Icons.star_border_rounded, '我的收藏', null),
            _MenuItem(Icons.settings_outlined, '设置', null),
            _MenuItem(Icons.info_outline, '关于', null),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(Color cardBg, bool isDark, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(i == 0 ? 18 : 0),
                bottom: Radius.circular(i == items.length - 1 ? 18 : 0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 21, color: const Color(0xFF465CFF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        items[i].title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[200] : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              Divider(height: 1, indent: 50, color: isDark ? Colors.white10 : Colors.black.withAlpha(13)),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  const _MenuItem(this.icon, this.title, this.onTap);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF465CFF)),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
