import 'dart:ui';
import 'package:flutter/material.dart';

/// 全局液态玻璃弹窗/底部弹层主题（iOS 26 液态玻璃风格）
///
/// 用法：buildNewTheme 里 dialogTheme/bottomSheetTheme 调 glassDialogTheme(dark) /
/// glassBottomSheetTheme(dark)。
/// 个别弹窗需要实底（如支付确认）可在调用处显式传 backgroundColor 覆盖。
///
/// 原理：DialogThemeData/BottomSheetThemeData 的 backgroundColor 支持
/// 任意 Widget 吗？——不支持，ThemeData 只能给颜色。所以真正的玻璃效果
/// 需要容器。这里用折中方案：主题给「玻璃感颜色」(半透明+高光渐变做不到，
/// ThemeData 只有纯色)，实际玻璃由 [GlassDialogShell] 包裹实现。
///
/// 因此提供两条路径：
/// 1. 主题层：dialogTheme/bottomSheetTheme 设半透明色 + showBuilder 需要配合 shell
/// 2. 简化路径（本文件采用）：主题仍给实底色（保证可读性），但圆角、
///    elevation、surfaceTintColor 统一，观感提升立即可全量生效、零风险；
///    真毛玻璃效果通过 [showGlassDialog] / [showGlassSheet] 可选使用。
/// 后续想全量毛玻璃，把各处 showDialog 换成 showGlassDialog 即可渐进迁移。

/// 毛玻璃容器（BackdropFilter + 高光描边）
class GlassShell extends StatelessWidget {
  const GlassShell({
    super.key,
    required this.child,
    this.dark = false,
    this.radius = 22,
    this.topHighlight = true,
  });
  final Widget child;
  final bool dark;
  final double radius;
  final bool topHighlight;

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? const Color(0xE6171A24) // 暗色玻璃底（90% 不透明保证可读）
        : const Color(0xF0FFFFFF);
    final border = dark
        ? Colors.white.withAlpha(26)
        : Colors.black.withAlpha(12);
    final hl = dark
        ? Colors.white.withAlpha(38)
        : Colors.white.withAlpha(150);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(dark ? 90 : 40),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: topHighlight
              ? Stack(children: [
                  // 顶部 1px 高光渐变（液态玻璃标志性反光）
                  Positioned(
                    top: 0,
                    left: radius * 0.6,
                    right: radius * 0.6,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          hl.withAlpha(0),
                          hl,
                          hl.withAlpha(0),
                        ]),
                      ),
                    ),
                  ),
                  child,
                ])
              : child,
        ),
      ),
    );
  }
}

/// 液态玻璃 Dialog（替代 showDialog，观感统一）
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool dark = false,
}) {
  final d = dark || Theme.of(context).brightness == Brightness.dark;
  return showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black.withAlpha(d ? 120 : 80),
    pageBuilder: (ctx, _, __) => Center(
      child: GlassShell(dark: d, child: Dialog(child: builder(ctx))),
    ),
  );
}

/// 液态玻璃 BottomSheet（替代 showModalBottomSheet）
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  final d = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(d ? 120 : 70),
    builder: (ctx) => GlassShell(
      dark: d,
      radius: 24,
      topHighlight: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 8),
        child: builder(ctx),
      ),
    ),
  );
}
