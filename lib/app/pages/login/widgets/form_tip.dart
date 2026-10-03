import 'package:flutter/material.dart';

/// 内联错误提示条（替代会遮挡按钮的底部弹窗）
class FormTip extends StatelessWidget {
  final String message;
  final bool isError;
  final Widget child;

  const FormTip({
    super.key,
    required this.message,
    required this.child,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    final color = isError ? const Color(0xFFDC2626) : const Color(0xFFB45309);
    final bg = isError ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(fontSize: 13, color: color, height: 1.35)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
