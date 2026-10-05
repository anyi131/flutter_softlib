import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/ui.dart';
import 'tools_common.dart';

// ═══════════════════════════════════════════════════════════
//  扩展工具集（计时 / 测量 / 换算 / 游戏 / 设计 / 系统）
//
//  ★ 设计约定（与 tools_local.dart、tools_text.dart 完全一致）：
//    · 每个工具都是 App 内的真实页面（不跳浏览器）
//    · 外壳统一用 ToolScaffold，分区用 ToolCard，按钮用 ToolButton
//    · 色值只用 C.*，圆角只用 R.*，排版只用 Ty.*
//    · 全部为纯本地实现，不依赖网络接口
//
//  ★ 传感器降级说明：
//    本项目 pubspec 未引入 sensors_plus，所以「指南针 / 水平仪 / 分贝仪」
//    三个工具采用「静态方位盘 + 可拖拽指针 / 匀速摆动演示」的降级方案，
//    不读取真实磁力计、加速度计和麦克风，仅作为界面演示与校准说明。
//    若后续接入 sensors_plus，只需把下列类里的变量替换成传感器数据流即可：
//      · CompassTool  → MagnetometerEvent
//      · LevelTool    → AccelerometerEvent
//      · DecibelTool  → 麦克风采样
// ═══════════════════════════════════════════════════════════

/// 把 0~1 的进度换算为 0~255 的透明度（Material 3 已移除 withOpacity）
int _a(double ratio) => (255 * ratio).clamp(0, 255).round();

// ─────────── 小部件：通用单选标签（本文件内部复用） ───────────

/// 胶囊标签，用于分类切换 / 模式切换（选中态用品牌色填充）
class _ChipBar extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _ChipBar({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (i) {
        final on = i == index;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: on
                  ? C.brand
                  : C.brand.withAlpha(context.isDark ? 30 : 16),
              borderRadius: BorderRadius.circular(R.full),
              border: Border.all(
                color: on ? C.brand : C.brand.withAlpha(60),
                width: 0.9,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : C.brand,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 数值滑杆（统一主题，避免各工具各写一套）
class _ToolSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final Color? color;
  const _ToolSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.brand;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 5,
        activeTrackColor: c,
        inactiveTrackColor: c.withAlpha(context.isDark ? 40 : 24),
        thumbColor: c,
        overlayColor: c.withAlpha(30),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// 键盘上方的「方向键」小方块（贪吃蛇 / 2048 共用）
class _PadKey extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _PadKey({required this.icon, required this.onTap, this.text = ''});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 52,
      child: Material(
        color: context.isDark ? Colors.white.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(R.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(R.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: context.t1),
              if (text.isNotEmpty)
                Text(text,
                    style: Ty.tiny.copyWith(fontSize: 9, color: context.t3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  1. 秒表
// ═══════════════════════════════════════════════════════════

/// 秒表：开始 / 暂停 / 重置 + 计次列表
class StopwatchTool extends StatefulWidget {
  const StopwatchTool({super.key});
  @override
  State<StopwatchTool> createState() => _StopwatchToolState();
}

class _StopwatchToolState extends State<StopwatchTool> {
  final Stopwatch _sw = Stopwatch();
  Timer? _timer;
  final List<int> _laps = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 开始计时（每 33ms 刷新一次，约 30fps，毫秒位不跳字）
  void _start() {
    _timer?.cancel();
    _sw.start();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _pause() {
    _sw.stop();
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _reset() {
    _sw
      ..stop()
      ..reset();
    _timer?.cancel();
    _timer = null;
    setState(() => _laps.clear());
  }

  void _lap() {
    if (_sw.elapsedMilliseconds == 0) return;
    setState(() => _laps.insert(0, _sw.elapsedMilliseconds));
  }

  /// 毫秒 → 00:00.00（分:秒.百分秒）
  String _fmt(int ms) {
    final m = (ms ~/ 60000).toString().padLeft(2, '0');
    final s = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final c = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$c';
  }

  @override
  Widget build(BuildContext context) {
    final running = _sw.isRunning;
    return ToolScaffold(
      title: '秒表',
      subtitle: '毫秒级计时 · 支持计次',
      children: [
        ToolCard(
          children: [
            Center(
              child: Text(
                _fmt(_sw.elapsedMilliseconds),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1.2,
                  color: context.t1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('分:秒.百分秒',
                  style: Ty.tiny.copyWith(color: context.t3)),
            ),
          ],
        ),
        ToolCard(
          title: '控制',
          icon: Icons.av_timer_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: ToolButton(
                    label: running ? '暂停' : '开始',
                    icon: running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: running ? C.amber : C.brand,
                    onPressed: running ? _pause : _start,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ToolButton(
                    label: '计次',
                    icon: Icons.flag_rounded,
                    color: C.cyan,
                    onPressed: _sw.elapsedMilliseconds == 0 ? null : _lap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '重置',
              icon: Icons.refresh_rounded,
              color: C.danger,
              onPressed: _reset,
            ),
          ],
        ),
        if (_laps.isNotEmpty)
          ToolCard(
            title: '计次记录',
            icon: Icons.list_alt_rounded,
            children: [
              for (int i = 0; i < _laps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: C.brand.withAlpha(context.isDark ? 40 : 22),
                          borderRadius: BorderRadius.circular(R.full),
                        ),
                        child: Text('#${_laps.length - i}',
                            style: Ty.tiny.copyWith(
                                fontSize: 10, color: C.brand)),
                      ),
                      const SizedBox(width: 10),
                      Text(_fmt(_laps[i]),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.t1)),
                      const Spacer(),
                      // 与上一次的差值
                      if (i < _laps.length - 1)
                        Text('+${_fmt(_laps[i] - _laps[i + 1])}',
                            style: Ty.tiny.copyWith(color: context.t3)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  2. 倒计时
// ═══════════════════════════════════════════════════════════

/// 倒计时：可选 时/分/秒，结束震动提醒
class CountdownTool extends StatefulWidget {
  const CountdownTool({super.key});
  @override
  State<CountdownTool> createState() => _CountdownToolState();
}

class _CountdownToolState extends State<CountdownTool> {
  int _h = 0;
  int _m = 1;
  int _s = 0;
  int _left = 60; // 剩余秒数
  bool _running = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 按当前选择重新装载剩余时间
  void _load() => _left = _h * 3600 + _m * 60 + _s;

  void _start() {
    if (_running) return;
    if (_left <= 0) _load();
    if (_left <= 0) {
      ToastUtil.info('请先选择倒计时时长');
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_left <= 1) {
        // 归零：震动三下提示
        setState(() {
          _left = 0;
          _running = false;
        });
        _timer?.cancel();
        _timer = null;
        HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 220));
        HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 220));
        HapticFeedback.heavyImpact();
        if (mounted) ToastUtil.success('时间到！');
        return;
      }
      setState(() => _left--);
    });
    setState(() => _running = true);
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _load();
    });
  }

  String _fmt(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$ss';
  }

  /// 一行「加减」选择器（时 / 分 / 秒 共用）
  Widget _picker(String label, int value, int max, ValueChanged<int> set) {
    return Column(
      children: [
        Text(label, style: Ty.tiny.copyWith(color: context.t3)),
        const SizedBox(height: 8),
        Icon(Icons.keyboard_arrow_up_rounded,
            size: 26, color: context.t2),
        GestureDetector(
          onTap: () {
            set(value >= max ? 0 : value + 1);
            if (!_running) _load();
          },
          child: Text('${value.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _running ? context.t3 : context.t1)),
        ),
        GestureDetector(
          onTap: () {
            set(value <= 0 ? max : value - 1);
            if (!_running) _load();
          },
          child: Icon(Icons.keyboard_arrow_down_rounded,
              size: 26, color: context.t2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _h * 3600 + _m * 60 + _s;
    final progress = total <= 0 ? 0.0 : (1 - _left / total).clamp(0.0, 1.0);
    return ToolScaffold(
      title: '倒计时',
      subtitle: '结束震动提醒',
      children: [
        ToolCard(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: C.brand.withAlpha(context.isDark ? 36 : 20),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _left == 0 ? C.mint : C.brand),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmt(_left),
                        style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: context.t1)),
                    Text(_running ? '计时中…' : '已暂停',
                        style: Ty.tiny.copyWith(color: context.t3)),
                  ],
                ),
              ],
            ),
          ],
        ),
        ToolCard(
          title: '选择时长',
          icon: Icons.timer_rounded,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _picker('时', _h, 23, (v) => setState(() => _h = v)),
                _picker('分', _m, 59, (v) => setState(() => _m = v)),
                _picker('秒', _s, 59, (v) => setState(() => _s = v)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quick('1 分钟', 0, 1, 0),
                _quick('3 分钟', 0, 3, 0),
                _quick('5 分钟', 0, 5, 0),
                _quick('25 分钟', 0, 25, 0),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ToolButton(
                label: _running ? '暂停' : '开始',
                icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _running ? C.amber : C.brand,
                onPressed: _running ? _pause : _start,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ToolButton(
                label: '重置',
                icon: Icons.refresh_rounded,
                color: C.danger,
                onPressed: _reset,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quick(String label, int h, int m, int s) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _h = h;
          _m = m;
          _s = s;
          _running = false;
          _timer?.cancel();
          _timer = null;
          _load();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: C.brand.withAlpha(context.isDark ? 30 : 16),
          borderRadius: BorderRadius.circular(R.full),
          border: Border.all(color: C.brand.withAlpha(60), width: 0.9),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: C.brand)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  3. 指南针
// ═══════════════════════════════════════════════════════════

/// 指南针（降级实现）
///
/// ★ 未引入 sensors_plus，无法读取磁力计，这里提供「方位指示盘」：
///   大盘固定显示 N/E/S/W 与刻度，内圈指针可通过滑杆或左右按钮旋转，
///   用于演示方位读数；真实使用时把 _angle 换成 MagnetometerEvent 数据即可。
class CompassTool extends StatefulWidget {
  const CompassTool({super.key});
  @override
  State<CompassTool> createState() => _CompassToolState();
}

class _CompassToolState extends State<CompassTool> {
  double _angle = 0; // 0~360 度，0 = 正北
  bool _lockNorth = true;

  static const _dirs = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];

  /// 角度 → 八方位文字
  String get _dirText => _dirs[((_angle + 22.5) ~/ 45) % 8];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '指南针',
      subtitle: '方位指示盘 · 需水平校准',
      children: [
        ToolCard(
          children: [
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _CompassPainter(
                        angle: _angle,
                        dark: context.isDark,
                        text: context.t1,
                        sub: context.t3,
                      ),
                    ),
                    // 中心读数
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_angle.round()}°',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: context.t1)),
                        Text(_dirText,
                            style: Ty.tiny.copyWith(color: C.brand)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ToolCard(
          title: '方位调节',
          icon: Icons.explore_rounded,
          children: [
            _ToolSlider(
              value: _angle,
              min: 0,
              max: 360,
              onChanged: (v) => setState(() => _angle = v),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ToolButton(
                    label: '左转 15°',
                    icon: Icons.arrow_back_rounded,
                    color: C.cyan,
                    onPressed: () => setState(
                        () => _angle = (_angle - 15 + 360) % 360),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ToolButton(
                    label: '右转 15°',
                    icon: Icons.arrow_forward_rounded,
                    color: C.cyan,
                    onPressed: () => setState(() => _angle = (_angle + 15) % 360),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: _lockNorth ? '取消锁定正北' : '锁定正北（0°）',
              icon: Icons.flag_rounded,
              color: C.amber,
              onPressed: () => setState(() {
                _lockNorth = !_lockNorth;
                if (_lockNorth) _angle = 0;
              }),
            ),
          ],
        ),
        ToolCard(
          title: '使用说明',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '· 把手机水平放置，远离磁铁、音箱、金属桌面再读数\n'
              '· 首次使用请在室外空旷处做「8 字」校准\n'
              '· 本页为方位指示盘演示；接入 sensors_plus 的磁力计数据后即为真实指南针',
              style: TextStyle(fontSize: 13, height: 1.85, color: context.t2),
            ),
          ],
        ),
      ],
    );
  }
}

/// 罗盘绘制：外圈刻度 + N/E/S/W + 内圈指针（-angle 表示罗盘旋转）
class _CompassPainter extends CustomPainter {
  final double angle;
  final bool dark;
  final Color text;
  final Color sub;
  const _CompassPainter({
    required this.angle,
    required this.dark,
    required this.text,
    required this.sub,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;

    // 底盘
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.fill
        ..color = dark ? Colors.white.withAlpha(10) : Colors.white,
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = dark ? Colors.white.withAlpha(28) : Colors.black.withAlpha(16),
    );

    // 刻度：每 5° 一根，整 30° 加长
    final tick = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int d = 0; d < 360; d += 5) {
      final big = d % 30 == 0;
      final rad = (d - 90) * pi / 180;
      final p1 = c + Offset(cos(rad), sin(rad)) * (r - (big ? 12 : 7));
      final p2 = c + Offset(cos(rad), sin(rad)) * (r - 2);
      tick.color = big ? C.brand.withAlpha(160) : sub.withAlpha(110);
      canvas.drawLine(p1, p2, tick);
    }

    // 罗盘整体反向旋转：指针保持向上，刻度盘转
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-angle * pi / 180);

    // N/E/S/W 文字
    const names = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final rad = (i * 90 - 90) * pi / 180;
      final p = Offset(cos(rad), sin(rad)) * (r - 30);
      final tp = TextPainter(
        text: TextSpan(
          text: names[i],
          style: TextStyle(
            fontSize: i == 0 ? 19 : 16,
            fontWeight: FontWeight.w900,
            color: i == 0 ? C.danger : text,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    canvas.restore();

    // 指针：红色朝北，蓝色朝南
    final path = Path()
      ..moveTo(c.dx, c.dy - r + 26)
      ..lineTo(c.dx - 11, c.dy)
      ..lineTo(c.dx + 11, c.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = C.danger);
    final path2 = Path()
      ..moveTo(c.dx, c.dy + r - 26)
      ..lineTo(c.dx - 11, c.dy)
      ..lineTo(c.dx + 11, c.dy)
      ..close();
    canvas.drawPath(path2, Paint()..color = C.cyan);

    // 中心圆点
    canvas.drawCircle(c, 6, Paint()..color = text);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.angle != angle || old.dark != dark;
}

// ═══════════════════════════════════════════════════════════
//  4. 水平仪
// ═══════════════════════════════════════════════════════════

/// 水平仪（降级实现）
///
/// ★ 未引入 sensors_plus，无法读取加速度计，这里提供「气泡水平仪演示盘」：
///   气泡位置由 x/y 倾角滑杆控制，|x|、|y| 都小于 1° 时判定为「已水平」。
///   真实场景下把 _x/_y 换成 AccelerometerEvent 换算的倾角即可。
class LevelTool extends StatefulWidget {
  const LevelTool({super.key});
  @override
  State<LevelTool> createState() => _LevelToolState();
}

class _LevelToolState extends State<LevelTool> {
  double _x = 0; // 左右倾角（度）
  double _y = 0; // 前后倾角（度）
  bool _beep = true; // 水平时震动提示

  /// 是否已经水平
  bool get _isLevel => _x.abs() < 1 && _y.abs() < 1;

  void _checkHaptic() {
    if (_beep && _isLevel) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final cx = (_x / 30).clamp(-1.0, 1.0);
    final cy = (_y / 30).clamp(-1.0, 1.0);
    final ok = _isLevel;
    return ToolScaffold(
      title: '水平仪',
      subtitle: '气泡水平仪 · 演示盘',
      children: [
        ToolCard(
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = min(box.maxWidth, 260.0);
                  return SizedBox(
                    width: size,
                    height: size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.isDark ? C.bg1 : Colors.white,
                        borderRadius: BorderRadius.circular(R.xl),
                        border: Border.all(
                          color: ok ? C.mint : C.brand.withAlpha(90),
                          width: ok ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 中心十字与目标圈
                          CustomPaint(
                            size: Size(size, size),
                            painter: _LevelPainter(
                              color: context.t3,
                              ok: ok,
                            ),
                          ),
                          // 气泡：跟随倾角移动
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 120),
                            alignment: Alignment(cx, cy),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (ok ? C.mint : C.brand).withAlpha(200),
                                border: Border.all(
                                    color: Colors.white.withAlpha(180),
                                    width: 1.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: (ok ? C.mint : C.amber).withAlpha(context.isDark ? 40 : 24),
                  borderRadius: BorderRadius.circular(R.full),
                ),
                child: Text(
                  ok ? '已水平 ✓' : '未水平',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ok ? C.mint : C.amber),
                ),
              ),
            ),
          ],
        ),
        ToolCard(
          title: '倾角调节',
          icon: Icons.straighten_rounded,
          trailing: Text('X ${_x.toStringAsFixed(1)}° / Y ${_y.toStringAsFixed(1)}°',
              style: Ty.tiny.copyWith(color: context.t3)),
          children: [
            Text('左右倾角 X', style: Ty.tiny.copyWith(color: context.t3)),
            _ToolSlider(
              value: _x,
              min: -30,
              max: 30,
              color: C.cyan,
              onChanged: (v) => setState(() => _x = v),
            ),
            Text('前后倾角 Y', style: Ty.tiny.copyWith(color: context.t3)),
            _ToolSlider(
              value: _y,
              min: -30,
              max: 30,
              color: C.violet,
              onChanged: (v) => setState(() => _y = v),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ToolButton(
                    label: '一键归零',
                    icon: Icons.flag_rounded,
                    onPressed: () => setState(() {
                      _x = 0;
                      _y = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ToolButton(
                    label: _beep ? '震动提示：开' : '震动提示：关',
                    icon: Icons.volume_up_rounded,
                    color: _beep ? C.mint : C.amber,
                    onPressed: () => setState(() => _beep = !_beep),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '检测是否水平',
              icon: Icons.check_circle_outline_rounded,
              color: C.brand,
              onPressed: () {
                _checkHaptic();
                ToastUtil.info(ok ? '已水平' : '还有倾斜，请继续调整');
              },
            ),
          ],
        ),
        ToolCard(
          title: '使用说明',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '· 把手机背面朝下平放在被测平面上\n'
              '· 气泡进入中心圈（|X|、|Y| < 1°）即表示水平\n'
              '· 本页为演示盘；接入 sensors_plus 加速度计即为真实水平仪',
              style: TextStyle(fontSize: 13, height: 1.85, color: context.t2),
            ),
          ],
        ),
      ],
    );
  }
}

/// 水平仪底盘：外框 + 中心十字 + 中心圆圈
class _LevelPainter extends CustomPainter {
  final Color color;
  final bool ok;
  const _LevelPainter({required this.color, required this.ok});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final line = Paint()
      ..strokeWidth = 1
      ..color = color.withAlpha(70);

    // 中心十字
    canvas.drawLine(Offset(c.dx, r * 0.22), Offset(c.dx, r * 1.78), line);
    canvas.drawLine(Offset(r * 0.22, c.dy), Offset(r * 1.78, c.dy), line);

    // 同心刻度圈
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withAlpha(70);
    canvas.drawCircle(c, r * 0.28, ring);
    canvas.drawCircle(c, r * 0.52, ring);
    canvas.drawCircle(c, r * 0.76, ring);

    // 水平目标区
    canvas.drawCircle(
      c,
      22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ok ? 2.2 : 1.4
        ..color = (ok ? C.mint : color).withAlpha(ok ? 255 : 120),
    );
  }

  @override
  bool shouldRepaint(covariant _LevelPainter old) =>
      old.ok != ok || old.color != color;
}

// ═══════════════════════════════════════════════════════════
//  5. 量角器
// ═══════════════════════════════════════════════════════════

/// 量角器：半圆刻度盘 + 可拖拽指针（按 0.5° 吸附）
class ProtractorTool extends StatefulWidget {
  const ProtractorTool({super.key});
  @override
  State<ProtractorTool> createState() => _ProtractorToolState();
}

class _ProtractorToolState extends State<ProtractorTool> {
  double _angle = 45;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '量角器',
      subtitle: '半圆刻度 · 拖动指针读数',
      children: [
        ToolCard(
          children: [
            // 半圆盘：宽高约 2:1，底部有一行数值留白
            AspectRatio(
              aspectRatio: 2,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  final h = box.maxHeight;
                  final r = w / 2;
                  final center = Offset(r, h - 8); // 圆心（底部中偏上）
                  return GestureDetector(
                    onPanUpdate: (d) {
                      final v = d.localPosition - center;
                      // 屏幕坐标 → 数学角度（0° 在正右，逆时针增大）
                      var deg = atan2(-v.dy, v.dx) * 180 / pi;
                      if (deg < 0) deg = 0; // 半圆只取 0~180
                      setState(() => _angle = (deg * 2).round() / 2);
                    },
                    child: CustomPaint(
                      size: Size(w, h),
                      painter: _ProtractorPainter(
                        angle: _angle,
                        dark: context.isDark,
                        alpha: _a(0.7),
                        text: context.t1,
                        sub: context.t3,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ToolResult(
              title: '当前角度',
              content: '${_angle.toStringAsFixed(1)}°  '
                  '（补角 ${(180 - _angle).toStringAsFixed(1)}°）',
            ),
          ],
        ),
        ToolCard(
          title: '微调',
          icon: Icons.architecture_rounded,
          children: [
            _ToolSlider(
              value: _angle,
              min: 0,
              max: 180,
              divisions: 360,
              onChanged: (v) => setState(() => _angle = v),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [30.0, 45.0, 60.0, 90.0, 120.0, 135.0]
                  .map((a) => GestureDetector(
                        onTap: () => setState(() => _angle = a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: C.brand.withAlpha(context.isDark ? 30 : 16),
                            borderRadius: BorderRadius.circular(R.full),
                          ),
                          child: Text('${a.round()}°',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: C.brand)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        ToolCard(
          title: '使用说明',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '· 在盘面上拖动即可读数，角度按 0.5° 吸附\n'
              '· 把手机平放在物体边缘，让底边与被测边重合\n'
              '· 需要更高精度时用下面的滑杆微调',
              style: TextStyle(fontSize: 13, height: 1.85, color: context.t2),
            ),
          ],
        ),
      ],
    );
  }
}

/// 半圆量角器绘制：外弧刻度 + 每 10° 数字 + 指针
class _ProtractorPainter extends CustomPainter {
  final double angle;
  final bool dark;
  final int alpha;
  final Color text;
  final Color sub;
  const _ProtractorPainter({
    required this.angle,
    required this.dark,
    required this.alpha,
    required this.text,
    required this.sub,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, size.height - 8);

    // 底盘（半圆）
    final base = Path()
      ..moveTo(c.dx - r, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), pi, pi, false)
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..color = dark
            ? Colors.white.withAlpha(10)
            : Colors.black.withAlpha(6),
    );
    canvas.drawPath(
      base,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = dark ? Colors.white.withAlpha(26) : Colors.black.withAlpha(14),
    );

    // 刻度：每 1° 短，5° 中，10° 长且有数字
    final tick = Paint()..strokeCap = StrokeCap.round;
    for (int d = 0; d <= 180; d++) {
      final rad = -d * pi / 180;
      final dir = Offset(cos(rad), sin(rad));
      double len = 5;
      if (d % 10 == 0) {
        len = 14;
      } else if (d % 5 == 0) {
        len = 9;
      }
      tick
        ..strokeWidth = d % 10 == 0 ? 1.4 : 1
        ..color = d % 10 == 0 ? C.brand.withAlpha(180) : sub.withAlpha(110);
      canvas.drawLine(c + dir * (r - len), c + dir * (r - 2), tick);

      // 每 10° 标注数字
      if (d % 10 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$d',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: sub,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final p = c + dir * (r - 26);
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // 半圆内圈辅助线（每 30°）
    final guide = Paint()
      ..strokeWidth = 0.8
      ..color = sub.withAlpha(70);
    for (int d = 0; d <= 180; d += 30) {
      final rad = -d * pi / 180;
      canvas.drawLine(c, c + Offset(cos(rad), sin(rad)) * (r - 34), guide);
    }

    // 指针
    final rad = -angle * pi / 180;
    final tip = c + Offset(cos(rad), sin(rad)) * (r - 18);
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = C.brand,
    );
    canvas.drawCircle(c, 6, Paint()..color = C.brand);
    canvas.drawCircle(
        c, 2.6, Paint()..color = dark ? C.bg0 : Colors.white);

    // 指针读数气泡
    final tp = TextPainter(
      text: TextSpan(
        text: '${angle.toStringAsFixed(1)}°',
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bp = tip + Offset(6, -16);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bp.dx - 4, bp.dy - 2, tp.width + 8, tp.height + 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = C.brand);
    tp.paint(canvas, bp);

    // 底边基准线
    canvas.drawLine(
      Offset(c.dx - r, c.dy),
      Offset(c.dx + r, c.dy),
      Paint()
        ..strokeWidth = 1.6
        ..color = text.withAlpha(90),
    );
  }

  @override
  bool shouldRepaint(covariant _ProtractorPainter old) =>
      old.angle != angle || old.dark != dark;
}

// ═══════════════════════════════════════════════════════════
//  6. 分贝仪
// ═══════════════════════════════════════════════════════════

/// 分贝仪（降级实现）
///
/// ★ 未引入 sensors_plus / 录音权限插件，读不到麦克风，这里做「模拟仪表盘」：
///   用一条带噪声的正弦曲线生成 30~100 dB 的波动值，指针与柱状条实时联动，
///   用于演示仪表盘效果。接入真实音频采样后替换 _simulate() 即可。
class DecibelTool extends StatefulWidget {
  const DecibelTool({super.key});
  @override
  State<DecibelTool> createState() => _DecibelToolState();
}

class _DecibelToolState extends State<DecibelTool> {
  Timer? _timer;
  final List<double> _bars = [];
  double _db = 42;
  bool _running = false;
  int _tick = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 模拟一段「说话/环境噪声」的波形
  void _simulate() {
    _tick++;
    final base = 48 + 16 * sin(_tick / 9) + 7 * sin(_tick / 2.7);
    final noise = (Random().nextDouble() - 0.5) * 10;
    _db = (base + noise).clamp(30.0, 100.0);
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      _timer = null;
      setState(() => _running = false);
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted) return;
      setState(() {
        _simulate();
        _bars.add(_db);
        if (_bars.length > 40) _bars.removeAt(0);
      });
    });
    setState(() => _running = true);
  }

  /// 分贝值 → 环境描述与颜色
  List<Object> get _level {
    if (_db < 40) return ['安静', C.mint];
    if (_db < 60) return ['正常', C.cyan];
    if (_db < 80) return ['偏吵', C.amber];
    return ['嘈杂', C.danger];
  }

  @override
  Widget build(BuildContext context) {
    final lv = _level;
    final ratio = ((_db - 30) / 70).clamp(0.0, 1.0);
    return ToolScaffold(
      title: '分贝仪',
      subtitle: '环境噪声 · 模拟演示',
      children: [
        ToolCard(
          children: [
            Center(
              child: SizedBox(
                width: 200,
                height: 110,
                child: CustomPaint(
                  painter: _GaugePainter(
                    ratio: ratio,
                    color: lv[1] as Color,
                    sub: context.t3,
                    text: context.t1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(_db.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          color: lv[1] as Color)),
                  const SizedBox(width: 5),
                  Text('dB',
                      style: Ty.small.copyWith(
                          color: context.t3, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: (lv[1] as Color).withAlpha(context.isDark ? 40 : 24),
                  borderRadius: BorderRadius.circular(R.full),
                ),
                child: Text('${lv[0]} · 模拟数据',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: lv[1] as Color)),
              ),
            ),
          ],
        ),
        ToolCard(
          title: '实时波形',
          icon: Icons.graphic_eq_rounded,
          children: [
            SizedBox(
              height: 90,
              child: _bars.isEmpty
                  ? Center(
                      child: Text('点击「开始检测」查看波形',
                          style: Ty.tiny.copyWith(color: context.t3)),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _bars
                          .map((v) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 0.6),
                                  child: Container(
                                    height: ((v - 25) / 80)
                                        .clamp(0.04, 1.0)
                                        .toDouble() *
                                        88,
                                    decoration: BoxDecoration(
                                      color: C.brand.withAlpha(200),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
        ToolButton(
          label: _running ? '停止检测' : '开始检测',
          icon: _running ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: _running ? C.danger : C.brand,
          onPressed: _toggle,
        ),
        const SizedBox(height: 14),
        ToolCard(
          title: '分贝参考',
          icon: Icons.info_outline_rounded,
          children: [
            _refRow('0-30 dB', '极安静（耳语、森林）', C.mint),
            _refRow('30-50 dB', '安静（图书馆、卧室）', C.cyan),
            _refRow('50-70 dB', '正常（交谈、办公室）', C.brand),
            _refRow('70-90 dB', '吵闹（马路、吸尘器）', C.amber),
            _refRow('90 dB 以上', '危险（长期暴露损伤听力）', C.danger),
          ],
        ),
      ],
    );
  }

  Widget _refRow(String l, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: Text(l,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.t1)),
            ),
            Expanded(
              child: Text(v,
                  style: TextStyle(fontSize: 12.5, color: context.t2)),
            ),
          ],
        ),
      );
}

/// 半圆形仪表盘：底弧 + 彩色进度弧 + 指针 + 刻度
class _GaugePainter extends CustomPainter {
  final double ratio;
  final Color color;
  final Color sub;
  final Color text;
  const _GaugePainter({
    required this.ratio,
    required this.color,
    required this.sub,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 8;
    final c = Offset(size.width / 2, size.height - 8);
    final rect = Rect.fromCircle(center: c, radius: r);

    // 底弧
    canvas.drawArc(
      rect,
      pi,
      pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = sub.withAlpha(45),
    );

    // 进度弧
    canvas.drawArc(
      rect,
      pi,
      pi * ratio,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // 刻度
    final tick = Paint()
      ..strokeWidth = 1.2
      ..color = sub.withAlpha(120);
    for (int i = 0; i <= 10; i++) {
      final rad = pi + pi * i / 10;
      final d = Offset(cos(rad), sin(rad));
      canvas.drawLine(c + d * (r - 18), c + d * (r - 25), tick);
    }

    // 指针
    final rad = pi + pi * ratio.clamp(0.0, 1.0);
    final d = Offset(cos(rad), sin(rad));
    canvas.drawLine(
      c,
      c + d * (r - 22),
      Paint()
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = text,
    );
    canvas.drawCircle(c, 5, Paint()..color = text);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.ratio != ratio || old.color != color;
}

// ═══════════════════════════════════════════════════════════
//  7. 单位换算
// ═══════════════════════════════════════════════════════════

/// 单位换算：长度 / 重量 / 面积 / 温度 / 数据 / 时间
class UnitTool extends StatefulWidget {
  const UnitTool({super.key});
  @override
  State<UnitTool> createState() => _UnitToolState();
}

class _UnitToolState extends State<UnitTool> {
  final _in = TextEditingController(text: '1');
  int _cat = 0;
  int _from = 0;
  int _to = 1;

  /// 分类表：名称 + 单位名 + 相对基准单位的系数
  /// 温度不满足线性比例，单独用公式处理（见 _convert）
  static const List<Map<String, Object>> _cats = [
    {
      'name': '长度',
      'units': ['毫米', '厘米', '米', '千米', '英寸', '英尺', '英里', '海里'],
      'k': [0.001, 0.01, 1, 1000, 0.0254, 0.3048, 1609.344, 1852],
    },
    {
      'name': '重量',
      'units': ['毫克', '克', '千克', '吨', '两', '斤', '磅', '盎司'],
      'k': [1e-6, 0.001, 1, 1000, 0.05, 0.5, 0.4535924, 0.02834952],
    },
    {
      'name': '面积',
      'units': ['平方厘米', '平方米', '平方千米', '公顷', '亩', '平方英尺', '英亩'],
      'k': [0.0001, 1, 1e6, 10000, 666.6667, 0.09290304, 4046.8564224],
    },
    {
      'name': '温度',
      'units': ['摄氏度', '华氏度', '开尔文'],
      'k': [1, 1, 1],
    },
    {
      'name': '数据',
      'units': ['位(bit)', '字节(B)', 'KB', 'MB', 'GB', 'TB'],
      'k': [0.125, 1, 1024, 1048576, 1073741824, 1099511627776],
    },
    {
      'name': '时间',
      'units': ['毫秒', '秒', '分钟', '小时', '天', '周'],
      'k': [0.001, 1, 60, 3600, 86400, 604800],
    },
  ];

  List<String> get _units =>
      (_cats[_cat]['units']! as List).cast<String>();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// 基准单位 → 目标单位
  double _convert(double v) {
    if (_cat == 3) {
      // 温度：先转成摄氏度，再转成目标
      double c;
      switch (_from) {
        case 0:
          c = v;
          break;
        case 1:
          c = (v - 32) * 5 / 9;
          break;
        default:
          c = v - 273.15;
      }
      switch (_to) {
        case 0:
          return c;
        case 1:
          return c * 9 / 5 + 32;
        default:
          return c + 273.15;
      }
    }
    final k = (_cats[_cat]['k']! as List).cast<num>();
    return v * k[_from] / k[_to];
  }

  /// 去掉小数点后多余的 0
  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '—';
    final abs = v.abs();
    if (abs != 0 && (abs >= 1e12 || abs < 1e-6)) {
      return v.toStringAsExponential(4);
    }
    var s = v.toStringAsFixed(6);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  void _switchCat(int i) {
    setState(() {
      _cat = i;
      _from = 0;
      _to = i == 3 ? 1 : 1;
    });
  }

  void _swap() {
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final units = _units;
    final v = double.tryParse(_in.text.trim()) ?? 0;
    final out = _convert(v);
    return ToolScaffold(
      title: '单位换算',
      subtitle: '长度 / 重量 / 面积 / 温度 / 数据 / 时间',
      children: [
        ToolCard(
          title: '换算分类',
          icon: Icons.category_rounded,
          children: [
            _ChipBar(
              labels: _cats.map((e) => e['name']! as String).toList(),
              index: _cat,
              onChanged: _switchCat,
            ),
          ],
        ),
        ToolCard(
          title: '输入与换算',
          icon: Icons.swap_horiz_rounded,
          children: [
            Text('从', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    units[_from],
                    (i) => setState(() => _from = i),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(units[_to], (i) => setState(() => _to = i)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ToolField(
              controller: _in,
              hint: '输入数值',
              keyboard:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '交换单位',
              icon: Icons.swap_vert_rounded,
              color: C.cyan,
              onPressed: _swap,
            ),
            const SizedBox(height: 14),
            ToolResult(
              title: '换算结果',
              content: '${_fmt(v)} ${units[_from]} = ${_fmt(out)} ${units[_to]}',
            ),
          ],
        ),
        ToolCard(
          title: '同类别全部换算',
          icon: Icons.list_alt_rounded,
          children: [
            for (int i = 0; i < units.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(units[i],
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  i == _to ? FontWeight.w800 : FontWeight.w500,
                              color: i == _to ? C.brand : context.t2)),
                    ),
                    Expanded(
                      child: Text(_fmt(_convertFrom(v, i)),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.t1)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 指定目标下标 i 时的换算（复用 _convert，临时切换 _to）
  double _convertFrom(double v, int i) {
    final keep = _to;
    _to = i;
    final r = _convert(v);
    _to = keep;
    return r;
  }

  Widget _dropdown(String value, ValueChanged<int> onChanged) {
    final units = _units;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(
            color: context.isDark
                ? Colors.white.withAlpha(18)
                : Colors.black.withAlpha(8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(R.md),
          style: TextStyle(fontSize: 14, color: context.t1),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.t3),
          items: units
              .map((u) => DropdownMenuItem<String>(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(units.indexOf(v));
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  8. 汇率换算
// ═══════════════════════════════════════════════════════════

/// 汇率换算：内置常见货币汇率表（以人民币为基准，离线近似值）
///
/// ★ 汇率为内置静态数据（写死一份近似值），不联网、不引入行情依赖；
///   如需实时汇率请替换 kRates 为接口下发数据。
class ExchangeTool extends StatefulWidget {
  const ExchangeTool({super.key});
  @override
  State<ExchangeTool> createState() => _ExchangeToolState();
}

class _ExchangeToolState extends State<ExchangeTool> {
  final _in = TextEditingController(text: '100');
  String _from = 'CNY';
  String _to = 'USD';

  /// 汇率表：1 单位该货币 ≈ 多少人民币（离线近似值，仅作演示）
  static const Map<String, double> kRates = {
    'CNY': 1.0,
    'USD': 7.15,
    'EUR': 7.78,
    'GBP': 9.12,
    'JPY': 0.0472,
    'HKD': 0.916,
    'MOP': 0.889,
    'TWD': 0.221,
    'KRW': 0.00522,
    'SGD': 5.32,
    'AUD': 4.72,
    'CAD': 5.25,
    'CHF': 8.09,
    'RUB': 0.0745,
    'INR': 0.0857,
    'THB': 0.200,
    'MYR': 1.58,
    'NZD': 4.32,
  };

  /// 带符号与中文名，便于展示
  static const Map<String, String> kNames = {
    'CNY': '人民币 ¥',
    'USD': '美元 \$',
    'EUR': '欧元 €',
    'GBP': '英镑 £',
    'JPY': '日元 ¥',
    'HKD': '港币 HK\$',
    'MOP': '澳门元 MOP\$',
    'TWD': '新台币 NT\$',
    'KRW': '韩元 ₩',
    'SGD': '新加坡元 S\$',
    'AUD': '澳元 A\$',
    'CAD': '加元 C\$',
    'CHF': '瑞士法郎',
    'RUB': '卢布 ₽',
    'INR': '印度卢比 ₹',
    'THB': '泰铢 ฿',
    'MYR': '马来西亚林吉特',
    'NZD': '新西兰元',
  };

  List<String> get _codes => kRates.keys.toList();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// 通用换算：from → to（都先折成人民币）
  double _conv(double v, String from, String to) =>
      v * kRates[from]! / kRates[to]!;

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '—';
    if (v != 0 && v.abs() < 0.01) return v.toStringAsFixed(6);
    var s = v.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  void _swap() {
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(_in.text.trim()) ?? 0;
    final out = _conv(v, _from, _to);
    return ToolScaffold(
      title: '汇率换算',
      subtitle: '内置汇率表 · 双向换算',
      children: [
        ToolCard(
          title: '换算',
          icon: Icons.currency_exchange_rounded,
          children: [
            Row(
              children: [
                Expanded(child: _picker(true)),
                IconButton(
                  onPressed: _swap,
                  icon: Icon(Icons.swap_horiz_rounded, color: C.brand),
                ),
                Expanded(child: _picker(false)),
              ],
            ),
            const SizedBox(height: 12),
            ToolField(
              controller: _in,
              hint: '输入金额',
              keyboard:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            ToolResult(
              title: '换算结果',
              content: '${_fmt(v)} ${kNames[_from]}\n= ${_fmt(out)} ${kNames[_to]}',
            ),
            const SizedBox(height: 10),
            // 反向结果，方便直接复制
            ToolResult(
              title: '反向结果（1 ${_to} = ? ${_from}）',
              content:
                  '1 $_to = ${_fmt(_conv(1, _to, _from))} $_from',
              color: C.cyan,
            ),
          ],
        ),
        ToolCard(
          title: '常用对照（1 单位 = ? 人民币）',
          icon: Icons.list_alt_rounded,
          children: [
            for (final code in ['USD', 'EUR', 'GBP', 'JPY', 'HKD', 'KRW'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(code,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: C.brand)),
                    ),
                    Expanded(
                      child: Text(kNames[code]!,
                          style: TextStyle(fontSize: 12.5, color: context.t2)),
                    ),
                    Text('¥ ${_fmt(kRates[code]!)}',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: context.t1)),
                  ],
                ),
              ),
          ],
        ),
        ToolCard(
          title: '说明',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '· 汇率为内置离线近似值（以人民币为基准），仅供日常估算\n'
              '· 实际以银行/支付平台实时牌价为准',
              style: TextStyle(fontSize: 13, height: 1.85, color: context.t2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _picker(bool isFrom) {
    final code = isFrom ? _from : _to;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(
            color: context.isDark
                ? Colors.white.withAlpha(18)
                : Colors.black.withAlpha(8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: code,
          isExpanded: true,
          borderRadius: BorderRadius.circular(R.md),
          style: TextStyle(fontSize: 14, color: context.t1),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.t3),
          items: _codes
              .map((c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text('${kNames[c]}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              if (isFrom) {
                _from = v;
              } else {
                _to = v;
              }
            });
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  9. 房贷计算
// ═══════════════════════════════════════════════════════════

/// 房贷计算：支持「等额本息」「等额本金」两种还款方式
class LoanTool extends StatefulWidget {
  const LoanTool({super.key});
  @override
  State<LoanTool> createState() => _LoanToolState();
}

class _LoanToolState extends State<LoanTool> {
  final _amount = TextEditingController(text: '100');
  final _rate = TextEditingController(text: '3.5');
  final _years = TextEditingController(text: '30');
  int _mode = 0; // 0 = 等额本息，1 = 等额本金

  String _out = '';

  @override
  void initState() {
    super.initState();
    _calc();
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  /// 金额（万元）→ 元
  double get _principal =>
      (double.tryParse(_amount.text.trim()) ?? 0) * 10000;

  int get _months {
    final y = double.tryParse(_years.text.trim()) ?? 0;
    return (y * 12).round();
  }

  /// 年利率（%）→ 月利率
  double get _monthRate =>
      (double.tryParse(_rate.text.trim()) ?? 0) / 100 / 12;

  void _calc() {
    final p = _principal;
    final n = _months;
    final i = _monthRate;
    if (p <= 0 || n <= 0) {
      setState(() => _out = '请输入有效的贷款金额与年限');
      return;
    }
    final sb = StringBuffer();
    sb.writeln('贷款总额：¥ ${_yuan(p)}（${_amount.text} 万元）');
    sb.writeln('年利率：${_rate.text}%    期数：$n 期（${_years.text} 年）');
    sb.writeln('还款方式：${_mode == 0 ? '等额本息' : '等额本金'}');
    sb.writeln('────────────────────────');

    if (_mode == 0) {
      // 等额本息：月供 = P·i·(1+i)^n / ((1+i)^n − 1)
      double pay;
      if (i == 0) {
        pay = p / n;
      } else {
        final f = pow(1 + i, n).toDouble();
        pay = p * i * f / (f - 1);
      }
      final total = pay * n;
      sb.writeln('每月月供：¥ ${_yuan(pay)}');
      sb.writeln('还款总额：¥ ${_yuan(total)}');
      sb.writeln('支付利息：¥ ${_yuan(total - p)}');
      sb.writeln('利息占比：${((total - p) / total * 100).toStringAsFixed(1)}%');
      sb.writeln('────────────────────────');
      // 前 5 期明细
      sb.writeln('前 5 期参考：');
      var left = p;
      for (int k = 1; k <= 5 && k <= n; k++) {
        final interest = left * i;
        final prin = pay - interest;
        left -= prin;
        sb.writeln('  第 $k 期：本金 ${_yuan(prin)}  利息 ${_yuan(interest)}'
            '  剩余 ${_yuan(left < 0 ? 0 : left)}');
      }
    } else {
      // 等额本金：每月本金 = P/n，利息 = 剩余本金 × i
      final prin = p / n;
      final firstPay = prin + p * i;
      final lastPay = prin + prin * i;
      final totalRate = p * i * (n + 1) / 2; // 利息合计
      sb.writeln('首月月供：¥ ${_yuan(firstPay)}');
      sb.writeln('末月月供：¥ ${_yuan(lastPay)}');
      sb.writeln('每月递减：¥ ${_yuan(prin * i)}');
      sb.writeln('还款总额：¥ ${_yuan(p + totalRate)}');
      sb.writeln('支付利息：¥ ${_yuan(totalRate)}');
      sb.writeln('利息占比：${(totalRate / (p + totalRate) * 100).toStringAsFixed(1)}%');
      sb.writeln('────────────────────────');
      sb.writeln('前 5 期参考：');
      var left = p;
      for (int k = 1; k <= 5 && k <= n; k++) {
        final interest = left * i;
        left -= prin;
        sb.writeln('  第 $k 期：本金 ${_yuan(prin)}  利息 ${_yuan(interest)}'
            '  剩余 ${_yuan(left < 0 ? 0 : left)}');
      }
    }
    setState(() => _out = sb.toString().trimRight());
  }

  /// 金额格式化（保留 2 位小数 + 千分位）
  String _yuan(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '房贷计算',
      subtitle: '等额本息 / 等额本金',
      children: [
        ToolCard(
          title: '贷款信息',
          icon: Icons.home_work_rounded,
          children: [
            ToolField(
              controller: _amount,
              hint: '贷款金额（万元）',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calc(),
            ),
            const SizedBox(height: 12),
            ToolField(
              controller: _rate,
              hint: '年利率（%）',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calc(),
            ),
            const SizedBox(height: 12),
            ToolField(
              controller: _years,
              hint: '贷款年限（年）',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calc(),
            ),
            const SizedBox(height: 12),
            Text('还款方式', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            _ChipBar(
              labels: const ['等额本息', '等额本金'],
              index: _mode,
              onChanged: (i) => setState(() {
                _mode = i;
                _calc();
              }),
            ),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '计算结果', content: _out),
        ToolCard(
          title: '两种方式区别',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '· 等额本息：每月还款额固定，前期利息占比高，总利息更多\n'
              '· 等额本金：每月本金固定，月供逐月递减，总利息更少但前期压力大',
              style: TextStyle(fontSize: 13, height: 1.85, color: context.t2),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  10. 油耗计算
// ═══════════════════════════════════════════════════════════

/// 油耗计算：输入行驶里程与加油量，输出百公里油耗与每公里油费
class FuelTool extends StatefulWidget {
  const FuelTool({super.key});
  @override
  State<FuelTool> createState() => _FuelToolState();
}

class _FuelToolState extends State<FuelTool> {
  final _km = TextEditingController(text: '500');
  final _l = TextEditingController(text: '40');
  final _price = TextEditingController(text: '7.8');
  double _per100 = 0;
  double _perKm = 0;
  double _cost = 0;

  @override
  void initState() {
    super.initState();
    _calc();
  }

  @override
  void dispose() {
    _km.dispose();
    _l.dispose();
    _price.dispose();
    super.dispose();
  }

  void _calc() {
    final km = double.tryParse(_km.text.trim()) ?? 0;
    final l = double.tryParse(_l.text.trim()) ?? 0;
    final price = double.tryParse(_price.text.trim()) ?? 0;
    if (km <= 0 || l <= 0) {
      setState(() {
        _per100 = 0;
        _perKm = 0;
        _cost = 0;
      });
      return;
    }
    setState(() {
      _per100 = l / km * 100; // 百公里油耗 L/100km
      _perKm = l * price / km; // 每公里油费
      _cost = l * price; // 本次油费
    });
  }

  String _f(double v, int n) => v <= 0 ? '—' : v.toStringAsFixed(n);

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '油耗计算',
      subtitle: '百公里油耗 · 每公里油费',
      children: [
        ToolCard(
          title: '输入数据',
          icon: Icons.local_gas_station_rounded,
          children: [
            ToolField(
              controller: _km,
              hint: '行驶里程（公里）',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calc(),
            ),
            const SizedBox(height: 12),
            ToolField(
              controller: _l,
              hint: '加油量（升）',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calc(),
            ),
            const SizedBox(height: 12),
            ToolField(
              controller: _price,
              hint: '油价（元/升），可留空',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calc(),
            ),
          ],
        ),
        ToolCard(
          title: '计算结果',
          icon: Icons.bar_chart_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: _big('百公里油耗', _f(_per100, 2), 'L/100km', C.brand),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _big('每公里油费', _f(_perKm, 3), '元/km', C.mint),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ToolResult(
              title: '汇总',
              content: '本次加油花费：¥ ${_f(_cost, 2)}\n'
                  '百公里油耗：${_f(_per100, 2)} L/100km\n'
                  '每公里油费：¥ ${_f(_perKm, 3)}\n'
                  '每升可行驶：${_per100 <= 0 ? '—' : (100 / _per100).toStringAsFixed(2)} km',
            ),
          ],
        ),
        ToolCard(
          title: '油耗参考（L/100km）',
          icon: Icons.info_outline_rounded,
          children: [
            _row('小型车 / 混动', '4 ~ 6', C.mint),
            _row('紧凑型轿车', '6 ~ 8', C.cyan),
            _row('中型轿车 / SUV', '8 ~ 11', C.brand),
            _row('大型 SUV / 越野', '11 ~ 15', C.amber),
            _row('明显偏高（需检查）', '> 15', C.danger),
          ],
        ),
      ],
    );
  }

  Widget _big(String label, String value, String unit, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: c.withAlpha(context.isDark ? 30 : 16),
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: c.withAlpha(70), width: 0.9),
      ),
      child: Column(
        children: [
          Text(label, style: Ty.tiny.copyWith(color: context.t3)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: c)),
          Text(unit, style: Ty.tiny.copyWith(fontSize: 10, color: context.t3)),
        ],
      ),
    );
  }

  Widget _row(String l, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(l, style: TextStyle(fontSize: 13, color: context.t2)),
            const Spacer(),
            Text(v,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  11. 血型遗传查询
// ═══════════════════════════════════════════════════════════

/// 血型遗传：父母血型 → 子女可能血型 / 不可能血型
class BloodTypeTool extends StatefulWidget {
  const BloodTypeTool({super.key});
  @override
  State<BloodTypeTool> createState() => _BloodTypeToolState();
}

class _BloodTypeToolState extends State<BloodTypeTool> {
  /// ABO 血型的等位基因组合（表现型 → 基因型）
  static const Map<String, List<String>> kGeno = {
    'A': ['AA', 'AO'],
    'B': ['BB', 'BO'],
    'AB': ['AB'],
    'O': ['OO'],
  };

  static const List<String> kTypes = ['A', 'B', 'AB', 'O'];

  static const List<String> kAll = ['A', 'B', 'AB', 'O'];

  String _father = 'A';
  String _mother = 'B';

  /// 由两个等位基因推出表现型
  String _pheno(String g) {
    if (g == 'OO') return 'O';
    if (g == 'AA' || g == 'AO') return 'A';
    if (g == 'BB' || g == 'BO') return 'B';
    return 'AB';
  }

  /// 枚举双亲所有基因型组合，统计子女可能血型
  List<String> _possible() {
    final res = <String>{};
    for (final g1 in kGeno[_father]!) {
      for (final g2 in kGeno[_mother]!) {
        // 各取一个等位基因
        for (int i = 0; i < 2; i++) {
          for (int j = 0; j < 2; j++) {
            final child = g1[i] + g2[j];
            res.add(_pheno(child));
          }
        }
      }
    }
    final list = kAll.where(res.contains).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final possible = _possible();
    final impossible = kAll.where((e) => !possible.contains(e)).toList();
    return ToolScaffold(
      title: '血型遗传查询',
      subtitle: '父母血型 → 子女可能血型',
      children: [
        ToolCard(
          title: '选择父母血型',
          icon: Icons.bloodtype_rounded,
          children: [
            Text('父亲血型', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            _ChipBar(
              labels: kTypes,
              index: kTypes.indexOf(_father),
              onChanged: (i) => setState(() => _father = kTypes[i]),
            ),
            const SizedBox(height: 14),
            Text('母亲血型', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            _ChipBar(
              labels: kTypes,
              index: kTypes.indexOf(_mother),
              onChanged: (i) => setState(() => _mother = kTypes[i]),
            ),
          ],
        ),
        ToolCard(
          title: '查询结果',
          icon: Icons.search_rounded,
          children: [
            Row(
              children: [
                _bloodChip(_father, '父', C.brand),
                const SizedBox(width: 8),
                Icon(Icons.add_rounded, size: 18, color: context.t3),
                const SizedBox(width: 8),
                _bloodChip(_mother, '母', C.violet),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: context.t3),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: possible
                        .map((b) => _bloodChip(b, '', C.mint))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ToolResult(
              title: '结论',
              content: '父母为 $_father 型 + $_mother 型时：\n'
                  '· 子女可能血型：${possible.join(' / ')}\n'
                  '· 子女不可能血型：${impossible.isEmpty ? '无' : impossible.join(' / ')}',
            ),
          ],
        ),
        ToolCard(
          title: '全部组合对照表',
          icon: Icons.list_alt_rounded,
          children: [
            for (final f in kTypes)
              for (final m in kTypes)
                if (kTypes.indexOf(f) <= kTypes.indexOf(m))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text('$f + $m',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: (f == _father && m == _mother)
                                      ? C.brand
                                      : context.t2)),
                        ),
                        Expanded(
                          child: Text(
                            _possibleFor(f, m).join(' / '),
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: context.t1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
        ToolCard(
          title: '说明',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '· 依据 ABO 血型的等位基因自由组合推算，不含 Rh 阴/阳性\n'
              '· 结论仅为「可能性」，不能用于亲子鉴定等法律用途',
              style: TextStyle(fontSize: 13, height: 1.85, color: context.t2),
            ),
          ],
        ),
      ],
    );
  }

  /// 指定父母血型的子女可能血型（对照表用）
  List<String> _possibleFor(String f, String m) {
    final res = <String>{};
    for (final g1 in kGeno[f]!) {
      for (final g2 in kGeno[m]!) {
        for (int i = 0; i < 2; i++) {
          for (int j = 0; j < 2; j++) {
            res.add(_pheno(g1[i] + g2[j]));
          }
        }
      }
    }
    return kAll.where(res.contains).toList();
  }

  Widget _bloodChip(String type, String tag, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: c.withAlpha(context.isDark ? 40 : 24),
        borderRadius: BorderRadius.circular(R.full),
        border: Border.all(color: c.withAlpha(90), width: 0.9),
      ),
      child: Text(tag.isEmpty ? type : '$tag $type',
          style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w900, color: c)),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  12. 贪吃蛇
// ═══════════════════════════════════════════════════════════

/// 贪吃蛇：网格 + 方向键 / 定时器自动前进
class SnakeTool extends StatefulWidget {
  const SnakeTool({super.key});
  @override
  State<SnakeTool> createState() => _SnakeToolState();
}

class _SnakeToolState extends State<SnakeTool> {
  static const int n = 15; // 15×15 网格
  Timer? _timer;

  /// 蛇身坐标队列（下标 0 为蛇头）
  List<Point<int>> _snake = [];
  Point<int> _food = const Point(0, 0);
  Point<int> _dir = const Point(1, 0);
  Point<int> _nextDir = const Point(1, 0);
  int _score = 0;
  int _best = 0;
  bool _running = false;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    final cx = n ~/ 2;
    setState(() {
      _snake = [
        Point(cx, cx),
        Point(cx - 1, cx),
        Point(cx - 2, cx),
      ];
      _dir = const Point(1, 0);
      _nextDir = const Point(1, 0);
      _score = 0;
      _over = false;
      _running = false;
      _placeFood();
    });
  }

  /// 在空格子里随机放食物
  void _placeFood() {
    final rnd = Random();
    while (true) {
      final p = Point(rnd.nextInt(n), rnd.nextInt(n));
      if (!_snake.contains(p)) {
        _food = p;
        return;
      }
    }
  }

  void _start() {
    if (_running) return;
    if (_over) _reset();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) => _step());
    setState(() => _running = true);
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _running = false);
  }

  /// 转向（禁止 180° 反折）
  void _turn(Point<int> d) {
    if (d.x == -_dir.x && d.y == -_dir.y) return;
    _nextDir = d;
  }

  /// 走一步
  void _step() {
    if (!mounted) return;
    _dir = _nextDir;
    final head = _snake.first;
    final nh = Point(head.x + _dir.x, head.y + _dir.y);

    // 撞墙
    if (nh.x < 0 || nh.y < 0 || nh.x >= n || nh.y >= n) {
      _gameOver();
      return;
    }
    // 撞自己（尾巴会同时移开，所以最后一节允许占用）
    if (_snake.sublist(0, _snake.length - 1).contains(nh)) {
      _gameOver();
      return;
    }

    setState(() {
      _snake.insert(0, nh);
      if (nh == _food) {
        _score += 10;
        if (_score > _best) _best = _score;
        _placeFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _gameOver() {
    _timer?.cancel();
    _timer = null;
    HapticFeedback.mediumImpact();
    setState(() {
      _running = false;
      _over = true;
    });
    ToastUtil.error('撞到了！得分 $_score');
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '贪吃蛇',
      subtitle: '方向键控制 · 吃到食物得分',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Center(
            child: Text('$_score',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: C.brand)),
          ),
        ),
      ],
      children: [
        ToolCard(
          children: [
            Row(
              children: [
                Text('得分 $_score',
                    style: Ty.small.copyWith(
                        color: context.t1, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('最高 $_best',
                    style: Ty.small.copyWith(color: context.t3)),
              ],
            ),
            const SizedBox(height: 10),
            // 棋盘：固定边长正方形，保证格子为正方形
            LayoutBuilder(
              builder: (context, box) {
                final side = min(box.maxWidth, 340.0);
                return Center(
                  child: Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      color: context.isDark ? C.bg1 : Colors.white,
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(
                          color: C.brand.withAlpha(80), width: 1.2),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: n),
                      itemCount: n * n,
                      itemBuilder: (context, idx) {
                        final x = idx % n;
                        final y = idx ~/ n;
                        final isHead = _snake.isNotEmpty &&
                            _snake.first.x == x &&
                            _snake.first.y == y;
                        final isBody = _snake.contains(Point(x, y));
                        final isFood = _food.x == x && _food.y == y;
                        Color? color;
                        if (isHead) {
                          color = C.brand;
                        } else if (isBody) {
                          color = C.brand.withAlpha(context.isDark ? 150 : 120);
                        } else if (isFood) {
                          color = C.danger;
                        }
                        return Padding(
                          padding: const EdgeInsets.all(1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                              border: (x + y) % 2 == 0
                                  ? Border.all(
                                      color: context.t3.withAlpha(18),
                                      width: 0.5)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            if (_over)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ToolResult(
                  title: '游戏结束',
                  content: '本局得分：$_score\n最高得分：$_best',
                  color: C.danger,
                ),
              ),
          ],
        ),
        ToolCard(
          title: '控制',
          icon: Icons.sports_esports_rounded,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PadKey(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => _turn(const Point(-1, 0)),
                ),
                const SizedBox(width: 10),
                _PadKey(
                  icon: Icons.arrow_upward_rounded,
                  onTap: () => _turn(const Point(0, -1)),
                ),
                const SizedBox(width: 10),
                _PadKey(
                  icon: Icons.arrow_downward_rounded,
                  onTap: () => _turn(const Point(0, 1)),
                ),
                const SizedBox(width: 10),
                _PadKey(
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => _turn(const Point(1, 0)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ToolButton(
                    label: _running ? '暂停' : '开始',
                    icon: _running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: _running ? C.amber : C.brand,
                    onPressed: _running ? _pause : _start,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ToolButton(
                    label: '重新开始',
                    icon: Icons.refresh_rounded,
                    color: C.danger,
                    onPressed: () => setState(_reset),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  13. 2048
// ═══════════════════════════════════════════════════════════

/// 2048：4×4 网格，支持滑动与方向键
class Game2048Tool extends StatefulWidget {
  const Game2048Tool({super.key});
  @override
  State<Game2048Tool> createState() => _Game2048ToolState();
}

class _Game2048ToolState extends State<Game2048Tool> {
  static const int n = 4;
  late List<List<int>> _g; // 0 表示空格
  int _score = 0;
  int _best = 0;
  bool _over = false;
  /// 滑动累计位移（松手时判断主方向）
  Offset _dragStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _g = List.generate(n, (_) => List.filled(n, 0));
    _score = 0;
    _over = false;
    _addTile();
    _addTile();
    setState(() {});
  }

  /// 随机在空格生成 2（90%）或 4（10%）
  void _addTile() {
    final empty = <Point<int>>[];
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (_g[y][x] == 0) empty.add(Point(x, y));
      }
    }
    if (empty.isEmpty) return;
    final p = empty[Random().nextInt(empty.length)];
    _g[p.y][p.x] = Random().nextDouble() < 0.9 ? 2 : 4;
  }

  /// 把一行/列向左压缩合并（值向左靠拢）
  List<int> _merge(List<int> line) {
    final v = line.where((e) => e != 0).toList();
    final out = <int>[];
    int i = 0;
    while (i < v.length) {
      if (i + 1 < v.length && v[i] == v[i + 1]) {
        final s = v[i] * 2;
        out.add(s);
        _score += s;
        i += 2;
      } else {
        out.add(v[i]);
        i++;
      }
    }
    while (out.length < n) {
      out.add(0);
    }
    return out;
  }

  /// 取第 y 行
  List<int> _getRow(int y) => List.generate(n, (x) => _g[y][x]);
  void _setRow(int y, List<int> r) {
    for (int x = 0; x < n; x++) {
      _g[y][x] = r[x];
    }
  }

  List<int> _getCol(int x) => List.generate(n, (y) => _g[y][x]);
  void _setCol(int x, List<int> c) {
    for (int y = 0; y < n; y++) {
      _g[y][x] = c[y];
    }
  }

  /// 移动一回合；返回是否发生变化
  bool _move(String dir) {
    final before = _g.map((r) => r.join(',')).join('|');
    switch (dir) {
      case 'left':
        for (int y = 0; y < n; y++) {
          _setRow(y, _merge(_getRow(y)));
        }
        break;
      case 'right':
        for (int y = 0; y < n; y++) {
          final r = _getRow(y).reversed.toList();
          _setRow(y, _merge(r).reversed.toList());
        }
        break;
      case 'up':
        for (int x = 0; x < n; x++) {
          _setCol(x, _merge(_getCol(x)));
        }
        break;
      case 'down':
        for (int x = 0; x < n; x++) {
          final c = _getCol(x).reversed.toList();
          _setCol(x, _merge(c).reversed.toList());
        }
        break;
    }
    final after = _g.map((r) => r.join(',')).join('|');
    return before != after;
  }

  void _doMove(String dir) {
    if (_over) return;
    final changed = _move(dir);
    if (changed) {
      _addTile();
      if (_score > _best) _best = _score;
    }
    if (!_canMove()) {
      _over = true;
      HapticFeedback.mediumImpact();
    }
    setState(() {});
  }

  /// 是否还有可行的移动
  bool _canMove() {
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (_g[y][x] == 0) return true;
        if (x + 1 < n && _g[y][x] == _g[y][x + 1]) return true;
        if (y + 1 < n && _g[y][x] == _g[y + 1][x]) return true;
      }
    }
    return false;
  }

  /// 不同数值用不同底色，越大越「烫」
  Color _tileColor(int v) {
    switch (v) {
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      default:
        return const Color(0xFFEDC22E);
    }
  }

  Color _textColor(int v) =>
      v <= 4 ? const Color(0xFF776E65) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '2048',
      subtitle: '滑动或方向键合并相同数字',
      children: [
        ToolCard(
          children: [
            Row(
              children: [
                Text('得分 $_score',
                    style: Ty.small.copyWith(
                        color: context.t1, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('最高 $_best', style: Ty.small.copyWith(color: context.t3)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final side = min(box.maxWidth, 340.0);
                return Center(
                  child: GestureDetector(
                    // 滑动识别：按松手时的累计位移判断主方向
                    onPanUpdate: (d) {
                      _dragStart += d.delta;
                    },
                    onPanEnd: (_) {
                      final dx = _dragStart.dx;
                      final dy = _dragStart.dy;
                      _dragStart = Offset.zero;
                      if (dx.abs() < 18 && dy.abs() < 18) return;
                      if (dx.abs() > dy.abs()) {
                        _doMove(dx > 0 ? 'right' : 'left');
                      } else {
                        _doMove(dy > 0 ? 'down' : 'up');
                      }
                    },
                    child: Container(
                      width: side,
                      height: side,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF26292E)
                            : const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(R.md),
                      ),
                      child: Column(
                        children: List.generate(n, (y) {
                          return Expanded(
                            child: Row(
                              children: List.generate(n, (x) {
                                final v = _g[y][x];
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 110),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: v == 0
                                            ? (context.isDark
                                                ? Colors.white.withAlpha(8)
                                                : Colors.white.withAlpha(72))
                                            : _tileColor(v),
                                        borderRadius:
                                            BorderRadius.circular(R.xs),
                                      ),
                                      child: v == 0
                                          ? null
                                          : FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text('$v',
                                                  style: TextStyle(
                                                      fontSize: v >= 1024
                                                          ? 20
                                                          : (v >= 128 ? 24 : 28),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: _textColor(v))),
                                            ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_over)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ToolResult(
                  title: '无路可走',
                  content: '本局得分：$_score\n最高得分：$_best',
                  color: C.danger,
                ),
              ),
          ],
        ),
        ToolCard(
          title: '控制',
          icon: Icons.grid_4x4_rounded,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PadKey(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => _doMove('left')),
                const SizedBox(width: 10),
                _PadKey(
                    icon: Icons.arrow_upward_rounded,
                    onTap: () => _doMove('up')),
                const SizedBox(width: 10),
                _PadKey(
                    icon: Icons.arrow_downward_rounded,
                    onTap: () => _doMove('down')),
                const SizedBox(width: 10),
                _PadKey(
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => _doMove('right')),
              ],
            ),
            const SizedBox(height: 14),
            ToolButton(
              label: '重新开始',
              icon: Icons.refresh_rounded,
              color: C.danger,
              onPressed: _reset,
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  14. 画板
// ═══════════════════════════════════════════════════════════

/// 简易画板：手指涂鸦，可切换颜色 / 粗细，可撤销与清空
class DrawBoardTool extends StatefulWidget {
  const DrawBoardTool({super.key});
  @override
  State<DrawBoardTool> createState() => _DrawBoardToolState();
}

class _DrawBoardToolState extends State<DrawBoardTool> {
  /// 所有笔画（每笔是一条点集）
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  Color _color = const Color(0xFF14161E);
  double _width = 4;

  static const List<Color> _colors = [
    Color(0xFF14161E),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF4B5EF5),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFFFFFF),
  ];

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '画板',
      subtitle: '手指涂鸦 · 可切换颜色',
      children: [
        ToolCard(
          children: [
            // 画布：用 LayoutBuilder 拿到真实尺寸，指示选择器按序渲染
            AspectRatio(
              aspectRatio: 0.78,
              child: LayoutBuilder(
                builder: (context, box) {
                  return GestureDetector(
                    onPanStart: (d) {
                      setState(() => _current = [d.localPosition]);
                    },
                    onPanUpdate: (d) {
                      setState(() => _current.add(d.localPosition));
                    },
                    onPanEnd: (_) {
                      setState(() {
                        if (_current.length > 1) {
                          _strokes.add(List.of(_current));
                        }
                        _current = [];
                      });
                    },
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: context.isDark ? C.bg1 : Colors.white,
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(
                            color: context.isDark
                                ? Colors.white.withAlpha(20)
                                : Colors.black.withAlpha(10)),
                      ),
                      child: CustomPaint(
                        size: Size(box.maxWidth, box.maxHeight),
                        painter: _DrawPainter(
                          strokes: _strokes,
                          current: _current,
                          color: _color,
                          width: _width,
                          canvasSize: Size(box.maxWidth, box.maxHeight),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('颜色', style: Ty.tiny.copyWith(color: context.t3)),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: _colors
                        .map((c) => GestureDetector(
                              onTap: () => setState(() => _color = c),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color == c
                                        ? C.brand
                                        : (context.isDark
                                            ? Colors.white.withAlpha(40)
                                            : Colors.black.withAlpha(20)),
                                    width: _color == c ? 2.5 : 1,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('粗细', style: Ty.tiny.copyWith(color: context.t3)),
                Expanded(
                  child: _ToolSlider(
                    value: _width,
                    min: 1,
                    max: 20,
                    onChanged: (v) => setState(() => _width = v),
                  ),
                ),
                SizedBox(
                    width: 30,
                    child: Text('${_width.round()}',
                        textAlign: TextAlign.right,
                        style: Ty.tiny.copyWith(color: context.t1))),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ToolButton(
                label: '撤销一笔',
                icon: Icons.arrow_back_rounded,
                color: C.amber,
                onPressed: _strokes.isEmpty ? null : _undo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ToolButton(
                label: '清空画板',
                icon: Icons.delete_outline_rounded,
                color: C.danger,
                onPressed: _strokes.isEmpty ? null : _clear,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ToolResult(
          title: '提示',
          content: '共 ${_strokes.length} 笔。'
              '需要保存图片时可直接截图，本页不写入相册。',
          color: C.cyan,
        ),
      ],
    );
  }
}

/// 画板绘制：历史笔画 + 当前笔画
class _DrawPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color color;
  final Color? bg;
  final double width;
  final Size canvasSize;
  const _DrawPainter({
    required this.strokes,
    required this.current,
    required this.color,
    required this.width,
    required this.canvasSize,
    this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bg != null) canvas.drawRect(Offset.zero & size, Paint()..color = bg!);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      _drawStroke(canvas, s, paint);
    }
    _drawStroke(canvas, current, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, width / 2, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawPainter old) => true;
}

// ═══════════════════════════════════════════════════════════
//  15. 电子琴
// ═══════════════════════════════════════════════════════════

/// 电子琴：一组琴键，点击有按压高亮 + 震动反馈
///
/// ★ 降级说明：项目未引入音频播放插件（audioplayers 等），也没有内置音效资源，
///   所以这里用「按压高亮动画 + HapticFeedback」做发声占位；
///   接入音频插件后把 _play() 换成播放对应音高的音频即可。
class PianoTool extends StatefulWidget {
  const PianoTool({super.key});
  @override
  State<PianoTool> createState() => _PianoToolState();
}

class _PianoToolState extends State<PianoTool> {
  /// 白键音名（两个八度）
  static const List<String> _white = [
    'C', 'D', 'E', 'F', 'G', 'A', 'B',
    'C2', 'D2', 'E2', 'F2', 'G2', 'A2', 'B2',
  ];

  /// 各白键的半音序号（用于估算频率）
  static const List<int> _semi = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];

  /// 白键后面是否跟着黑键（E、B 后面没有）
  static bool _hasBlack(String name) =>
      !name.startsWith('E') && !name.startsWith('B');

  int _active = -1;
  Timer? _clearTimer;

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  /// 按下琴键：震动 + 高亮 180ms
  void _play(int index) {
    HapticFeedback.lightImpact();
    setState(() => _active = index);
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _active = -1);
    });
  }

  /// 白键近似频率（C4 = 261.63Hz，十二平均律递推）
  String _freq(int i) {
    final f = 261.63 * pow(2, _semi[i] / 12);
    return f.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '电子琴',
      subtitle: '点击琴键 · 震动反馈',
      children: [
        ToolCard(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // 白键
                  Row(
                    children: List.generate(_white.length, (i) {
                      final on = _active == i;
                      return Expanded(
                        child: GestureDetector(
                          onTapDown: (_) => _play(i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              gradient: on
                                  ? LinearGradient(colors: [
                                      C.brand.withAlpha(200),
                                      C.accent.withAlpha(200),
                                    ])
                                  : null,
                              color: on ? null : Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(R.sm)),
                              border: Border.all(
                                  color: Colors.black.withAlpha(30),
                                  width: 0.8),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(_white[i],
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: on
                                            ? Colors.white
                                            : Colors.black.withAlpha(120))),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _active < 0
                    ? '按下琴键开始'
                    : '正在弹奏：${_white[_active]}（${_freq(_active)} Hz）',
                style: Ty.small.copyWith(
                    color: _active < 0 ? context.t3 : C.brand,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        ToolCard(
          title: '音阶演示片段',
          icon: Icons.piano_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['小星星', '音阶上下行', '生日快乐']
                  .map((name) => GestureDetector(
                        onTap: () => ToastUtil.info('「$name」需要音频插件支持，当前为占位'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: C.brand.withAlpha(context.isDark ? 30 : 16),
                            borderRadius: BorderRadius.circular(R.full),
                          ),
                          child: Text(name,
                              style: TextStyle(fontSize: 12, color: C.brand)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '提示：当前项目未引入音频播放依赖，琴键以震动 + 高亮代替发声。'
              '接入 audioplayers 并放入 .wav 音源后即可真实发声。',
              style: TextStyle(fontSize: 12.5, height: 1.8, color: context.t2),
            ),
          ],
        ),
        if (_showHint)
          ToolResult(
            title: '曲谱映射',
            content: '小星星：C C G G A A G — F F E E D D C\n'
                '音阶：C D E F G A B C2',
            color: C.cyan,
          ),
      ],
    );
  }

  static const bool _showHint = true;
}

// ═══════════════════════════════════════════════════════════
//  16. 手持弹幕
// ═══════════════════════════════════════════════════════════

/// 手持弹幕：输入文字 → 进入全屏横向滚动（可调速度、字号与颜色）
///
/// ★ 全屏页由本文件内的私有组件 _DanmakuWindow 承载，
///   用 AnimationController + Transform 自己做滚动（不依赖 marquee 包）。
class DanmakuTool extends StatefulWidget {
  const DanmakuTool({super.key});
  @override
  State<DanmakuTool> createState() => _DanmakuToolState();
}

class _DanmakuToolState extends State<DanmakuTool> {
  final _in = TextEditingController(text: '你好呀 ✨');
  Color _color = Colors.white;
  double _speed = 90; // 每秒滚动像素
  double _fontSize = 96;

  static const List<Color> _colors = [
    Colors.white,
    Color(0xFFFFD54F),
    Color(0xFFFF6B6B),
    Color(0xFF4B5EF5),
    Color(0xFF34D399),
    Color(0xFFEC4899),
    Color(0xFF22D3EE),
  ];

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// 进入全屏滚动页
  void _play() {
    final text = _in.text.trim();
    if (text.isEmpty) {
      ToastUtil.error('请输入弹幕文字');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DanmakuWindow(
          text: text,
          color: _color,
          speed: _speed,
          fontSize: _fontSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _in.text.trim();
    return ToolScaffold(
      title: '手持弹幕',
      subtitle: '全屏横向滚动大字',
      children: [
        ToolCard(
          title: '弹幕内容',
          icon: Icons.subtitles_rounded,
          children: [
            ToolField(
              controller: _in,
              hint: '输入要显示的文字',
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text('颜色', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            Row(
              children: _colors
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == c
                                  ? C.brand
                                  : Colors.black.withAlpha(30),
                              width: _color == c ? 2.5 : 1,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('速度', style: Ty.tiny.copyWith(color: context.t3)),
                Expanded(
                  child: _ToolSlider(
                    value: _speed,
                    min: 30,
                    max: 300,
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ),
                Text('${_speed.round()}',
                    style: Ty.tiny.copyWith(color: context.t1)),
              ],
            ),
            Row(
              children: [
                Text('字号', style: Ty.tiny.copyWith(color: context.t3)),
                Expanded(
                  child: _ToolSlider(
                    value: _fontSize,
                    min: 48,
                    max: 200,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                Text('${_fontSize.round()}',
                    style: Ty.tiny.copyWith(color: context.t1)),
              ],
            ),
          ],
        ),
        // 预览条：不做真实滚动，仅按宽度等比缩放
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(R.lg),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  preview.isEmpty ? '请输入文字' : preview,
                  style: TextStyle(
                      color: _color,
                      fontSize: 44,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
        ToolButton(
          label: '全屏滚动播放',
          icon: Icons.play_arrow_rounded,
          onPressed: _play,
        ),
        const SizedBox(height: 14),
        ToolResult(
          title: '提示',
          content: '进入全屏后点击屏幕任意位置即可退出。\n'
              '现场应援建议把手机亮度调到最高。',
          color: C.cyan,
        ),
      ],
    );
  }
}

/// 全屏弹幕窗口（私有组件，不对外导出）
class _DanmakuWindow extends StatefulWidget {
  final String text;
  final Color color;
  final double speed;
  final double fontSize;
  const _DanmakuWindow({
    required this.text,
    required this.color,
    required this.speed,
    required this.fontSize,
  });

  @override
  State<_DanmakuWindow> createState() => _DanmakuWindowState();
}

class _DanmakuWindowState extends State<_DanmakuWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    // 全屏沉浸：隐藏状态栏与底部指示条（退出时恢复）
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: LayoutBuilder(
          builder: (context, box) {
            // 先量出文字宽度，用于计算滚动总路程
            final tp = TextPainter(
              text: TextSpan(
                text: widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  color: widget.color,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            final textWidth = tp.width + 60;
            final total = box.maxWidth + textWidth;
            // 时长 = 总路程 / 速度（限制在 1.5~30 秒）
            final seconds = (total / widget.speed).clamp(1.5, 30.0);
            final ms = (seconds * 1000).round();
            if (_ctrl.duration!.inMilliseconds != ms) {
              _ctrl.duration = Duration(milliseconds: ms);
              _ctrl.repeat();
            }
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                // 从右边缘外侧滚到左边缘外侧
                final dx = box.maxWidth - total * _ctrl.value;
                return Stack(
                  children: [
                    Positioned(
                      left: dx,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w900,
                            color: widget.color,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: MediaQuery.of(context).padding.top + 8,
                      child: Text('点击退出',
                          style: TextStyle(
                              color: Colors.white.withAlpha(60),
                              fontSize: 12)),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  17. 文字转图片
// ═══════════════════════════════════════════════════════════

/// 文字转图片：输入文字 → 生成一张可预览 / 可复制的文字卡片
///
/// ★ 降级说明：在不落盘、不引入额外渲染链路的前提下，把 Widget 转成 PNG 需要
///   RepaintBoundary.toImage 配合相册/分享插件，因此这里降级为
///   「样式可调的预览卡片 + 复制文字」，调好样式后截图即可分享。
class TextImageTool extends StatefulWidget {
  const TextImageTool({super.key});
  @override
  State<TextImageTool> createState() => _TextImageToolState();
}

class _TextImageToolState extends State<TextImageTool> {
  final _in = TextEditingController(text: '把想说的话，做成一张好看的卡片');
  double _fontSize = 20;
  double _pad = 26;
  int _align = 1; // 0 左 / 1 中 / 2 右
  int _theme = 0;

  /// 卡片背景主题（渐变起止色）
  static const List<List<Color>> _themes = [
    [Color(0xFFFFFFFF), Color(0xFFF4F6FB)],
    [Color(0xFF141721), Color(0xFF232838)],
    [Color(0xFF4B5EF5), Color(0xFFA78BFA)],
    [Color(0xFFFF8A65), Color(0xFFFFB74D)],
    [Color(0xFF0F172A), Color(0xFF1E293B)],
  ];

  static const List<String> _themeNames = ['简约白', '暗夜黑', '品牌蓝紫', '暖阳橙', '深空'];

  TextAlign get _ta =>
      _align == 0 ? TextAlign.left : (_align == 1 ? TextAlign.center : TextAlign.right);

  Alignment get _alignPos => _align == 0
      ? Alignment.centerLeft
      : (_align == 1 ? Alignment.center : Alignment.centerRight);

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _themes[_theme];
    // 深色底的主题用浅色字
    final darkBg = _theme == 1 || _theme == 2 || _theme == 4;
    final textColor = darkBg ? Colors.white : const Color(0xFF14161E);
    final text = _in.text.trim();

    return ToolScaffold(
      title: '文字转图片',
      subtitle: '生成文字卡片 · 调好后截图分享',
      children: [
        ToolCard(
          title: '卡片内容',
          icon: Icons.text_fields_rounded,
          children: [
            ToolField(
              controller: _in,
              hint: '输入卡片文字',
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('背景主题', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            _ChipBar(
              labels: _themeNames,
              index: _theme,
              onChanged: (i) => setState(() => _theme = i),
            ),
            const SizedBox(height: 14),
            Text('对齐方式', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            _ChipBar(
              labels: const ['左对齐', '居中', '右对齐'],
              index: _align,
              onChanged: (i) => setState(() => _align = i),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('字号', style: Ty.tiny.copyWith(color: context.t3)),
                Expanded(
                  child: _ToolSlider(
                    value: _fontSize,
                    min: 12,
                    max: 40,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                Text('${_fontSize.round()}',
                    style: Ty.tiny.copyWith(color: context.t1)),
              ],
            ),
            Row(
              children: [
                Text('留白', style: Ty.tiny.copyWith(color: context.t3)),
                Expanded(
                  child: _ToolSlider(
                    value: _pad,
                    min: 12,
                    max: 60,
                    onChanged: (v) => setState(() => _pad = v),
                  ),
                ),
                Text('${_pad.round()}',
                    style: Ty.tiny.copyWith(color: context.t1)),
              ],
            ),
          ],
        ),
        ToolCard(
          title: '预览',
          icon: Icons.image_rounded,
          children: [
            // 卡片本体：4:3，接近截图分享的常用比例
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                padding: EdgeInsets.all(_pad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: bg,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(R.lg),
                  border: Border.all(
                      color: darkBg
                          ? Colors.white.withAlpha(26)
                          : Colors.black.withAlpha(10)),
                ),
                child: Align(
                  alignment: _alignPos,
                  child: Text(
                    text.isEmpty ? '请输入文字' : text,
                    textAlign: _ta,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.6,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('需要导出 PNG 时直接截图即可，本页不写入相册。',
                style: Ty.tiny.copyWith(color: context.t3)),
          ],
        ),
        ToolButton(
          label: '复制卡片文字',
          icon: Icons.copy_rounded,
          onPressed: () {
            if (text.isEmpty) {
              ToastUtil.error('内容为空');
              return;
            }
            copyText(text);
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  18. ARGB / HEX 颜色转换
// ═══════════════════════════════════════════════════════════

/// ARGB / HEX 颜色互转：输入任一写法，实时得到其它格式与色块
class ArgBTool extends StatefulWidget {
  const ArgBTool({super.key});
  @override
  State<ArgBTool> createState() => _ArgBToolState();
}

class _ArgBToolState extends State<ArgBTool> {
  final _in = TextEditingController(text: '0xFF4B5EF5');
  Color _color = const Color(0xFF4B5EF5);
  String _err = '';

  /// 常用色（点击直接填入）
  static const List<Color> _quick = [
    Color(0xFF4B5EF5),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF22D3EE),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFF14161E),
  ];

  @override
  void initState() {
    super.initState();
    _parse(_in.text);
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// 单个分量 → 两位十六进制
  String _hex2(int v) =>
      v.clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();

  /// 把 Color 的 0~1 分量还原为 0~255
  int _c8(double v) => (v * 255).round();

  /// 解析多种写法：#RRGGBB / 0xAARRGGBB / AARRGGBB / rgb(r,g,b)
  void _parse(String raw) {
    final s = raw.trim().replaceAll('#', '');
    if (s.isEmpty) {
      setState(() => _err = '');
      return;
    }
    try {
      if (s.toLowerCase().startsWith('rgb')) {
        // rgb(75,94,245) 或 rgba(75,94,245,255)
        final nums = RegExp(r'\d+')
            .allMatches(s)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        if (nums.length < 3) {
          setState(() => _err = 'rgb() 参数不足');
          return;
        }
        final a = nums.length >= 4 ? nums[3] : 255;
        setState(() {
          _color = Color.fromARGB(a, nums[0], nums[1], nums[2]);
          _err = '';
        });
        return;
      }
      final hex = s.replaceAll(' ', '');
      if (hex.length == 3) {
        // F5A → FF55AA
        final e = hex.split('').map((c) => '$c$c').join();
        setState(() {
          _color = Color(0xFF000000 | int.parse(e, radix: 16));
          _err = '';
        });
        return;
      }
      if (hex.length == 6) {
        setState(() {
          _color = Color(0xFF000000 | int.parse(hex, radix: 16));
          _err = '';
        });
        return;
      }
      if (hex.length == 8) {
        setState(() {
          _color = Color(int.parse(hex, radix: 16));
          _err = '';
        });
        return;
      }
      if (hex.length == 10 && hex.toUpperCase().startsWith('0X')) {
        setState(() {
          _color = Color(int.parse(hex.substring(2), radix: 16));
          _err = '';
        });
        return;
      }
      setState(() => _err = '无法识别，请输入 6/8 位 HEX 或 rgb(...)');
    } catch (e) {
      setState(() => _err = '解析失败：$e');
    }
  }

  /// => #AARRGGBB
  String get _hex8 => '#${_hex2(_c8(_color.a))}'
      '${_hex2(_c8(_color.r))}${_hex2(_c8(_color.g))}${_hex2(_c8(_color.b))}';

  /// => #RRGGBB
  String get _hex6 =>
      '#${_hex2(_c8(_color.r))}${_hex2(_c8(_color.g))}${_hex2(_c8(_color.b))}';

  /// => 0xAARRGGBB（Flutter 字面量）
  String get _literal => '0x${_hex2(_c8(_color.a))}'
      '${_hex2(_c8(_color.r))}${_hex2(_c8(_color.g))}${_hex2(_c8(_color.b))}';

  /// => rgb(r, g, b) / rgba(r, g, b, a)
  String get _rgb => _c8(_color.a) >= 255
      ? 'rgb(${_c8(_color.r)}, ${_c8(_color.g)}, ${_c8(_color.b)})'
      : 'rgba(${_c8(_color.r)}, ${_c8(_color.g)}, ${_c8(_color.b)}, '
          '${(_color.a * 100).round() / 100})';

  @override
  Widget build(BuildContext context) {
    final light = _color.computeLuminance() > 0.6;
    return ToolScaffold(
      title: 'ARGB / HEX 转换',
      subtitle: '颜色格式互转 · 实时预览',
      children: [
        ToolCard(
          title: '输入色值',
          icon: Icons.colorize_rounded,
          children: [
            ToolField(
              controller: _in,
              hint: '如 0xFF4B5EF5 / #4B5EF5 / rgb(75,94,245)',
              onChanged: _parse,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quick
                  .map((q) => GestureDetector(
                        onTap: () {
                          setState(() => _in.text = _hexOf(q));
                          _parse(_hexOf(q));
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: q,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black.withAlpha(30)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            if (_err.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_err, style: TextStyle(fontSize: 12.5, color: C.danger)),
            ],
          ],
        ),
        ToolCard(
          title: '色块预览',
          icon: Icons.palette_rounded,
          children: [
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: Colors.black.withAlpha(24)),
              ),
              alignment: Alignment.center,
              child: Text(
                _hex6,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: light ? const Color(0xFF14161E) : Colors.white,
                ),
              ),
            ),
          ],
        ),
        ToolCard(
          title: '各格式结果（点击可复制）',
          icon: Icons.code_rounded,
          children: [
            _row('HEX(A)8位', _hex8),
            _row('HEX(6位)', _hex6),
            _row('Flutter', _literal),
            _row('ARGB 分量', '${_c8(_color.a)}, ${_c8(_color.r)}, '
                '${_c8(_color.g)}, ${_c8(_color.b)}'),
            _row('CSS', _rgb),
            const SizedBox(height: 8),
            ToolResult(
              title: '全部结果',
              content: 'HEX8：$_hex8\n'
                  'HEX6：$_hex6\n'
                  'Flutter：Color($_literal)\n'
                  'CSS：$_rgb',
            ),
          ],
        ),
      ],
    );
  }

  /// 取某个预设色的 8 位 HEX 文本（用于回填输入框）
  String _hexOf(Color c) =>
      '0x${_hex2(_c8(c.a))}${_hex2(_c8(c.r))}${_hex2(_c8(c.g))}${_hex2(_c8(c.b))}';

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Ty.tiny.copyWith(color: context.t3)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => copyText(value),
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.t1)),
            ),
          ),
          Icon(Icons.copy_rounded, size: 14, color: context.t3),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  19. Material 配色
// ═══════════════════════════════════════════════════════════

/// Material 配色：展示常用主色的 10 级色阶，点击色块复制色值
class MdColorTool extends StatefulWidget {
  const MdColorTool({super.key});
  @override
  State<MdColorTool> createState() => _MdColorToolState();
}

class _MdColorToolState extends State<MdColorTool> {
  /// Material 常用主色（名称 → 500 基准色）
  static const List<MapEntry<String, Color>> _seeds = [
    MapEntry('Red', Color(0xFFF44336)),
    MapEntry('Pink', Color(0xFFE91E63)),
    MapEntry('Purple', Color(0xFF9C27B0)),
    MapEntry('Deep Purple', Color(0xFF673AB7)),
    MapEntry('Indigo', Color(0xFF3F51B5)),
    MapEntry('Blue', Color(0xFF2196F3)),
    MapEntry('Light Blue', Color(0xFF03A9F4)),
    MapEntry('Cyan', Color(0xFF00BCD4)),
    MapEntry('Teal', Color(0xFF009688)),
    MapEntry('Green', Color(0xFF4CAF50)),
    MapEntry('Light Green', Color(0xFF8BC34A)),
    MapEntry('Lime', Color(0xFFCDDC39)),
    MapEntry('Yellow', Color(0xFFFFEB3B)),
    MapEntry('Amber', Color(0xFFFFC107)),
    MapEntry('Orange', Color(0xFFFF9800)),
    MapEntry('Deep Orange', Color(0xFFFF5722)),
    MapEntry('Brown', Color(0xFF795548)),
    MapEntry('Grey', Color(0xFF9E9E9E)),
    MapEntry('Blue Grey', Color(0xFF607D8B)),
    MapEntry('Black', Color(0xFF000000)),
  ];

  /// Material 标准色阶
  static const List<int> _levels = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];

  /// 生成 50~900 色阶：以 500 为种子，向下混白、向上混黑
  List<Color> _swatches(Color seed) {
    return _levels.map((lv) {
      final t = (lv - 500) / 400;
      if (t < 0) return Color.lerp(seed, Colors.white, -t * 0.85)!;
      return Color.lerp(seed, Colors.black, t * 0.65)!;
    }).toList();
  }

  String _hex(Color c) =>
      '#${_h2(c.r)}${_h2(c.g)}${_h2(c.b)}';

  String _h2(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Material 配色',
      subtitle: '点击色块复制色值 · 共 ${_seeds.length} 种主色',
      children: [
        for (final e in _seeds)
          ToolCard(
            title: e.key,
            trailing: Text(_hex(_swatches(e.value)[5]),
                style: Ty.tiny.copyWith(
                    color: C.brand, fontWeight: FontWeight.w800)),
            children: [
              _mainSwatch(e.value),
              const SizedBox(height: 6),
              _levelRow(e.value),
            ],
          ),
      ],
    );
  }

  /// 500 主色大色块
  Widget _mainSwatch(Color seed) {
    final c = _swatches(seed)[5];
    return GestureDetector(
      onTap: () => copyText('500  ${_hex(c)}'),
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(R.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          '500  ${_hex(c)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: c.computeLuminance() > 0.6
                ? const Color(0xFF14161E)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  /// 10 级色阶小色块（点击复制）
  Widget _levelRow(Color seed) {
    final list = _swatches(seed);
    return Row(
      children: List.generate(list.length, (i) {
        final c = list[i];
        final lightText = c.computeLuminance() > 0.6;
        return Expanded(
          child: GestureDetector(
            onTap: () => copyText('${_levels[i]}  ${_hex(c)}'),
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(6) : Radius.zero,
                  bottom: i == list.length - 1
                      ? const Radius.circular(6)
                      : Radius.zero,
                ),
              ),
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${_levels[i]}',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: lightText
                        ? const Color(0xFF14161E).withAlpha(150)
                        : Colors.white.withAlpha(180),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  20. 设备信息
// ═══════════════════════════════════════════════════════════

/// 设备信息
///
/// ★ 使用项目 pubspec 中已有的 device_info_plus（未新增依赖）；
///   读取失败时自动降级为 dart:io 的 Platform + dart:ui 的屏幕信息。
class DeviceInfoTool extends StatefulWidget {
  const DeviceInfoTool({super.key});
  @override
  State<DeviceInfoTool> createState() => _DeviceInfoToolState();
}

class _DeviceInfoToolState extends State<DeviceInfoTool> {
  final List<List<String>> _rows = [];
  bool _loading = true;
  String _model = '未知设备';
  String _os = '未知系统';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = <List<String>>[];

    // ① 屏幕 / 密度（dart:ui，始终可用）
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final d = MediaQueryData.fromView(view);
    final size = d.size;
    rows.add(['屏幕尺寸', '${size.width.toStringAsFixed(0)} × '
        '${size.height.toStringAsFixed(0)} pt']);
    rows.add(['像素比', d.devicePixelRatio.toStringAsFixed(2)]);
    rows.add(['物理像素', '${(size.width * d.devicePixelRatio).toStringAsFixed(0)} × '
        '${(size.height * d.devicePixelRatio).toStringAsFixed(0)} px']);
    rows.add(['安全区', '上 ${d.padding.top.toStringAsFixed(0)} / '
        '下 ${d.padding.bottom.toStringAsFixed(0)}']);

    // ② 平台信息（dart:io，始终可用）
    rows.add(['操作系统', Platform.operatingSystem]);
    rows.add(['系统版本', Platform.operatingSystemVersion]);
    rows.add(['本地语言', Platform.localeName]);
    rows.add(['CPU 核数', '${Platform.numberOfProcessors}']);
    rows.add(['Dart 版本', Platform.version.split(' ').first]);

    // ③ device_info_plus（读取失败则跳过，不影响其它字段）
    try {
      final p = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await p.androidInfo;
        _model = '${a.brand} ${a.model}'.trim();
        _os = 'Android ${a.version.release}（API ${a.version.sdkInt}）';
        rows.insert(0, ['设备型号', _model]);
        rows.insert(1, ['系统版本', _os]);
        rows.add(['设备品牌', a.brand]);
        rows.add(['制造商', a.manufacturer]);
        rows.add(['主板', a.board]);
        rows.add(['是否物理设备', a.isPhysicalDevice ? '是' : '否']);
        rows.add(['支持的 ABI', a.supportedAbis.join(' / ')]);
      } else if (Platform.isIOS) {
        final i = await p.iosInfo;
        _model = i.utsname.machine;
        _os = 'iOS ${i.systemVersion}';
        rows.insert(0, ['设备型号', '${i.name}（${i.utsname.machine}）']);
        rows.insert(1, ['系统版本', _os]);
        rows.add(['设备名', i.name]);
        rows.add(['机型标识', i.model]);
        rows.add(['是否物理设备', i.isPhysicalDevice ? '是' : '否']);
      } else {
        rows.add(['设备信息', '当前平台不支持 device_info 查询']);
      }
    } catch (e) {
      rows.add(['device_info_plus', '读取失败：$e']);
    }

    if (!mounted) return;
    setState(() {
      _rows
        ..clear()
        ..addAll(rows);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '设备信息',
      subtitle: '型号 / 系统 / 屏幕参数',
      actions: [
        IconButton(
          onPressed: () {
            setState(() => _loading = true);
            _load();
          },
          icon: Icon(Icons.refresh_rounded, color: context.t2),
        ),
      ],
      children: [
        ToolCard(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.brand.withAlpha(context.isDark ? 40 : 22),
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                  child: Icon(Icons.phone_android_rounded,
                      size: 26, color: C.brand),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Ty.h3.copyWith(color: context.t1)),
                      const SizedBox(height: 2),
                      Text(_os,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Ty.tiny.copyWith(color: context.t3)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        ToolCard(
          title: '详细信息',
          icon: Icons.bar_chart_rounded,
          children: _loading
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ]
              : [
                  for (final r in _rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(r[0],
                                style: Ty.tiny.copyWith(color: context.t3)),
                          ),
                          Expanded(
                            child: SelectableText(r[1],
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.t1)),
                          ),
                        ],
                      ),
                    ),
                ],
        ),
        if (!_loading)
          ToolButton(
            label: '复制全部信息',
            icon: Icons.copy_rounded,
            onPressed: () {
              final sb = StringBuffer();
              sb.writeln('$_model / $_os');
              for (final r in _rows) {
                sb.writeln('${r[0]}：${r[1]}');
              }
              copyText(sb.toString().trimRight());
            },
          ),
        const SizedBox(height: 14),
        ToolResult(
          title: '说明',
          content: '· 型号 / 系统来自项目已有依赖 device_info_plus\n'
              '· 屏幕参数来自 dart:ui，Dart 版本来自 dart:io\n'
              '· 部分字段在模拟器上会显示为 generic',
          color: C.cyan,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  21. 屏幕坏点检测
// ═══════════════════════════════════════════════════════════

/// 屏幕坏点检测：全屏纯色轮播
///
/// 进入全屏后：单击切换下一个颜色，双击退出。
class DeadPixelTool extends StatefulWidget {
  const DeadPixelTool({super.key});
  @override
  State<DeadPixelTool> createState() => _DeadPixelToolState();
}

class _DeadPixelToolState extends State<DeadPixelTool> {
  /// 待检测的纯色（名称 → 颜色）
  static const List<MapEntry<String, Color>> _colors = [
    MapEntry('红', Color(0xFFFF0000)),
    MapEntry('绿', Color(0xFF00FF00)),
    MapEntry('蓝', Color(0xFF0000FF)),
    MapEntry('白', Color(0xFFFFFFFF)),
    MapEntry('黑', Color(0xFF000000)),
    MapEntry('青', Color(0xFF00FFFF)),
    MapEntry('洋红', Color(0xFFFF00FF)),
    MapEntry('黄', Color(0xFFFFFF00)),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cur = _colors[_index];
    final lightText = cur.value.computeLuminance() > 0.6;
    return ToolScaffold(
      title: '坏点检测',
      subtitle: '纯色轮播 · 全屏检测',
      children: [
        ToolCard(
          title: '颜色预览（点击切换下一个）',
          icon: Icons.broken_image_outlined,
          children: [
            GestureDetector(
              onTap: () => setState(() => _index = (_index + 1) % _colors.length),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cur.value,
                  borderRadius: BorderRadius.circular(R.md),
                  border: Border.all(color: Colors.black.withAlpha(26)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cur.key}（${_index + 1}/${_colors.length}）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: lightText ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_colors.length, (i) {
                final e = _colors[i];
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _index == i
                            ? C.brand
                            : Colors.black.withAlpha(30),
                        width: _index == i ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        ToolCard(
          title: '操作',
          icon: Icons.check_circle_outline_rounded,
          children: [
            ToolButton(
              label: '全屏检测（单击换色 / 双击退出）',
              icon: Icons.fullscreen_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _DeadPixelFull(
                    start: _index,
                    colors: _colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '上一个颜色',
              icon: Icons.arrow_back_rounded,
              color: C.cyan,
              onPressed: () => setState(
                  () => _index = (_index - 1 + _colors.length) % _colors.length),
            ),
          ],
        ),
        ToolResult(
          title: '怎么看坏点',
          content: '· 依次切换纯色，仔细观察是否有不随颜色变化的亮点 / 暗点\n'
              '· 白底找黑点（坏点），黑底找亮点（亮点或进灰）\n'
              '· 检测前请擦净屏幕，并把亮度调到最高',
          color: C.cyan,
        ),
      ],
    );
  }
}

/// 全屏纯色检测页（私有组件）
class _DeadPixelFull extends StatefulWidget {
  final int start;
  final List<MapEntry<String, Color>> colors;
  const _DeadPixelFull({required this.start, required this.colors});

  @override
  State<_DeadPixelFull> createState() => _DeadPixelFullState();
}

class _DeadPixelFullState extends State<_DeadPixelFull> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _i = widget.start;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.colors[_i];
    final lightText = cur.value.computeLuminance() > 0.6;
    return Scaffold(
      backgroundColor: cur.value,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            setState(() => _i = (_i + 1) % widget.colors.length),
        onDoubleTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: Text(
            '单击切换颜色 · 双击退出\n'
            '${cur.key}（${_i + 1}/${widget.colors.length}）',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.9,
              fontWeight: FontWeight.w800,
              color: lightText
                  ? Colors.black.withAlpha(120)
                  : Colors.white.withAlpha(120),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  22. 电池信息
// ═══════════════════════════════════════════════════════════

/// 电池信息（降级实现）
///
/// ★ 说明：项目未引入 battery_plus，Flutter 标准库也没有读取电量 / 充电状态的
///   公开 API，因此这里无法给出真实电量，只展示「能拿到的」信息
///   （运行平台、屏幕尺寸等）并给出接入指引；
///   若后续添加 battery_plus，把 _load() 换成 Battery().batteryLevel 即可。
class BatteryTool extends StatefulWidget {
  const BatteryTool({super.key});
  @override
  State<BatteryTool> createState() => _BatteryToolState();
}

class _BatteryToolState extends State<BatteryTool> {
  final List<List<String>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final d = MediaQueryData.fromView(view);
    setState(() {
      _rows
        ..clear()
        ..add(['运行平台', Platform.operatingSystem])
        ..add(['系统版本', Platform.operatingSystemVersion])
        ..add(['屏幕尺寸',
            '${d.size.width.toStringAsFixed(0)} × ${d.size.height.toStringAsFixed(0)} pt'])
        ..add(['系统深色模式', d.platformBrightness == Brightness.dark ? '已开启' : '未开启'])
        ..add(['电量读取', '不可用（缺少 battery_plus 依赖）']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '电池信息',
      subtitle: '系统电池状态（降级展示）',
      actions: [
        IconButton(
          onPressed: _load,
          icon: Icon(Icons.refresh_rounded, color: context.t2),
        ),
      ],
      children: [
        ToolCard(
          children: [
            Column(
              children: [
                Icon(Icons.battery_charging_full_rounded,
                    size: 52, color: C.brand),
                const SizedBox(height: 10),
                Text('电量信息不可用', style: Ty.h3.copyWith(color: context.t1)),
                const SizedBox(height: 4),
                Text('当前项目未引入 battery_plus 依赖',
                    style: Ty.tiny.copyWith(color: context.t3)),
              ],
            ),
          ],
        ),
        ToolCard(
          title: '能获取到的信息',
          icon: Icons.bar_chart_rounded,
          children: [
            for (final r in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child:
                          Text(r[0], style: Ty.tiny.copyWith(color: context.t3)),
                    ),
                    Expanded(
                      child: Text(r[1],
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.t1)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        ToolCard(
          title: '如何接入真实电量',
          icon: Icons.info_outline_rounded,
          children: [
            Text(
              '1. 在 pubspec.yaml 添加依赖：battery_plus: ^6.0.0\n'
              '2. 代码中读取：\n'
              '     final level = await Battery().batteryLevel;\n'
              '     final state = await Battery().batteryState;\n'
              '3. iOS 需在 Info.plist 说明用途，Android 无需额外权限\n'
              '（本项目受「不新增依赖」约束，暂以占位形式展示）',
              style: TextStyle(
                  fontSize: 12.5, height: 1.9, color: context.t2),
            ),
          ],
        ),
        ToolResult(
          title: '也可以手动查看',
          content: 'iOS：设置 → 电池 → 电池健康\n'
              'Android：设置 → 电池（部分机型为「省电与电池」）',
          color: C.cyan,
        ),
      ],
    );
  }
}
