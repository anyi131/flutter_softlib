import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/app_item.dart';

/// 软件卡片（现代圆角卡片风格）
class AppCard extends StatelessWidget {
  final AppItem item;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 图标
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: item.icon.isEmpty
                      ? _placeholder(scheme)
                      : CachedNetworkImage(
                          imageUrl: item.icon,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(scheme),
                          errorWidget: (_, __, ___) => _placeholder(scheme),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title.isEmpty ? '未知应用' : item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _sourceTag(scheme),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (item.size.isNotEmpty) ...[
                            Icon(Icons.data_usage,
                                size: 13, color: scheme.primary.withAlpha(150)),
                            const SizedBox(width: 3),
                            Text(
                              item.size,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (item.version.isNotEmpty)
                            Text(
                              item.version,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '查看',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: 56,
      height: 56,
      color: scheme.primaryContainer.withAlpha(120),
      child: Icon(Icons.android, color: scheme.primary, size: 28),
    );
  }

  /// 来源标记：蓝奏云 / 服务器
  Widget _sourceTag(ColorScheme scheme) {
    final isLocal = item.isLocal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isLocal
            ? const Color(0xFFDBEAFE)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLocal ? '服务器' : '蓝奏云',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isLocal ? const Color(0xFF1D4ED8) : const Color(0xFFB45309),
        ),
      ),
    );
  }
}
