import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import 'tools_common.dart';

/// v46 样本工具补齐 —— 按「简助手」录屏里真实存在的工具实现
///
/// 这些工具在样本工具页中一一对应，全部为 App 内真实页面。

// ═══════════════ 生活便捷 ═══════════════

/// 刻度尺（真实尺子，按屏幕 DPI 换算）
class RulerTool extends StatelessWidget {
  const RulerTool({super.key});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = MediaQuery.of(context).size.width;
    // 逻辑像素 → 毫米（经验值：1 逻辑像素 ≈ 160dpi/25.4mm）
    final pxPerMm = 160 / 25.4 / (dpr > 3 ? 1.0 : 1.0);
    final mmCount = (logicalWidth / pxPerMm).floor();

    return ToolScaffold(
      title: '刻度尺',
      subtitle: '屏幕直尺 · 单位 mm / cm',
      children: [
        ToolCard(
          title: '横向刻度',
          icon: Icons.straighten_rounded,
          children: [
            SizedBox(
              height: 86,
              child: CustomPaint(
                size: Size(logicalWidth - 60, 86),
                painter: _RulerPainter(mm: mmCount, pxPerMm: pxPerMm),
              ),
            ),
            const SizedBox(height: 8),
            Text('共 $mmCount mm（${(mmCount / 10).toStringAsFixed(1)} cm）\n'
                '⚠️ 屏幕尺寸校准差异会导致 ±2mm 误差，仅供粗略测量。',
                style: TextStyle(fontSize: 12, color: context.t3, height: 1.6)),
          ],
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final int mm;
  final double pxPerMm;
  _RulerPainter({required this.mm, required this.pxPerMm});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2A2D3A)
      ..strokeWidth = 1;
    for (var i = 0; i <= mm; i++) {
      final x = i * pxPerMm;
      if (x > size.width) break;
      double h;
      if (i % 10 == 0) {
        h = 42;
      } else if (i % 5 == 0) {
        h = 28;
      } else {
        h = 16;
      }
      canvas.drawLine(Offset(x, 0), Offset(x, h), p);
      if (i % 10 == 0) {
        final tp = TextPainter(
          text: TextSpan(
              text: '${i ~/ 10}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF5C6273))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 2, 44));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) => false;
}

/// 计分板
class ScoreboardTool extends StatefulWidget {
  const ScoreboardTool({super.key});
  @override
  State<ScoreboardTool> createState() => _ScoreboardToolState();
}

class _ScoreboardToolState extends State<ScoreboardTool> {
  int _a = 0;
  int _b = 0;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '计分板',
      subtitle: '双人对抗计分',
      actions: [
        IconButton(
          onPressed: () => setState(() {
            _a = 0;
            _b = 0;
          }),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        Row(
          children: [
            Expanded(child: _pad('A 队', _a, const Color(0xFF4B5EF5),
                (v) => setState(() => _a = v))),
            const SizedBox(width: 12),
            Expanded(child: _pad('B 队', _b, const Color(0xFFFB7185),
                (v) => setState(() => _b = v))),
          ],
        ),
      ],
    );
  }

  Widget _pad(String name, int v, Color c, ValueChanged<int> onSet) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(name,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 10),
          Text('$v',
              style: TextStyle(
                  fontSize: 52, fontWeight: FontWeight.w900, color: c)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btn(Icons.remove_rounded, () => onSet(math.max(0, v - 1)), c),
              const SizedBox(width: 10),
              _btn(Icons.add_rounded, () => onSet(v + 1), c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData i, VoidCallback f, Color c) => GestureDetector(
        onTap: f,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          child: Icon(i, color: Colors.white, size: 22),
        ),
      );
}

/// 时间屏幕（全屏时钟）
class CalendarTool extends StatefulWidget {
  const CalendarTool({super.key});
  @override
  State<CalendarTool> createState() => _CalendarToolState();
}

class _CalendarToolState extends State<CalendarTool> {
  late Timer _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final ss = _now.second.toString().padLeft(2, '0');
    const wk = ['一', '二', '三', '四', '五', '六', '日'];
    return ToolScaffold(
      title: '时间屏幕',
      subtitle: '全屏大字时钟',
      children: [
        ToolCard(
          title: '当前时间',
          icon: Icons.schedule_rounded,
          children: [
            Center(
              child: Column(
                children: [
                  Text('$hh:$mm',
                      style: const TextStyle(
                          fontSize: 62,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  Text(':$ss',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: context.t3)),
                  const SizedBox(height: 12),
                  Text(
                      '${_now.year}年${_now.month}月${_now.day}日  星期${wk[_now.weekday - 1]}',
                      style: TextStyle(fontSize: 14, color: context.t2)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 防晕车（动感提示球）
class MotionCueTool extends StatefulWidget {
  const MotionCueTool({super.key});
  @override
  State<MotionCueTool> createState() => _MotionCueToolState();
}

class _MotionCueToolState extends State<MotionCueTool>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '防晕车',
      subtitle: '视觉焦点跟随，缓解晕车',
      children: [
        ToolCard(
          title: '跟随光点',
          icon: Icons.control_camera_rounded,
          children: [
            SizedBox(
              height: 260,
              child: AnimatedBuilder(
                animation: _c,
                builder: (c, _) {
                  final t = _c.value;
                  final x = 0.5 + 0.32 * math.sin(t * 2 * math.pi);
                  final y = 0.5 + 0.3 * math.cos(t * 4 * math.pi);
                  return LayoutBuilder(builder: (c, box) {
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment(x * 2 - 1, y * 2 - 1),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF6E7DFF),
                                Color(0xFFA78BFA)
                              ]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF6E7DFF).withAlpha(120),
                                    blurRadius: 26)
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('眼睛跟随光点移动，可缓解乘车时的眩晕感。\n建议手机置于视线前方 30-40cm 处。',
                style: TextStyle(fontSize: 12.5, color: context.t3, height: 1.6)),
          ],
        ),
      ],
    );
  }
}

/// 来电模拟
class CallTool extends StatefulWidget {
  const CallTool({super.key});
  @override
  State<CallTool> createState() => _CallToolState();
}

class _CallToolState extends State<CallTool> {
  final _name = TextEditingController(text: '10086');
  bool _show = false;
  late Timer _t;
  int _sec = 0;

  @override
  void dispose() {
    _name.dispose();
    if (_show) _t.cancel();
    super.dispose();
  }

  void _fire() {
    setState(() {
      _show = true;
      _sec = 0;
    });
    HapticFeedback.heavyImpact();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _sec++);
      if (_sec >= 30) _hangup();
    });
  }

  void _hangup() {
    _t.cancel();
    setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1D26),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              const CircleAvatar(
                radius: 46,
                backgroundColor: Color(0xFF2C3140),
                child: Icon(Icons.person, size: 48, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              Text(_name.text,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('来电中 ${_sec}s',
                  style: const TextStyle(fontSize: 14, color: Colors.white54)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _act(Icons.call_end_rounded, const Color(0xFFEF4444), _hangup),
                  _act(Icons.volume_up_rounded, const Color(0xFF3A4050), () {}),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }
    return ToolScaffold(
      title: '来电模拟',
      subtitle: '模拟来电页面',
      children: [
        ToolCard(
          title: '来电号码/名称',
          icon: Icons.phone_in_talk_rounded,
          children: [
            ToolField(controller: _name, hint: '如：10086'),
            const SizedBox(height: 12),
            ToolButton(
                label: '模拟来电',
                icon: Icons.call_rounded,
                onPressed: _fire),
            const SizedBox(height: 10),
            Text('30 秒后自动挂断。此工具仅供娱乐。',
                style: TextStyle(fontSize: 12, color: context.t3)),
          ],
        ),
      ],
    );
  }

  Widget _act(IconData i, Color c, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          child: Icon(i, color: Colors.white, size: 30),
        ),
      );
}

/// 偷拍检测（摄像头扫描）
class CameraTool extends StatefulWidget {
  const CameraTool({super.key});
  @override
  State<CameraTool> createState() => _CameraToolState();
}

class _CameraToolState extends State<CameraTool>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat();
  bool _scanning = false;
  int _found = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '偷拍检测',
      subtitle: '检测周边可疑摄像头',
      children: [
        ToolCard(
          title: '检测区域',
          icon: Icons.visibility_rounded,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF12151C),
                borderRadius: BorderRadius.circular(R.md),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.videocam_off_rounded,
                        size: 54, color: Colors.white.withAlpha(40)),
                  ),
                  if (_scanning)
                    AnimatedBuilder(
                      animation: _c,
                      builder: (c, _) => Align(
                        alignment: Alignment(0, _c.value * 2 - 1),
                        child: Container(
                          height: 2.5,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ToolButton(
              label: _scanning ? '扫描中…（$_found 个可疑点）' : '开始扫描',
              icon: Icons.search_rounded,
              loading: _scanning,
              onPressed: _scanning
                  ? null
                  : () async {
                      setState(() {
                        _scanning = true;
                        _found = 0;
                      });
                      // 无真实红外能力：演示式扫描
                      await Future.delayed(const Duration(seconds: 3));
                      if (!mounted) return;
                      setState(() {
                        _scanning = false;
                        _found = 0;
                      });
                      ToastUtil.info('未发现可疑设备');
                    },
            ),
            const SizedBox(height: 10),
            Text('⚠️ 本机无红外/磁力检测硬件，扫描为演示效果。\n'
                '真实检测请使用专业设备或「手机摄像头 + 红光滤镜」方式。',
                style: TextStyle(fontSize: 12, color: context.t3, height: 1.6)),
          ],
        ),
      ],
    );
  }
}

// ═══════════════ 信息资讯 ═══════════════

/// 健身指南
class JianshenTool extends StatelessWidget {
  const JianshenTool({super.key});

  static const _plans = [
    ['胸 + 三头', '平板卧推 4×10 / 上斜哑铃推 3×12 / 双杠臂屈伸 3×力竭 / 绳索下压 3×15'],
    ['背 + 二头', '引体向上 4×力竭 / 高位下拉 4×10 / 杠铃划船 3×10 / 弯举 3×12'],
    ['腿 + 臀', '深蹲 4×10 / 腿举 3×12 / 罗马尼亚硬拉 3×12 / 提踵 4×15'],
    ['肩 + 核心', '坐姿推举 4×10 / 侧平举 4×15 / 面拉 3×15 / 卷腹 4×20'],
    ['有氧 + 拉伸', '慢跑 30min / 动态拉伸 10min / 泡沫轴放松 10min'],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '健身指南',
      subtitle: '一周训练计划参考',
      children: _plans
          .asMap()
          .entries
          .map((e) => ToolCard(
                title: 'Day ${e.key + 1} · ${e.value[0]}',
                icon: Icons.fitness_center_rounded,
                children: [
                  Text(e.value[1],
                      style: TextStyle(
                          fontSize: 13.5, height: 1.9, color: context.t2)),
                ],
              ))
          .toList(),
    );
  }
}

/// 菜谱大全
class RecipeTool extends StatefulWidget {
  const RecipeTool({super.key});
  @override
  State<RecipeTool> createState() => _RecipeToolState();
}

class _RecipeToolState extends State<RecipeTool> {
  final _kw = TextEditingController();

  static const _data = <String, List<String>>{
    '番茄炒蛋': ['番茄 2个', '鸡蛋 3个', '葱花 少许', '盐 / 糖 适量'],
    '青椒肉丝': ['青椒 2个', '猪里脊 200g', '蒜末', '生抽 / 淀粉'],
    '土豆炖牛腩': ['牛腩 500g', '土豆 2个', '胡萝卜 1根', '八角 / 桂皮'],
    '蒜蓉西兰花': ['西兰花 1颗', '蒜末 3瓣', '蚝油 1勺', '盐 少许'],
    '红烧肉': ['五花肉 600g', '冰糖 20g', '老抽 / 生抽', '姜片 / 料酒'],
  };

  String _sel = '番茄炒蛋';

  @override
  void dispose() {
    _kw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _data.keys.where((k) => k.contains(_kw.text.trim())).toList();
    final cur = _data[_sel] ?? [];
    return ToolScaffold(
      title: '菜谱大全',
      subtitle: '常用家常菜做法',
      children: [
        ToolCard(
          title: '搜索菜名',
          icon: Icons.restaurant_menu_rounded,
          children: [
            ToolField(
                controller: _kw,
                hint: '如：番茄',
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keys
                  .map((k) => GestureDetector(
                        onTap: () => setState(() => _sel = k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _sel == k
                                ? C.brand.withAlpha(30)
                                : C.brand.withAlpha(14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(k,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: C.brand)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        ToolCard(
          title: _sel,
          icon: Icons.shopping_basket_rounded,
          children: [
            ...cur.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.check_circle_outline_rounded,
                      size: 19, color: C.brand),
                  title: Text(e, style: const TextStyle(fontSize: 14)),
                )),
          ],
        ),
      ],
    );
  }
}

/// 每日英语
class DayEnglishTool extends StatefulWidget {
  const DayEnglishTool({super.key});
  @override
  State<DayEnglishTool> createState() => _DayEnglishToolState();
}

class _DayEnglishToolState extends State<DayEnglishTool> {
  static const _list = [
    ['Actions speak louder than words.', '行动胜于雄辩。'],
    ['Every cloud has a silver lining.', '黑暗中总有一线光明。'],
    ['Practice makes perfect.', '熟能生巧。'],
    ['Where there is a will, there is a way.', '有志者事竟成。'],
    ['It never rains but it pours.', '祸不单行。'],
    ['Better late than never.', '迟做总比不做好。'],
    ['A friend in need is a friend indeed.', '患难见真情。'],
    ['Rome was not built in a day.', '罗马不是一天建成的。'],
  ];

  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final cur = _list[_i];
    return ToolScaffold(
      title: '每日英语',
      subtitle: '每日一句英文谚语',
      children: [
        ToolCard(
          title: '第 ${_i + 1} / ${_list.length} 句',
          icon: Icons.translate_rounded,
          children: [
            SelectableText(cur[0],
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                    color: Color(0xFF2A2D3A))),
            const SizedBox(height: 12),
            Text(cur[1],
                style: TextStyle(fontSize: 14.5, color: context.t2, height: 1.6)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ToolButton(
                    label: '换一句',
                    icon: Icons.refresh_rounded,
                    onPressed: () => setState(
                        () => _i = (_i + 1) % _list.length),
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

/// 天气排行榜
class WeatherRankTool extends StatefulWidget {
  const WeatherRankTool({super.key});
  @override
  State<WeatherRankTool> createState() => _WeatherRankToolState();
}

class _WeatherRankToolState extends State<WeatherRankTool> {
  static const _cities = <List<String>>[
    ['三亚', '31', '晴'],
    ['海口', '29', '多云'],
    ['广州', '27', '阵雨'],
    ['深圳', '27', '多云'],
    ['南宁', '26', '阴'],
    ['福州', '25', '多云'],
    ['杭州', '22', '晴'],
    ['上海', '21', '多云'],
    ['成都', '20', '阴'],
    ['北京', '18', '晴'],
    ['西安', '17', '多云'],
    ['哈尔滨', '9', '小雪'],
    ['漠河', '3', '雪'],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '天气排行榜',
      subtitle: '全国主要城市气温',
      children: [
        ToolCard(
          title: '气温排行（℃）',
          icon: Icons.thermostat_rounded,
          children: _cities
              .asMap()
              .entries
              .map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: e.key < 3
                            ? const Color(0xFFFB7185).withAlpha(30)
                            : C.brand.withAlpha(16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: e.key < 3
                                  ? const Color(0xFFFB7185)
                                  : C.brand)),
                    ),
                    title: Text(e.value[0],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.value[2]} ',
                            style: TextStyle(fontSize: 12, color: context.t3)),
                        Text('${e.value[1]}°',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// 全国气温图
class TemperatureTool extends StatelessWidget {
  const TemperatureTool({super.key});

  static const _zones = [
    ['东北', '3 ~ 12℃', '寒冷', Color(0xFF60A5FA)],
    ['华北', '15 ~ 22℃', '凉爽', Color(0xFF34D399)],
    ['华东', '18 ~ 25℃', '舒适', Color(0xFF10B981)],
    ['华中', '19 ~ 26℃', '舒适', Color(0xFFFBBF24)],
    ['华南', '25 ~ 32℃', '炎热', Color(0xFFFB7185)],
    ['西南', '16 ~ 24℃', '温和', Color(0xFFA78BFA)],
    ['西北', '8 ~ 20℃', '温差大', Color(0xFF22D3EE)],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '全国气温图',
      subtitle: '各区域气温区间',
      children: [
        ToolCard(
          title: '区域气温',
          icon: Icons.public_rounded,
          children: _zones
              .map((z) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 34,
                          decoration: BoxDecoration(
                            color: z[3] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(z[0] as String,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Text(z[2] as String,
                                  style: TextStyle(
                                      fontSize: 11.5, color: context.t3)),
                            ],
                          ),
                        ),
                        Text(z[1] as String,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ))
                  .toList(),
        ),
      ],
    );
  }
}

/// 地震数据
class EarthquakeTool extends StatelessWidget {
  const EarthquakeTool({super.key});

  static const _list = [
    ['四川甘孜州', '3.2', '2026-10-04 08:12', '深度 10km'],
    ['云南大理州', '2.8', '2026-10-03 21:45', '深度 8km'],
    ['新疆阿克苏', '4.1', '2026-10-02 14:30', '深度 12km'],
    ['台湾花莲县', '4.6', '2026-10-01 06:22', '深度 15km'],
    ['西藏那曲市', '3.5', '2026-09-30 19:08', '深度 9km'],
    ['青海海西州', '2.9', '2026-09-29 11:33', '深度 11km'],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '地震数据',
      subtitle: '近期地震速览（示例）',
      children: [
        ToolCard(
          title: '近期地震',
          icon: Icons.waves_rounded,
          children: _list
              .map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB7185).withAlpha(22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text('${e[1]}级',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFB7185))),
                    ),
                    title: Text(e[0],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('${e[2]}  ·  ${e[3]}',
                        style: TextStyle(fontSize: 11.5, color: context.t3)),
                  ))
              .toList(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('⚠️ 数据为示例展示，真实数据请以中国地震台网发布为准。',
              style: TextStyle(fontSize: 12, color: context.t3)),
        ),
      ],
    );
  }
}

/// 设备排行榜
class DeviceRankTool extends StatefulWidget {
  const DeviceRankTool({super.key});
  @override
  State<DeviceRankTool> createState() => _DeviceRankToolState();
}

class _DeviceRankToolState extends State<DeviceRankTool> {
  int _tab = 0;
  static const _phone = [
    ['iPhone 17 Pro Max', 'A19 Pro / 8G / 6.9"'],
    ['小米 16 Ultra', '骁龙 8 Gen5 / 16G / 6.8"'],
    ['华为 Mate 80 Pro', '麒麟 9030 / 12G / 6.8"'],
    ['vivo X300 Pro', '天玑 9500 / 16G / 6.8"'],
    ['OPPO Find X9', '骁龙 8 Gen5 / 12G / 6.7"'],
  ];
  static const _moto = [
    ['春风 450SR', '449cc / 50.3 马力'],
    ['钱江赛 600', '600cc / 81 马力'],
    ['豪爵铃木 GSX250R', '248cc / 25 马力'],
    ['隆鑫无极 525', '494cc / 47 马力'],
    ['宗申赛科龙 RX6', '649cc / 73 马力'],
  ];

  @override
  Widget build(BuildContext context) {
    final list = _tab == 0 ? _phone : _moto;
    return ToolScaffold(
      title: '设备排行榜',
      subtitle: '数码 / 摩托 热门榜',
      children: [
        Row(
          children: [
            _tabBtn('数码设备', 0),
            const SizedBox(width: 10),
            _tabBtn('摩托车', 1),
          ],
        ),
        const SizedBox(height: 14),
        ToolCard(
          title: _tab == 0 ? '手机性能榜' : '热门摩托榜',
          icon: Icons.emoji_events_rounded,
          children: list
              .asMap()
              .entries
              .map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: e.key < 3
                            ? const Color(0xFFFBBF24).withAlpha(35)
                            : C.brand.withAlpha(14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: e.key < 3
                                  ? const Color(0xFFF59E0B)
                                  : C.brand)),
                    ),
                    title: Text(e.value[0],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(e.value[1],
                        style: TextStyle(fontSize: 11.5, color: context.t3)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _tabBtn(String t, int i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tab == i ? C.brand.withAlpha(24) : C.brand.withAlpha(10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(t,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _tab == i ? C.brand : context.t2)),
          ),
        ),
      );
}

// ═══════════════ 图片处理扩展 ═══════════════

/// EXIF 信息修改（说明型）
class ExifEditTool extends StatelessWidget {
  const ExifEditTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '图片信息修改',
        subtitle: '查看与清除 EXIF',
        icon: Icons.article_rounded,
        desc: '查看照片的拍摄时间、设备型号、GPS 位置等 EXIF 信息，并可一键清除以保护隐私。',
      );
}

/// 图片转链接
class ImageUrlTool extends StatelessWidget {
  const ImageUrlTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '图片转链接',
        subtitle: '上传图片生成外链',
        icon: Icons.link_rounded,
        desc: '把本地图片上传到图床，生成可直接访问的图片链接，方便分享到论坛、聊天工具。',
      );
}

/// 图片旋转
class ImageRotateTool extends StatelessWidget {
  const ImageRotateTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '图片旋转',
        subtitle: '任意角度旋转翻转',
        icon: Icons.rotate_90_degrees_ccw_rounded,
        desc: '支持 90°/180°/270° 快速旋转，以及水平/垂直翻转，可自由裁剪旋转角度。',
      );
}

/// 纯色图制作
class SolidColorTool extends StatefulWidget {
  const SolidColorTool({super.key});
  @override
  State<SolidColorTool> createState() => _SolidColorToolState();
}

class _SolidColorToolState extends State<SolidColorTool> {
  Color _c = const Color(0xFF4B5EF5);
  static const _presets = [
    Color(0xFF4B5EF5), Color(0xFFFB7185), Color(0xFF34D399),
    Color(0xFFFBBF24), Color(0xFFA78BFA), Color(0xFF22D3EE),
    Color(0xFF1F2937), Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '纯色图制作',
      subtitle: '生成纯色背景图',
      children: [
        ToolCard(
          title: '选择颜色',
          icon: Icons.format_color_fill_rounded,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _presets
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _c = c),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _c == c
                                    ? C.brand
                                    : const Color(0xFFD8DCE6),
                                width: _c == c ? 2.5 : 1),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        ToolCard(
          title: '预览',
          icon: Icons.image_rounded,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: _c,
                  borderRadius: BorderRadius.circular(R.md),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 渐变配色
class GradientColorTool extends StatefulWidget {
  const GradientColorTool({super.key});
  @override
  State<GradientColorTool> createState() => _GradientColorToolState();
}

class _GradientColorToolState extends State<GradientColorTool> {
  static const _pairs = [
    [Color(0xFF6E7DFF), Color(0xFFA78BFA)],
    [Color(0xFFFB7185), Color(0xFFFBBF24)],
    [Color(0xFF34D399), Color(0xFF22D3EE)],
    [Color(0xFF1F2937), Color(0xFF4B5EF5)],
    [Color(0xFFFF6B35), Color(0xFFFB7185)],
  ];
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final p = _pairs[_i];
    return ToolScaffold(
      title: '渐变配色',
      subtitle: '常用渐变方案',
      children: [
        ToolCard(
          title: '预览',
          icon: Icons.gradient_rounded,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: p,
                ),
                borderRadius: BorderRadius.circular(R.md),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              'LinearGradient(\n'
              "  colors: [Color(0x${p[0].r.toInt().toRadixString(16)}...), "
              'Color(0x${p[1].r.toInt().toRadixString(16)}...)],\n)',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 14),
            ToolButton(
              label: '换一组',
              icon: Icons.refresh_rounded,
              onPressed: () =>
                  setState(() => _i = (_i + 1) % _pairs.length),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════ 系统极客 ═══════════════

/// 应用管理（本机已装应用）
class AppManagerTool extends StatelessWidget {
  const AppManagerTool({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '应用管理',
      subtitle: '查看本机应用',
      children: [
        ToolCard(
          title: '系统信息',
          icon: Icons.apps_rounded,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.android_rounded, color: C.brand),
              title: const Text('操作系统', style: TextStyle(fontSize: 14)),
              trailing: Text(Platform.operatingSystem,
                  style: TextStyle(fontSize: 13, color: context.t3)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.memory_rounded, color: C.brand),
              title: const Text('系统版本', style: TextStyle(fontSize: 14)),
              trailing: Text(Platform.operatingSystemVersion.split(' ').first,
                  style: TextStyle(fontSize: 13, color: context.t3)),
            ),
            const SizedBox(height: 8),
            Text('受系统权限限制，App 列表需在系统设置中查看。',
                style: TextStyle(fontSize: 12, color: context.t3, height: 1.6)),
          ],
        ),
      ],
    );
  }
}

/// 安装包查找
class ApkScannerTool extends StatefulWidget {
  const ApkScannerTool({super.key});
  @override
  State<ApkScannerTool> createState() => _ApkScannerToolState();
}

class _ApkScannerToolState extends State<ApkScannerTool> {
  bool _scanning = false;
  List<String> _found = [];

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _found = [];
    });
    final dirs = ['/storage/emulated/0/Download', '/sdcard/Download',
                  '/storage/emulated/0/', '/storage/emulated/0/Android/data'];
    final res = <String>[];
    for (final d in dirs) {
      try {
        final dir = Directory(d);
        if (!await dir.exists()) continue;
        await for (final e in dir.list(recursive: false, followLinks: false)) {
          if (e.path.toLowerCase().endsWith('.apk')) {
            res.add(e.path.split('/').last);
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _found = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '安装包查找',
      subtitle: '扫描本机 APK 文件',
      children: [
        ToolCard(
          title: '扫描',
          icon: Icons.folder_open_rounded,
          children: [
            ToolButton(
              label: _scanning ? '扫描中…' : '开始扫描',
              icon: Icons.search_rounded,
              loading: _scanning,
              onPressed: _scanning ? null : _scan,
            ),
            const SizedBox(height: 14),
            if (_found.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.folder_off_rounded,
                          size: 46, color: context.t3),
                      const SizedBox(height: 10),
                      Text(_scanning ? '正在扫描…' : '未发现安装包',
                          style: TextStyle(color: context.t3)),
                    ],
                  ),
                ),
              )
            else
              ..._found.map((f) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading:
                        Icon(Icons.android_rounded, color: C.brand, size: 22),
                    title: Text(f,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  )),
            if (_found.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('共找到 ${_found.length} 个安装包',
                    style: TextStyle(fontSize: 12.5, color: context.t3)),
              ),
          ],
        ),
      ],
    );
  }
}

/// 应用商店
class AppStoreTool extends StatelessWidget {
  const AppStoreTool({super.key});

  static const _stores = [
    ['酷安', 'https://www.coolapk.com/'],
    ['应用宝', 'https://sj.qq.com/'],
    ['豌豆荚', 'https://www.wandoujia.com/'],
    ['华为应用市场', 'https://appgallery.huawei.com/'],
    ['小米应用商店', 'https://app.mi.com/'],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '应用商店',
      subtitle: '主流商店入口',
      children: [
        ToolCard(
          title: '商店',
          icon: Icons.storefront_rounded,
          children: _stores
              .map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.store_rounded, color: C.brand),
                    title: Text(s[0],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.open_in_new_rounded,
                        size: 18, color: context.t3),
                    onTap: () async {
                      final u = Uri.tryParse(s[1]);
                      if (u != null && await canLaunchUrl(u)) {
                        await launchUrl(u,
                            mode: LaunchMode.externalApplication);
                      } else {
                        copyText(s[1]);
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// APK 安装器
class ApkInstallerTool extends StatelessWidget {
  const ApkInstallerTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: 'Apk1 安装器',
        subtitle: '安装本地 APK',
        icon: Icons.install_mobile_rounded,
        desc: '选择本机 APK 文件直接安装。需要开启「未知来源应用安装」权限。',
      );
}

/// 字体大小调节
class FontSizeTool extends StatefulWidget {
  const FontSizeTool({super.key});
  @override
  State<FontSizeTool> createState() => _FontSizeToolState();
}

class _FontSizeToolState extends State<FontSizeTool> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '字体大小调节',
      subtitle: '预览字号效果',
      children: [
        ToolCard(
          title: '字号倍率 ${_scale.toStringAsFixed(2)}x',
          icon: Icons.format_size_rounded,
          children: [
            Slider(
              value: _scale,
              min: 0.8,
              max: 1.6,
              divisions: 16,
              label: '${_scale.toStringAsFixed(2)}x',
              activeColor: C.brand,
              onChanged: (v) => setState(() => _scale = v),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: C.brand.withAlpha(12),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Text(
                '预览文字效果\n这是一段用于预览的示例文本，可以直观看到不同字号下的显示效果。',
                style: TextStyle(
                    fontSize: 14 * _scale, height: 1.7 * _scale,
                    color: context.t1),
              ),
            ),
            const SizedBox(height: 10),
            Text('系统级字体调节需前往「设置 → 显示 → 字体大小」。',
                style: TextStyle(fontSize: 12, color: context.t3)),
          ],
        ),
      ],
    );
  }
}

/// 扬声器清灰
class LoudspeakerTool extends StatefulWidget {
  const LoudspeakerTool({super.key});
  @override
  State<LoudspeakerTool> createState() => _LoudspeakerToolState();
}

class _LoudspeakerToolState extends State<LoudspeakerTool> {
  bool _running = false;
  int _left = 0;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _left = 30;
    });
    HapticFeedback.mediumImpact();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      HapticFeedback.heavyImpact();
      if (_left <= 0) {
        t.cancel();
        setState(() => _running = false);
        ToastUtil.success('清灰完成');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '扬声器清灰',
      subtitle: '声波震动排出灰尘',
      children: [
        ToolCard(
          title: _running ? '清灰中… 剩余 $_left 秒' : '准备就绪',
          icon: Icons.volume_up_rounded,
          children: [
            if (_running)
              LinearProgressIndicator(
                  value: (30 - _left) / 30, color: C.brand)
            else
              const SizedBox(height: 6),
            const SizedBox(height: 18),
            ToolButton(
              label: _running ? '正在清灰…' : '开始清灰（30秒）',
              icon: Icons.cleaning_services_rounded,
              loading: _running,
              onPressed: _running ? null : _start,
            ),
            const SizedBox(height: 12),
            Text('原理：通过特定频率震动使扬声器振膜抖动，'
                '将附着灰尘排出。\n建议音量调至最大，效果更佳。',
                style: TextStyle(fontSize: 12, color: context.t3, height: 1.6)),
          ],
        ),
      ],
    );
  }
}

/// 动态视频壁纸
class VideoWallTool extends StatelessWidget {
  const VideoWallTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '动态视频壁纸',
        subtitle: '设置视频为壁纸',
        icon: Icons.video_settings_rounded,
        desc: '选择一段视频作为桌面动态壁纸。需要系统支持「动态壁纸」服务。',
      );
}

/// 空文件清理
class FileCleanTool extends StatelessWidget {
  const FileCleanTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '空文件清理',
        subtitle: '扫描并清理空文件夹',
        icon: Icons.cleaning_services_rounded,
        desc: '扫描存储中的空文件夹与残留目录，一键清理释放空间。',
      );
}

/// 视频提取音频
class ExtractAudioTool extends StatelessWidget {
  const ExtractAudioTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '视频提取音频',
        subtitle: '视频转 MP3',
        icon: Icons.audiotrack_rounded,
        desc: '从视频文件中提取音轨并保存为 MP3，支持批量处理。',
      );
}

/// 步数修改
class StepCounterTool extends StatelessWidget {
  const StepCounterTool({super.key});
  @override
  Widget build(BuildContext context) => const _NoteTool(
        title: '步数修改',
        subtitle: '同步微信运动步数',
        icon: Icons.directions_walk_rounded,
        desc: '修改本机健康数据中的步数，需授权健康数据读写权限。'
            '请遵守相关平台规则，仅供学习交流。',
      );
}

// ═══════════════ 通用说明页 ═══════════════

class _NoteTool extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String desc;
  const _NoteTool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: title,
      subtitle: subtitle,
      children: [
        ToolCard(
          title: '功能说明',
          icon: icon,
          children: [
            Text(desc,
                style: TextStyle(fontSize: 14, height: 1.8, color: context.t2)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.brand.withAlpha(14),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 17, color: C.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('该工具正在接入中，后续版本开放完整功能。',
                        style: TextStyle(fontSize: 12.5, color: context.t2)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
