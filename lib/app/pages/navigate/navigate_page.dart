import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/toast_util.dart';

import '../../design/ui.dart';
import 'navigate_logic.dart';

/// 主框架：沉浸式底部 Tab（悬浮玻璃胶囊）
class NavigatePage extends StatefulWidget {
  const NavigatePage({super.key});

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage> {
  final NavigateLogic logic = Get.find<NavigateLogic>();

  DateTime? _lastBack;

  /// 返回键：非首页先回首页；首页再按一次弹退出确认
  Future<bool> _onBack() async {
    if (logic.currentIndex != 0) {
      logic.changePage(0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      ToastUtil.info('再按一次退出应用');
      return false;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Color(0xFFFB7185), size: 22),
            SizedBox(width: 9),
            Text('退出应用',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text('确定要退出「安逸软件库」吗？',
            style: TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFB7185)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    return go == true;
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onBack()) SystemNavigator.pop();
      },
      child: Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: logic.pageController,
            children: logic.pages,
          ),
        ],
      ),
      bottomNavigationBar: GetBuilder<NavigateLogic>(
        id: 'navigate',
        builder: (logic) => _bar(context, logic, inset),
      ),
      ),
    );
  }

  Widget _bar(BuildContext context, NavigateLogic logic, double inset) {
    final isDark = context.isDark;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, (inset > 0 ? inset : 10) + 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF141721).withAlpha(215)
                  : Colors.white.withAlpha(240),
              borderRadius: BorderRadius.circular(R.full),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(22)
                    : Colors.black.withAlpha(8),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 110 : 30),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(
                logic.labels.length,
                (i) => Expanded(
                  child: _item(context, logic, i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, NavigateLogic logic, int i) {
    final sel = logic.currentIndex == i;
    final dest = logic.labels[i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => logic.changePage(i),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
              horizontal: sel ? 14 : 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: sel ? Deco.brandGradient : null,
            borderRadius: BorderRadius.circular(R.full),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: C.brand.withAlpha(90),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(
                  size: 21,
                  color: sel ? Colors.white : context.t3,
                ),
                child: (sel ? dest.selectedIcon : dest.icon) ??
                    const SizedBox.shrink(),
              ),
              if (sel) ...[
                const SizedBox(width: 7),
                Text(
                  dest.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
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
