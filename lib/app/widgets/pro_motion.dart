import 'package:flutter/material.dart';

/// 全局高刷支持
///
/// 历史实现：用一个【常驻 Ticker】持续请求渲染帧，试图让 Flutter 跑满
/// 设备最高刷新率。实测这个做法弊大于利：
///   · 引擎会被迫「一直出帧」，静止页面也在空转耗电
///   · 干扰部分设备的动态刷新率自适应，表现为轻微抖动/忽快忽慢
///   · 帧率的真正瓶颈在渲染成本（大面积 BackdropFilter、重绘），
///     而不是「有没有请求高刷」
///
/// 现在改为**纯透传**：Flutter 会自动跟随设备刷新率，只要渲染不掉帧
/// 就能跑满高刷。高刷支持已在 AndroidManifest 中用
/// `android:preferredDisplayModeId` / 高刷声明开启。
///
/// 保留此类是为了不破坏既有调用点（main.dart 的 builder）。
class HighRefreshScope extends StatelessWidget {
  final Widget child;
  const HighRefreshScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
