import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/ui.dart';

/// 轻量折线图（无第三方依赖，纯 CustomPaint）
///
/// ★ 1020：概览页要「看得见趋势」，但引入 fl_chart 会增加包体和依赖风险。
///   这里自己画：面积渐变 + 折线 + 数据点 + 网格，几十行足够。
class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.values,
    this.labels = const [],
    this.height = 96,
    this.color,
    this.showDots = true,
    this.fill = true,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color? color;
  final bool showDots;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final c = color ?? C.brand;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(
          values: values,
          color: c,
          isDark: context.isDark,
          showDots: showDots,
          fill: fill,
          gridColor: context.isDark
              ? Colors.white.withAlpha(14)
              : Colors.black.withAlpha(8),
        ),
        child: labels.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: labels
                        .map(
                          (l) => Text(
                            l,
                            style: TextStyle(fontSize: 8.5, color: context.t3),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.isDark,
    required this.showDots,
    required this.fill,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final bool isDark;
  final bool showDots;
  final bool fill;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    // 底部留 14px 给 x 轴标签
    final chartH = size.height - 14;
    final maxV = values.reduce(math.max);
    final minV = 0.0;
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    Offset pt(int i) {
      final x = size.width * i / (values.length - 1);
      final y = chartH - (values[i] - minV) / range * (chartH - 8) - 2;
      return Offset(x, y);
    }

    // 横向网格（3 条）
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = chartH * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 折线路径
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final prev = pt(i - 1);
      final cur = pt(i);
      // 平滑曲线（Catmull-Rom 近似 → 二次贝塞尔）
      final midX = (prev.dx + cur.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }

    // 面积填充
    if (fill) {
      final area = Path.from(path)
        ..lineTo(size.width, chartH)
        ..lineTo(0, chartH)
        ..close();
      final grad = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(isDark ? 90 : 60), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH));
      canvas.drawPath(area, grad);
    }

    // 折线
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    // 数据点（只标最后一点 + 最高点，避免拥挤）
    if (showDots) {
      final last = pt(values.length - 1);
      canvas.drawCircle(last, 5, Paint()..color = color.withAlpha(50));
      canvas.drawCircle(last, 2.8, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.color != color;
}

/// 横向条形图（用于 Top 榜单，比纯数字直观）
class MiniBarList extends StatelessWidget {
  const MiniBarList({
    super.key,
    required this.items,
    this.color,
    this.maxItems = 5,
    this.valueSuffix = '',
  });

  /// [('名称', 数值)]
  final List<MapEntry<String, double>> items;
  final Color? color;
  final int maxItems;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final list = items.take(maxItems).toList();
    final maxV = list.map((e) => e.value).reduce(math.max);
    final c = color ?? C.brand;

    return Column(
      children: list.map((e) {
        final ratio = maxV <= 0 ? 0.0 : (e.value / maxV).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: context.t1),
                    ),
                  ),
                  Text(
                    '${e.value.toInt()}$valueSuffix',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(
                      height: 5,
                      color: context.isDark
                          ? Colors.white.withAlpha(14)
                          : Colors.black.withAlpha(8),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio == 0 ? 0.02 : ratio,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [c, c.withAlpha(160)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
