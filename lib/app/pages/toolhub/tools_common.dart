import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';

/// 工具页通用外壳（统一视觉规范）
///
/// ★ 复刻样本 App：每个工具都是独立的 App 内页面（不跳浏览器）
class ToolScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottom;
  final bool scroll;
  final List<Widget>? actions;

  const ToolScaffold({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.children,
    this.bottom,
    this.scroll = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final content = scroll
        ? ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(context.pagePadding, 4,
                context.pagePadding, (bottom != null ? 80 : 0) + 30),
            children: children,
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(
                context.pagePadding, 4, context.pagePadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _bar(context),
                Expanded(child: content),
                if (bottom != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.pagePadding, 8,
                        context.pagePadding, context.safeBottom + 14),
                    child: bottom,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(context.pagePadding, 10, context.pagePadding, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    context.isDark ? Colors.white.withAlpha(14) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(8),
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: context.t1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.h2.copyWith(fontSize: 19, color: context.t1)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: Ty.tiny.copyWith(color: context.t3)),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// 工具内的分区卡片（标题 + 内容）
class ToolCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Widget? trailing;
  const ToolCard({
    super.key,
    this.title = '',
    this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return KitCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: C.brand.withAlpha(context.isDark ? 40 : 24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: C.brand),
                  ),
                  const SizedBox(width: 9),
                ],
                Text(title,
                    style: Ty.h3.copyWith(fontSize: 14, color: context.t1)),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// 工具内的主操作按钮
class ToolButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool loading;
  const ToolButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.brand;
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: Material(
        color: onPressed == null ? context.t3.withAlpha(50) : c,
        borderRadius: BorderRadius.circular(R.full),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(R.full),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 17, color: Colors.white),
                        const SizedBox(width: 7),
                      ],
                      Text(label,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 工具内输入框
class ToolField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboard;
  const ToolField({
    super.key,
    required this.controller,
    this.hint = '',
    this.maxLines = 1,
    this.onChanged,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14, color: context.t1),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md)),
      ),
    );
  }
}

/// 工具结果展示框（可复制）
class ToolResult extends StatelessWidget {
  final String title;
  final String content;
  final Color? color;
  const ToolResult({
    super.key,
    this.title = '结果',
    required this.content,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.brand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withAlpha(context.isDark ? 30 : 18),
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: c.withAlpha(80), width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: Ty.tiny.copyWith(
                      fontSize: 11, color: c, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  copyText(content);
                },
                child: Icon(Icons.copy_rounded, size: 15, color: c),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(content,
              style: TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: context.t1)),
        ],
      ),
    );
  }
}

/// 复制到剪贴板（统一入口）
void copyText(String s) {
  Clipboard.setData(ClipboardData(text: s));
  ToastUtil.success('已复制');
}
