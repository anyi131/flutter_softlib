import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/ui.dart';

/// 轻量图表（无第三方依赖，纯 CustomPaint）
///
/// ★ 1020：概览页要「看得见趋势」，但引入 fl_chart 会增加包体和依赖风险。
/// ★ 1108：MiniLineChart（折线图）已无使用方删除，保留 MiniBarList/DualLineChart。
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

/// 双线图（两条折线共用坐标系，省一半高度）
///
/// ★ 1020：原来两张单线图上下堆，各占 88px，中间大片留白。
///   合成一张后高度减半，还能直接对比「用户增长」和「下载」的关系。
class DualLineChart extends StatelessWidget {
  const DualLineChart({
    super.key,
    required this.seriesA,
    required this.seriesB,
    this.colorA,
    this.colorB,
    this.labels = const [],
    this.height = 120,
  });

  final List<double> seriesA;
  final List<double> seriesB;
  final Color? colorA;
  final Color? colorB;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (seriesA.length < 2 && seriesB.length < 2) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DualPainter(
          a: seriesA,
          b: seriesB,
          colorA: colorA ?? C.mint,
          colorB: colorB ?? C.brand,
          gridColor: context.isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(7),
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

class _DualPainter extends CustomPainter {
  _DualPainter({
    required this.a,
    required this.b,
    required this.colorA,
    required this.colorB,
    required this.gridColor,
  });

  final List<double> a;
  final List<double> b;
  final Color colorA;
  final Color colorB;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - 14;
    // 两条线共用最大值，保证可比性
    final all = [...a, ...b];
    if (all.isEmpty) return;
    final maxV = all.reduce(math.max);
    final range = maxV <= 0 ? 1.0 : maxV;

    // 网格
    final gp = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = chartH * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }

    void drawSeries(List<double> vals, Color color, {bool fill = false}) {
      if (vals.length < 2) return;
      Offset pt(int i) {
        final x = size.width * i / (vals.length - 1);
        final y = chartH - (vals[i] / range) * (chartH - 10) - 3;
        return Offset(x, y);
      }

      final path = Path()..moveTo(pt(0).dx, pt(0).dy);
      for (var i = 1; i < vals.length; i++) {
        final p0 = pt(i - 1);
        final p1 = pt(i);
        final mx = (p0.dx + p1.dx) / 2;
        path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
      }
      if (fill) {
        final area = Path.from(path)
          ..lineTo(size.width, chartH)
          ..lineTo(0, chartH)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withAlpha(46), color.withAlpha(0)],
            ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      final last = pt(vals.length - 1);
      canvas.drawCircle(last, 4.5, Paint()..color = color.withAlpha(50));
      canvas.drawCircle(last, 2.6, Paint()..color = color);
    }

    // 先画面积小的在下
    drawSeries(b, colorB, fill: true);
    drawSeries(a, colorA, fill: true);
  }

  @override
  bool shouldRepaint(covariant _DualPainter old) => old.a != a || old.b != b;
}
