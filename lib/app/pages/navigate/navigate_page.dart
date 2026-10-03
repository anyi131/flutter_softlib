import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'navigate_logic.dart';

/// 主框架：页面容器 + iOS 风格底部 Tab
class NavigatePage extends StatefulWidget {
  const NavigatePage({super.key});

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage> {
  final NavigateLogic logic = Get.find<NavigateLogic>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    // iOS 底部安全区（全面屏 Home Indicator）
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true, // 内容延伸到 Tab 栏下方（毛玻璃需要）
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: logic.pageController,
        children: logic.pages,
      ),
      bottomNavigationBar: GetBuilder<NavigateLogic>(
        id: 'navigate',
        builder: (logic) {
          return ClipRect(
            child: BackdropFilter(
              // iOS 毛玻璃效果
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: bottomInset > 0 ? bottomInset + 4 : 10,
                  left: 6,
                  right: 6,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                      .withAlpha(isDark ? 235 : 245),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withAlpha(18)
                          : Colors.black.withAlpha(14),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    logic.labels.length,
                    (i) => _tabItem(
                      context,
                      index: i,
                      selected: logic.currentIndex == i,
                      scheme: scheme,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 单个 Tab 项（iOS 风格：图标 + 小字 + 选中高亮）
  Widget _tabItem(
    BuildContext context, {
    required int index,
    required bool selected,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final dest = logic.labels[index];
    final color = selected
        ? scheme.primary
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93));

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: dest.label,
        child: InkWell(
          onTap: () => logic.changePage(index),
          borderRadius: BorderRadius.circular(14),
          splashColor: scheme.primary.withAlpha(20),
          highlightColor: scheme.primary.withAlpha(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary.withAlpha(isDark ? 46 : 30)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconTheme(
                    data: IconThemeData(size: 23, color: color),
                    child: selected ? dest.selectedIcon : dest.icon,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dest.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<NavigateLogic>();
    super.dispose();
  }
}
