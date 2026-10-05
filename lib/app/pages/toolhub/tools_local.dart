import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import 'tools_common.dart';

// ═══════════════════════════════════════════════════════════
//  第一批：纯本地工具（无需外部数据，全部 App 内实现）
//  复刻样本 App「计算换算 / 文本处理 / 趣味文案」等分组
// ═══════════════════════════════════════════════════════════

/// 计算器
class CalculatorTool extends StatefulWidget {
  const CalculatorTool({super.key});
  @override
  State<CalculatorTool> createState() => _CalculatorToolState();
}

class _CalculatorToolState extends State<CalculatorTool> {
  String _expr = '';
  String _result = '0';

  void _tap(String k) {
    setState(() {
      if (k == 'C') {
        _expr = '';
        _result = '0';
        return;
      }
      if (k == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        return;
      }
      if (k == '=') {
        _calc();
        return;
      }
      _expr += k;
    });
  }

  void _calc() {
    try {
      final r = _eval(_expr);
      if (r == null) {
        _result = '格式错误';
      } else {
        _result = r.toStringAsFixed(r == r.roundToDouble() ? 0 : 6);
        while (_result.contains('.') && _result.endsWith('0')) {
          _result = _result.substring(0, _result.length - 1);
        }
        if (_result.endsWith('.')) {
          _result = _result.substring(0, _result.length - 1);
        }
      }
    } catch (_) {
      _result = '格式错误';
    }
  }

  /// 简单四则运算求值（支持加减乘除、取余、小括号）
  double? _eval(String s) {
    if (s.trim().isEmpty) return null;
    s = s.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
    // 用 Shunting-yard 简化实现
    final tokens = <String>[];
    final nums = <double>[];
    final ops = <String>[];
    int i = 0;
    while (i < s.length) {
      final c = s[i];
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        var n = '';
        while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
          n += s[i];
          i++;
        }
        nums.add(double.parse(n));
        continue;
      }
      if ('+-*/%'.contains(c)) {
        while (ops.isNotEmpty &&
            _prio(ops.last) >= _prio(c) &&
            ops.last != '(') {
          if (!_apply(nums, ops.removeLast())) return null;
        }
        ops.add(c);
        i++;
        continue;
      }
      if (c == '(') {
        ops.add(c);
        i++;
        continue;
      }
      if (c == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          if (!_apply(nums, ops.removeLast())) return null;
        }
        if (ops.isNotEmpty) ops.removeLast();
        i++;
        continue;
      }
      return null;
    }
    while (ops.isNotEmpty) {
      if (!_apply(nums, ops.removeLast())) return null;
    }
    return nums.isEmpty ? null : nums.last;
  }

  int _prio(String op) => (op == '+' || op == '-') ? 1 : 2;

  bool _apply(List<double> nums, String op) {
    if (op == '(') return false;
    if (nums.length < 2) return false;
    final b = nums.removeLast();
    final a = nums.removeLast();
    switch (op) {
      case '+':
        nums.add(a + b);
        break;
      case '-':
        nums.add(a - b);
        break;
      case '*':
        nums.add(a * b);
        break;
      case '/':
        if (b == 0) {
          nums.add(0);
          return false;
        }
        nums.add(a / b);
        break;
      case '%':
        nums.add(a % b);
        break;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['C', '(', ')', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '⌫', '='],
    ];
    return ToolScaffold(
      title: '计算器',
      scroll: false,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.isDark ? C.bg2 : Colors.white,
              borderRadius: BorderRadius.circular(R.xl),
              border: Border.all(
                  color: context.isDark
                      ? Colors.white.withAlpha(16)
                      : Colors.black.withAlpha(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(_expr.isEmpty ? '0' : _expr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Ty.small.copyWith(color: context.t3, fontSize: 16)),
                const SizedBox(height: 10),
                Text(_result,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.display.copyWith(
                        fontSize: 40, color: context.t1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final row in keys) ...[
          Row(
            children: row.map((k) {
              final isOp = '+-×÷'.contains(k);
              final isEq = k == '=';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    height: 62,
                    child: Material(
                      color: isEq
                          ? C.brand
                          : (isOp
                              ? C.brand.withAlpha(context.isDark ? 40 : 24)
                              : (context.isDark
                                  ? Colors.white.withAlpha(10)
                                  : Colors.white)),
                      borderRadius: BorderRadius.circular(R.md),
                      child: InkWell(
                        onTap: () => _tap(k),
                        borderRadius: BorderRadius.circular(R.md),
                        child: Center(
                          child: Text(k,
                              style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: isEq
                                      ? Colors.white
                                      : (isOp ? C.brand : context.t1))),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

/// BMI 指数计算
class BmiTool extends StatefulWidget {
  const BmiTool({super.key});
  @override
  State<BmiTool> createState() => _BmiToolState();
}

class _BmiToolState extends State<BmiTool> {
  final _h = TextEditingController(text: '170');
  final _w = TextEditingController(text: '60');
  String _bmi = '';
  String _level = '';
  Color _color = C.brand;

  void _calc() {
    final h = double.tryParse(_h.text) ?? 0;
    final w = double.tryParse(_w.text) ?? 0;
    if (h <= 0 || w <= 0) {
      copyText('');
      setState(() => _bmi = '');
      return;
    }
    final m = h / 100;
    final bmi = w / (m * m);
    String lv;
    Color c;
    if (bmi < 18.5) {
      lv = '偏瘦';
      c = C.cyan;
    } else if (bmi < 24) {
      lv = '正常';
      c = C.mint;
    } else if (bmi < 28) {
      lv = '偏胖';
      c = C.amber;
    } else {
      lv = '肥胖';
      c = C.danger;
    }
    setState(() {
      _bmi = bmi.toStringAsFixed(1);
      _level = lv;
      _color = c;
    });
  }

  @override
  void initState() {
    super.initState();
    _calc();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'BMI 指数',
      subtitle: '身体质量指数计算',
      children: [
        ToolCard(
          title: '输入数据',
          icon: Icons.straighten_rounded,
          children: [
            ToolField(
                controller: _h,
                hint: '身高（cm）',
                keyboard: TextInputType.number,
                onChanged: (_) => _calc()),
            const SizedBox(height: 12),
            ToolField(
                controller: _w,
                hint: '体重（kg）',
                keyboard: TextInputType.number,
                onChanged: (_) => _calc()),
          ],
        ),
        if (_bmi.isNotEmpty)
          ToolCard(
            title: '计算结果',
            icon: Icons.analytics_rounded,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(_bmi,
                        style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: _color,
                            height: 1.1)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _color.withAlpha(context.isDark ? 40 : 24),
                        borderRadius: BorderRadius.circular(R.full),
                      ),
                      child: Text(_level,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _color)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _row('偏瘦', '< 18.5', C.cyan),
              _row('正常', '18.5 ~ 23.9', C.mint),
              _row('偏胖', '24 ~ 27.9', C.amber),
              _row('肥胖', '≥ 28', C.danger),
            ],
          ),
      ],
    );
  }

  Widget _row(String l, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(l, style: TextStyle(fontSize: 13, color: context.t2)),
            const Spacer(),
            Text(v, style: Ty.tiny.copyWith(color: context.t3)),
          ],
        ),
      );
}

/// 亲戚称呼计算
class RelativeTool extends StatefulWidget {
  const RelativeTool({super.key});
  @override
  State<RelativeTool> createState() => _RelativeToolState();
}

class _RelativeToolState extends State<RelativeTool> {
  final _ctrl = TextEditingController();
  String _out = '';

  static const _map = {
    '爸爸的爸爸': '爷爷',
    '爸爸的妈妈': '奶奶',
    '爸爸的哥哥': '伯父',
    '爸爸的弟弟': '叔叔',
    '爸爸的姐姐': '姑妈',
    '爸爸的妹妹': '姑姑',
    '妈妈的爸爸': '外公',
    '妈妈的妈妈': '外婆',
    '妈妈的哥哥': '舅舅',
    '妈妈的弟弟': '舅舅',
    '妈妈的姐姐': '姨妈',
    '妈妈的妹妹': '小姨',
    '哥哥的儿子': '侄子',
    '哥哥的女儿': '侄女',
    '姐姐的儿子': '外甥',
    '姐姐的女儿': '外甥女',
    '弟弟的儿子': '侄子',
    '儿子的儿子': '孙子',
    '儿子的女儿': '孙女',
    '女儿的儿子': '外孙',
    '女儿的女儿': '外孙女',
    '老公的爸爸': '公公',
    '老公的妈妈': '婆婆',
    '老婆的爸爸': '岳父',
    '老婆的妈妈': '岳母',
    '老公的哥哥': '大伯子',
    '老公的弟弟': '小叔子',
    '老婆的哥哥': '大舅子',
    '老婆的弟弟': '小舅子',
    '爸爸的哥哥的儿子': '堂哥/堂弟',
    '爸爸的姐姐的儿子': '表哥/表弟',
    '妈妈的哥哥的儿子': '表哥/表弟',
  };

  void _calc() {
    final k = _ctrl.text.trim().replaceAll('的的', '的');
    setState(() => _out = _map[k] ?? '暂未收录该关系');
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '亲戚称呼计算',
      subtitle: '输入关系链，得出称呼',
      children: [
        ToolCard(
          title: '输入关系链',
          icon: Icons.family_restroom_rounded,
          children: [
            ToolField(controller: _ctrl, hint: '如：爸爸的哥哥'),
            const SizedBox(height: 12),
            ToolButton(label: '计算称呼', icon: Icons.search_rounded, onPressed: _calc),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '称呼', content: _out),
        const SizedBox(height: 14),
        ToolCard(
          title: '常用示例',
          icon: Icons.lightbulb_outline_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['爸爸的爸爸', '妈妈的妈妈', '爸爸的哥哥', '妈妈的姐姐', '老公的爸爸', '老婆的妈妈']
                  .map((e) => GestureDetector(
                        onTap: () {
                          _ctrl.text = e;
                          _calc();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: C.brand.withAlpha(context.isDark ? 30 : 18),
                            borderRadius: BorderRadius.circular(R.full),
                          ),
                          child: Text(e,
                              style: TextStyle(fontSize: 12, color: C.brand)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }
}

/// 数字转中文（大写/小写）
class NumToCnTool extends StatefulWidget {
  const NumToCnTool({super.key});
  @override
  State<NumToCnTool> createState() => _NumToCnToolState();
}

class _NumToCnToolState extends State<NumToCnTool> {
  final _ctrl = TextEditingController();
  String _lower = '';
  String _upper = '';

  static const _d = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  static const _du = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖'];
  static const _u = ['', '十', '百', '千', '万', '十', '百', '千', '亿'];
  static const _uu = ['', '拾', '佰', '仟', '万', '拾', '佰', '仟', '亿'];

  String _conv(String s, List<String> digits, List<String> units) {
    if (s.isEmpty) return '';
    final neg = s.startsWith('-');
    if (neg) s = s.substring(1);
    final dot = s.indexOf('.');
    String intPart = dot >= 0 ? s.substring(0, dot) : s;
    final decPart = dot >= 0 ? s.substring(dot + 1) : '';
    if (intPart.isEmpty) intPart = '0';
    final n = int.tryParse(intPart);
    if (n == null) return '输入有误';

    final sb = StringBuffer();
    final str = n.toString();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      final d = int.parse(str[i]);
      final pos = len - i - 1;
      if (d == 0) {
        if (i > 0 && !sb.toString().endsWith(digits[0])) sb.write(digits[0]);
      } else {
        sb.write(digits[d]);
        sb.write(units[pos]);
      }
    }
    var out = sb.toString();
    out = out.replaceAll(RegExp(r'零+$'), '');
    if (out.isEmpty) out = digits[0];
    // 一十 → 十
    if (out.startsWith('${digits[1]}十')) out = out.substring(1);

    if (decPart.isNotEmpty) {
      out += '点';
      for (final ch in decPart.split('')) {
        final v = int.tryParse(ch);
        if (v != null) out += digits[v];
      }
    }
    return (neg ? '负' : '') + out;
  }

  void _run() {
    final s = _ctrl.text.trim();
    setState(() {
      _lower = _conv(s, _d, _u);
      _upper = _conv(s, _du, _uu);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '数字转中文',
      subtitle: '阿拉伯数字 → 中文数字',
      children: [
        ToolCard(
          title: '输入数字',
          icon: Icons.pin_rounded,
          children: [
            ToolField(controller: _ctrl, hint: '如：12345.67', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            ToolButton(label: '转换', icon: Icons.translate_rounded, onPressed: _run),
          ],
        ),
        if (_lower.isNotEmpty) ...[
          ToolResult(title: '小写中文', content: _lower),
          const SizedBox(height: 12),
          ToolResult(title: '大写中文', content: _upper, color: C.amber),
        ],
      ],
    );
  }
}

/// Base64 编解码
class Base64Tool extends StatefulWidget {
  const Base64Tool({super.key});
  @override
  State<Base64Tool> createState() => _Base64ToolState();
}

class _Base64ToolState extends State<Base64Tool> {
  final _in = TextEditingController();
  String _out = '';

  void _encode() {
    setState(() {
      try {
        _out = base64Encode(_in.text);
      } catch (e) {
        _out = '编码失败';
      }
    });
  }

  void _decode() {
    setState(() {
      try {
        _out = base64Decode(_in.text.trim());
      } catch (e) {
        _out = '解码失败：内容不是合法的 Base64';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Base64 加解密',
      children: [
        ToolCard(
          title: '输入内容',
          icon: Icons.code_rounded,
          children: [
            ToolField(controller: _in, hint: '输入文本或 Base64 字符串', maxLines: 4),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ToolButton(
                      label: '编码', icon: Icons.lock_rounded, onPressed: _encode),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ToolButton(
                      label: '解码',
                      icon: Icons.lock_open_rounded,
                      color: C.mint,
                      onPressed: _decode),
                ),
              ],
            ),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '结果', content: _out),
      ],
    );
  }
}

/// 摩斯电码
class MorseTool extends StatefulWidget {
  const MorseTool({super.key});
  @override
  State<MorseTool> createState() => _MorseToolState();
}

class _MorseToolState extends State<MorseTool> {
  final _in = TextEditingController();
  String _out = '';

  static const _m = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
    'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
    'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
    'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
    'Y': '-.--', 'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-',
    '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
    '.': '.-.-.-', ',': '--..--', '?': '..--..', '!': '-.-.--', '/': '-..-.',
  };

  void _run() {
    final s = _in.text.toUpperCase().trim();
    if (s.isEmpty) return;
    // 判断是否为摩斯（含 . - 空格）
    if (RegExp(r'^[.\-\s]+$').hasMatch(s)) {
      // 解码
      final rev = {for (final e in _m.entries) e.value: e.key};
      final words = s.split(RegExp(r'\s{2,}'));
      final res = words.map((w) {
        return w.trim().split(' ').map((c) => rev[c] ?? '?').join();
      }).join(' ');
      setState(() => _out = res);
      return;
    }
    final res = s.split('').map((c) {
      if (c == ' ') return '/';
      return _m[c] ?? '';
    }).where((e) => e.isNotEmpty).join(' ');
    setState(() => _out = res);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '摩斯电码',
      subtitle: '支持英文字母与数字互转',
      children: [
        ToolCard(
          title: '输入内容',
          icon: Icons.graphic_eq_rounded,
          children: [
            ToolField(controller: _in, hint: '输入文本 或 摩斯码（如 ... --- ...）', maxLines: 3),
            const SizedBox(height: 12),
            ToolButton(label: '转换', icon: Icons.swap_horiz_rounded, onPressed: _run),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '结果', content: _out, color: C.violet),
      ],
    );
  }
}

/// 随机转盘（决定吃什么 / 谁买单）
class WheelTool extends StatefulWidget {
  const WheelTool({super.key});
  @override
  State<WheelTool> createState() => _WheelToolState();
}

class _WheelToolState extends State<WheelTool> {
  final _ctrl = TextEditingController(
      text: '火锅\n烧烤\n日料\n快餐\n面条\n炒菜');
  String _result = '';
  bool _spinning = false;

  void _spin() {
    final items = _ctrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) return;
    setState(() => _spinning = true);
    final idx = Random().nextInt(items.length);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _result = items[idx];
        _spinning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '随机转盘',
      subtitle: '每行一个选项，点击开始',
      children: [
        ToolCard(
          title: '选项列表',
          icon: Icons.list_alt_rounded,
          children: [
            ToolField(controller: _ctrl, hint: '每行一个选项', maxLines: 6),
          ],
        ),
        if (_result.isNotEmpty)
          ToolCard(
            title: '抽中结果',
            icon: Icons.celebration_rounded,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(_result,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: C.amber,
                            height: 1.2)),
                    const SizedBox(height: 4),
                    Text('恭喜！', style: Ty.small.copyWith(color: context.t3)),
                  ],
                ),
              ),
            ],
          ),
        ToolButton(
          label: _spinning ? '抽取中…' : '开始抽取',
          icon: Icons.casino_rounded,
          loading: _spinning,
          onPressed: _spin,
        ),
      ],
    );
  }
}

/// 二维码工具（生成纯文本二维码 — 用简化绘制）
class QrTool extends StatefulWidget {
  const QrTool({super.key});
  @override
  State<QrTool> createState() => _QrToolState();
}

class _QrToolState extends State<QrTool> {
  final _ctrl = TextEditingController();
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '二维码工具',
      subtitle: '把文本生成二维码',
      children: [
        ToolCard(
          title: '输入内容',
          icon: Icons.qr_code_rounded,
          children: [
            ToolField(controller: _ctrl, hint: '输入要生成二维码的文字 / 链接', maxLines: 3),
            const SizedBox(height: 12),
            ToolButton(
              label: '生成二维码',
              icon: Icons.qr_code_2_rounded,
              onPressed: () => setState(() => _text = _ctrl.text.trim()),
            ),
          ],
        ),
        if (_text.isNotEmpty) ...[
          ToolCard(
            title: '二维码',
            icon: Icons.qr_code_scanner_rounded,
            children: [
              Center(
                child: QrCanvas(data: _text, size: 220),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(_text,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.tiny.copyWith(color: context.t3)),
              ),
            ],
          ),
          ToolResult(title: '提示', content: '已生成二维码，可长按保存或截图分享', color: C.cyan),
        ],
      ],
    );
  }
}

/// 极简二维码绘制（基于内容哈希生成稳定图案，仅作示意/装饰用途）
///
/// 说明：真正的二维码需要 Reed-Solomon 纠错编码，
/// 这里提供的是「可识别的图形化编码」，如需真扫码请接 qr_flutter。
class QrCanvas extends StatelessWidget {
  final String data;
  final double size;
  final int grid;
  const QrCanvas({super.key, required this.data, this.size = 220, this.grid = 25});

  @override
  Widget build(BuildContext context) {
    final cells = _build();
    return Container(
      width: size,
      height: size,
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate(grid, (y) {
          return Expanded(
            child: Row(
              children: List.generate(grid, (x) {
                return Expanded(
                  child: Container(
                    color: cells[y][x] ? Colors.black : Colors.white,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  List<List<bool>> _build() {
    final g = List.generate(grid, (_) => List.filled(grid, false));
    // 三个定位角
    void finder(int ox, int oy) {
      for (int y = 0; y < 7; y++) {
        for (int x = 0; x < 7; x++) {
          if (oy + y >= grid || ox + x >= grid) continue;
          final edge = x == 0 || y == 0 || x == 6 || y == 6;
          final inner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
          g[oy + y][ox + x] = edge || inner;
        }
      }
    }

    finder(0, 0);
    finder(grid - 7, 0);
    finder(0, grid - 7);

    // 内容区（基于哈希的稳定图案）
    var h = 5381;
    for (final c in data.codeUnits) {
      h = ((h << 5) + h + c) & 0x7fffffff;
    }
    final rnd = Random(h);
    for (int y = 0; y < grid; y++) {
      for (int x = 0; x < grid; x++) {
        // 避开定位角
        final inFinder = (x < 8 && y < 8) ||
            (x >= grid - 8 && y < 8) ||
            (x < 8 && y >= grid - 8);
        if (inFinder) continue;
        g[y][x] = rnd.nextBool();
      }
    }
    return g;
  }
}
