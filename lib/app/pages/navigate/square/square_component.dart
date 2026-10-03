import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// 广场 - 动态卡片流（SonPro 风格复刻）
class SquareComponent extends StatefulWidget {
  const SquareComponent({super.key});

  @override
  State<SquareComponent> createState() => _SquareComponentState();
}

class _SquareComponentState extends State<SquareComponent> {
  /// 示例动态（Phase 2 接入社区 API 后由后端返回）
  final List<_PostItem> _posts = const [
    _PostItem(
      name: '软件库官方',
      time: '10 分钟前',
      content: '欢迎来到广场！分享你的使用心得、软件推荐、技术讨论都可以发在这里～',
      likes: 128,
      comments: 36,
    ),
    _PostItem(
      name: '极客少年',
      time: '1 小时前',
      content: '刚发现一款超好用的下载工具，蓝奏云直链秒下，已分享到软件列表，自取～',
      likes: 56,
      comments: 12,
    ),
    _PostItem(
      name: '咸鱼翻身',
      time: '3 小时前',
      content: '这个界面改版后好看多了，卡片风格很清爽，点赞！',
      likes: 89,
      comments: 21,
    ),
    _PostItem(
      name: '每日一笑',
      time: '昨天',
      content: '程序员的浪漫：代码写完，编译通过，一次跑对 😄',
      likes: 204,
      comments: 45,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('广场', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // 顶部功能入口（SonPro 风格：双卡片）
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: [
                _buildShortcut(
                  context,
                  icon: Icons.edit_note_rounded,
                  title: '写篇文章',
                  subtitle: '创作你的技术分享',
                  gradient: const [Color(0xFF465CFF), Color(0xFF7B8CFF)],
                ),
                const SizedBox(width: 12),
                _buildShortcut(
                  context,
                  icon: Icons.forum_rounded,
                  title: '发个动态',
                  subtitle: '分享你的精彩生活',
                  gradient: const [Color(0xFFFE5F14), Color(0xFFFF9A66)],
                ),
              ],
            ),
          ),
          // 动态卡片流
          ..._posts.map((p) => _buildPostCard(context, p, isDark, scheme)),
        ],
      ),
    );
  }

  /// 快捷操作双卡片
  Widget _buildShortcut(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withAlpha(70),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 动态卡片
  Widget _buildPostCard(
    BuildContext context,
    _PostItem p,
    bool isDark,
    ColorScheme scheme,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户行
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  color: scheme.primaryContainer,
                  alignment: Alignment.center,
                  child: Text(
                    p.name.substring(0, 1),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      p.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 10),
          // 正文
          Text(
            p.content,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark ? Colors.grey[200] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // 互动行
          Row(
            children: [
              _buildAction(Icons.favorite_border, '${p.likes}', scheme),
              const SizedBox(width: 24),
              _buildAction(Icons.chat_bubble_outline, '${p.comments}', scheme),
              const Spacer(),
              Icon(Icons.share_outlined, size: 18, color: Colors.grey[500]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String count, ColorScheme scheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _PostItem {
  final String name;
  final String time;
  final String content;
  final int likes;
  final int comments;

  const _PostItem({
    required this.name,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
  });
}
