import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 全局高刷（ProMotion / 高刷新率屏幕）
///
/// Flutter 默认在部分设备上锁 60Hz。这里用一个常驻的 [Ticker] 持续向引擎
/// 请求渲染帧，使滚动与动画能跑满设备支持的刷新率（90/120Hz）。
class HighRefreshScope extends StatefulWidget {
  final Widget child;
  const HighRefreshScope({super.key, required this.child});

  @override
  State<HighRefreshScope> createState() => _HighRefreshScopeState();
}

class _HighRefreshScopeState extends State<HighRefreshScope>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {})..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
