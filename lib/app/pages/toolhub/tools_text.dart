import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import 'tools_common.dart';

// ═══════════════════════════════════════════════════════════
//  文本处理 / 趣味文案 / 生活小工具（纯本地实现）
// ═══════════════════════════════════════════════════════════

/// 通用「输入 → 输出」文本工具骨架
class _TextToolShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final String hint;
  final String btnLabel;
  final int inputLines;
  final String Function(String input) transform;
  final String resultTitle;

  const _TextToolShell({
    required this.title,
    required this.transform,
    this.subtitle = '',
    this.hint = '',
    this.btnLabel = '转换',
    this.inputLines = 3,
    this.resultTitle = '结果',
  });

  @override
  State<_TextToolShell> createState() => _TextToolShellState();
}

class _TextToolShellState extends State<_TextToolShell> {
  final _in = TextEditingController();
  String _out = '';
  String _err = '';

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _run() {
    final s = _in.text;
    if (s.trim().isEmpty) {
      setState(() {
        _err = '请输入内容';
        _out = '';
      });
      return;
    }
    try {
      setState(() {
        _out = widget.transform(s);
        _err = '';
      });
    } catch (e) {
      setState(() {
        _err = '转换失败：$e';
        _out = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      children: [
        ToolCard(
          title: '输入内容',
          icon: Icons.edit_note_rounded,
          children: [
            ToolField(controller: _in, hint: widget.hint, maxLines: widget.inputLines),
            const SizedBox(height: 12),
            ToolButton(label: widget.btnLabel, icon: Icons.auto_fix_high_rounded, onPressed: _run),
          ],
        ),
        if (_err.isNotEmpty) ToolResult(title: '错误', content: _err, color: C.danger),
        if (_out.isNotEmpty) ToolResult(title: widget.resultTitle, content: _out),
      ],
    );
  }
}

/// 汉字转拼音（常用字表，覆盖常用汉字）
class PinyinTool extends StatelessWidget {
  const PinyinTool({super.key});

  @override
  Widget build(BuildContext context) {
    return _TextToolShell(
      title: '汉字转拼音',
      subtitle: '常用汉字转拼音（无声调）',
      hint: '如：你好世界',
      btnLabel: '转拼音',
      inputLines: 3,
      resultTitle: '拼音',
      transform: (s) => _toPinyin(s),
    );
  }
}

/// 简化拼音转换（覆盖常用字 + 未收录字保留原样）
String _toPinyin(String s) {
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    final code = ch.codeUnitAt(0);
    final p = kPinyinMap[ch];
    if (p != null) {
      sb.write(p);
      sb.write(' ');
    } else if (RegExp(r'[a-zA-Z0-9]').hasMatch(ch)) {
      sb.write(ch);
    } else if (ch == '\n') {
      sb.write('\n');
    } else if (RegExp(r'[\u4e00-\u9fff]').hasMatch(ch)) {
      sb.write('[');
      sb.write(ch);
      sb.write('] ');
    }
    // 标点/空格 保留
    else {
      sb.write(ch);
    }
  }
  return sb.toString().trim();
}

/// 常用汉字 → 拼音（精简版，覆盖高频字）
const Map<String, String> kPinyinMap = {
  '你':'ni','好':'hao','世':'shi','界':'jie','中':'zhong','国':'guo','人':'ren','民':'min',
  '我':'wo','他':'ta','她':'ta','们':'men','是':'shi','的':'de','了':'le','在':'zai',
  '有':'you','和':'he','就':'jiu','不':'bu','一':'yi','二':'er','三':'san','四':'si',
  '五':'wu','六':'liu','七':'qi','八':'ba','九':'jiu','十':'shi','百':'bai','千':'qian',
  '万':'wan','亿':'yi','大':'da','小':'xiao','多':'duo','少':'shao','高':'gao','低':'di',
  '上':'shang','下':'xia','左':'zuo','右':'you','前':'qian','后':'hou','东':'dong','西':'xi',
  '南':'nan','北':'bei','天':'tian','地':'di','日':'ri','月':'yue','年':'nian','时':'shi',
  '分':'fen','秒':'miao','早':'zao','晚':'wan','今':'jin','明':'ming','昨':'zuo','春':'chun',
  '夏':'xia','秋':'qiu','冬':'dong','风':'feng','雨':'yu','雪':'xue','云':'yun','山':'shan',
  '水':'shui','火':'huo','木':'mu','金':'jin','土':'tu','花':'hua','草':'cao','树':'shu',
  '鸟':'niao','鱼':'yu','猫':'mao','狗':'gou','马':'ma','牛':'niu','羊':'yang','猪':'zhu',
  '吃':'chi','喝':'he','睡':'shui','走':'zou','跑':'pao','飞':'fei','看':'kan','听':'ting',
  '说':'shuo','读':'du','写':'xie','习':'xi','工':'gong','作':'zuo','生':'sheng',
  '活':'huo','爱':'ai','恨':'hen','喜':'xi','怒':'nu','哀':'ai','笑':'xiao',
  '哭':'ku','想':'xiang','念':'nian','思':'si','记':'ji','忘':'wang','知':'zhi','道':'dao',
  '能':'neng','会':'hui','可':'ke','以':'yi','要':'yao','需':'xu','得':'de','让':'rang',
  '给':'gei','拿':'na','放':'fang','开':'kai','关':'guan','进':'jin','出':'chu','来':'lai',
  '去':'qu','回':'hui','到':'dao','从':'cong','向':'xiang','把':'ba','被':'bei','比':'bi',
  '很':'hen','太':'tai','最':'zui','更':'geng','还':'hai','也':'ye','都':'dou','只':'zhi',
  '没':'mei','别':'bie','再':'zai','又':'you','已经':'yijing','因':'yin','为':'wei','所':'suo',
  '但':'dan','而':'er','或':'huo','如':'ru','果':'guo','虽':'sui','然':'ran','于':'yu',
  '与':'yu','及':'ji','这':'zhe','那':'na','哪':'na','谁':'shui','什':'shen',
  '么':'me','怎':'zen','样':'yang','何':'he','几':'ji','些':'xie','每':'mei','各':'ge',
  '个':'ge','件':'jian','条':'tiao','张':'zhang','本':'ben','台':'tai','部':'bu','位':'wei',
  '名':'ming','字':'zi','词':'ci','句':'ju','话':'hua','文':'wen','章':'zhang','书':'shu',
  '报':'bao','纸':'zhi','笔':'bi','墨':'mo','画':'hua','歌':'ge','舞':'wu','戏':'xi','视':'shi','剧':'ju','音':'yin','乐':'le','美':'mei','丑':'chou','善':'shan',
  '恶':'e','真':'zhen','假':'jia','对':'dui','错':'cuo','正':'zheng','反':'fan','新':'xin',
  '旧':'jiu','快':'kuai','慢':'man','长':'chang','短':'duan','远':'yuan','近':'jin','重':'zhong',
  '轻':'qing','强':'qiang','弱':'ruo','热':'re','冷':'leng','温':'wen','暖':'nuan','亮':'liang',
  '暗':'an','白':'bai','黑':'hei','红':'hong','黄':'huang','蓝':'lan','绿':'lv','紫':'zi',
  '粉':'fen','灰':'hui','色':'se','光':'guang','影':'ying','声':'sheng','味':'wei','香':'xiang',
  '甜':'tian','苦':'ku','酸':'suan','辣':'la','咸':'xian','淡':'dan','油':'you','盐':'yan',
  '米':'mi','饭':'fan','菜':'cai','肉':'rou','蛋':'dan','奶':'nai','茶':'cha','酒':'jiu',
  '药':'yao','病':'bing','医':'yi','院':'yuan','老':'lao','师':'shi','学':'xue','校':'xiao',
  '同':'tong','友':'you','亲':'qin','情':'qing','事':'shi','物':'wu','品':'pin','钱':'qian',
  '价':'jia','买':'mai','卖':'mai','用':'yong','做':'zuo','成':'cheng','变':'bian','化':'hua',
  '发':'fa','现':'xian','找':'zhao','见':'jian','等':'deng','待':'dai','帮':'bang','助':'zhu',
  '谢':'xie','请':'qing','问':'wen','答':'da','教':'jiao','告':'gao','诉':'su','聊':'liao',
  '谈':'tan','讲':'jiang','提':'ti','议':'yi','决':'jue','定':'ding','选':'xuan','择':'ze',
  '计':'ji','划':'hua','准':'zhun','备':'bei','始':'shi','完':'wan','结':'jie','束':'shu',
};

/// 数字上下标
class SubSupTool extends StatelessWidget {
  const SubSupTool({super.key});

  static const _sup = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹','+':'⁺','-':'⁻','=':'⁼','(':'⁽',')':'⁾','n':'ⁿ'};
  static const _sub = {'0':'₀','1':'₁','2':'₂','3':'₃','4':'₄','5':'₅','6':'₆','7':'₇','8':'₈','9':'₉','+':'₊','-':'₋','=':'₌','(':'₍',')':'₎'};

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '数字上下标',
      subtitle: '把数字转成上标 / 下标字符',
      children: [
        _TwoWay(
          supMap: _sup,
          subMap: _sub,
        ),
      ],
    );
  }
}

class _TwoWay extends StatefulWidget {
  final Map<String, String> supMap;
  final Map<String, String> subMap;
  const _TwoWay({required this.supMap, required this.subMap});
  @override
  State<_TwoWay> createState() => _TwoWayState();
}

class _TwoWayState extends State<_TwoWay> {
  final _in = TextEditingController();
  String _sup = '';
  String _sub = '';

  void _run() {
    final s = _in.text;
    setState(() {
      _sup = s.split('').map((c) => widget.supMap[c] ?? c).join();
      _sub = s.split('').map((c) => widget.subMap[c] ?? c).join();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToolCard(
          title: '输入数字',
          icon: Icons.superscript_rounded,
          children: [
            ToolField(controller: _in, hint: '如：1234567890', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            ToolButton(label: '转换', onPressed: _run),
          ],
        ),
        if (_sup.isNotEmpty) ...[
          ToolResult(title: '上标', content: _sup),
          const SizedBox(height: 12),
          ToolResult(title: '下标', content: _sub, color: C.mint),
        ],
      ],
    );
  }
}

/// 特殊文本生成（花体字 / 装饰）
class FancyTextTool extends StatefulWidget {
  const FancyTextTool({super.key});
  @override
  State<FancyTextTool> createState() => _FancyTextToolState();
}

class _FancyTextToolState extends State<FancyTextTool> {
  final _in = TextEditingController();
  final List<({String name, String text})> _out = [];

  // 花体字映射（Unicode 风格化字母）
  static String _mapBy(String s, int upperBase, int lowerBase) {
    final sb = StringBuffer();
    for (final r in s.runes) {
      if (r >= 65 && r <= 90) {
        sb.writeCharCode(upperBase + (r - 65));
      } else if (r >= 97 && r <= 122) {
        sb.writeCharCode(lowerBase + (r - 97));
      } else if (r >= 48 && r <= 57) {
        sb.writeCharCode(r);
      } else {
        sb.writeCharCode(r);
      }
    }
    return sb.toString();
  }

  void _run() {
    final s = _in.text;
    if (s.trim().isEmpty) return;
    setState(() {
      _out
        ..clear()
        ..add((name: '粗体', text: _mapBy(s, 0x1D400, 0x1D41A)))
        ..add((name: '斜体', text: _mapBy(s, 0x1D434, 0x1D44E)))
        ..add((name: '手写体', text: _mapBy(s, 0x1D49C, 0x1D4B6)))
        ..add((name: '哥特体', text: _mapBy(s, 0x1D504, 0x1D51E)))
        ..add((name: '双线体', text: _mapBy(s, 0x1D538, 0x1D552)))
        ..add((name: '等宽体', text: _mapBy(s, 0x1D670, 0x1D68A)))
        ..add((name: '装饰', text: '✧✦  $s  ✦✧'))
        ..add((name: '爱心', text: '❤ $s ❤'))
        ..add((name: '星星', text: '★彡 $s 彡★'))
        ..add((name: '波浪', text: '~*~ $s ~*~'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '特殊文本生成',
      subtitle: '一键生成好看的文字样式',
      children: [
        ToolCard(
          title: '输入文字',
          icon: Icons.text_fields_rounded,
          children: [
            ToolField(controller: _in, hint: '输入英文或数字效果最佳'),
            const SizedBox(height: 12),
            ToolButton(label: '生成样式', icon: Icons.auto_awesome_rounded, onPressed: _run),
          ],
        ),
        for (final o in _out)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ToolResult(title: o.name, content: o.text),
          ),
      ],
    );
  }
}

/// Rc4 加解密
class Rc4Tool extends StatelessWidget {
  const Rc4Tool({super.key});
  @override
  Widget build(BuildContext context) {
    return const _CipherTool(
      title: 'Rc4 加解密',
      subtitle: '对称流加密（同密钥可还原）',
      mode: 'rc4',
    );
  }
}

class _CipherTool extends StatefulWidget {
  final String title;
  final String subtitle;
  final String mode;
  const _CipherTool({required this.title, this.subtitle = '', required this.mode});

  @override
  State<_CipherTool> createState() => _CipherToolState();
}

class _CipherToolState extends State<_CipherTool> {
  final _in = TextEditingController();
  final _key = TextEditingController(text: 'softlib');
  String _out = '';

  void _run() {
    if (_in.text.isEmpty) return;
    try {
      setState(() {
        _out = _rc4(_in.text, _key.text);
      });
    } catch (e) {
      setState(() => _out = '失败：$e');
    }
  }

  String _rc4(String data, String key) {
    if (key.isEmpty) return data;
    final s = List<int>.generate(256, (i) => i);
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + s[i] + key.codeUnitAt(i % key.length)) & 0xff;
      final t = s[i];
      s[i] = s[j];
      s[j] = t;
    }
    var i2 = 0;
    j = 0;
    final out = <int>[];
    for (final b in utf8.encode(data)) {
      i2 = (i2 + 1) & 0xff;
      j = (j + s[i2]) & 0xff;
      final t = s[i2];
      s[i2] = s[j];
      s[j] = t;
      out.add(b ^ s[(s[i2] + s[j]) & 0xff]);
    }
    // 输出可读形式：优先按 UTF-8 解码，失败则输出 hex
    try {
      return utf8.decode(out);
    } catch (_) {
      return out.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      children: [
        ToolCard(
          title: '输入与密钥',
          icon: Icons.enhanced_encryption_rounded,
          children: [
            ToolField(controller: _in, hint: '输入明文或密文', maxLines: 3),
            const SizedBox(height: 10),
            ToolField(controller: _key, hint: '密钥'),
            const SizedBox(height: 12),
            ToolButton(label: '转换', icon: Icons.swap_horiz_rounded, onPressed: _run),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '结果', content: _out),
      ],
    );
  }
}

/// 随机笑话（本地笑话库）
class JokeTool extends StatefulWidget {
  const JokeTool({super.key});
  @override
  State<JokeTool> createState() => _JokeToolState();
}

class _JokeToolState extends State<JokeTool> {
  static const _jokes = [
    '我问扫地机器人：你觉得人类怎么样？\n它说：还行，就是老在我脑袋上放脚。',
    '小时候总以为钱是万能的，长大后发现……确实是。',
    '老板问我：你觉得自己最大的缺点是什么？\n我说：诚实。\n他说：我不觉得诚实是缺点。\n我说：我也不觉得。',
    '健身房教练：你想练哪个部位？\n我：想练不喘气走路。\n教练：那你出门左转，那是电梯。',
    '我妈说我花钱大手大脚。\n我说：哪有，我都是小手小脚，因为余额小。',
    '朋友问我为什么不谈恋爱。\n我说：我在等一个不需要我等的人。',
    '减肥第一天：今天少吃点。\n减肥第二天：昨天少吃的那顿补回来。',
    '程序员最讨厌的两件事：\n1. 写文档\n2. 别人不写文档',
    '闹钟的意义不是叫醒我，而是让我知道我还能再睡五分钟。',
    '我：我要开始自律了。\n手机：你确定？\n我：嗯。\n手机：我信你个鬼。',
    '存钱计划执行到第三天，我发现计划挺有钱的，我挺没钱的。',
    '人生就像打电话，不是你先挂就是我先挂，所以别太计较。',
    '同事说他昨天梦见自己中了五百万。\n我说：那你今天怎么还来上班？\n他说：梦里我也没请假。',
    '问：怎样才能健康长寿？\n答：保持呼吸，别断。',
  ];
  String _joke = _jokes.first;
  final _rnd = Random();

  void _next() {
    setState(() => _joke = _jokes[_rnd.nextInt(_jokes.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '随机笑话',
      subtitle: '共 ${_jokes.length} 条',
      children: [
        ToolCard(
          title: '今日笑话',
          icon: Icons.sentiment_very_satisfied_rounded,
          children: [
            Text(_joke,
                style: TextStyle(
                    fontSize: 15, height: 1.9, color: context.t1)),
          ],
        ),
        ToolButton(label: '换一条', icon: Icons.autorenew_rounded, onPressed: _next),
      ],
    );
  }
}

/// 舔狗日记 / 随机文案
class CopywritingTool extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> samples;
  const CopywritingTool({
    super.key,
    required this.title,
    required this.samples,
    this.subtitle = '',
  });
  @override
  State<CopywritingTool> createState() => _CopywritingToolState();
}

class _CopywritingToolState extends State<CopywritingTool> {
  final _rnd = Random();
  late String _cur = widget.samples.first;

  void _next() {
    setState(() => _cur = widget.samples[_rnd.nextInt(widget.samples.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: widget.title,
      subtitle: widget.subtitle.isEmpty ? '共 ${widget.samples.length} 条' : widget.subtitle,
      children: [
        ToolCard(
          title: '随机一条',
          icon: Icons.format_quote_rounded,
          children: [
            Text(_cur, style: TextStyle(fontSize: 15, height: 1.9, color: context.t1)),
          ],
        ),
        ToolButton(label: '换一条', icon: Icons.autorenew_rounded, onPressed: _next),
      ],
    );
  }
}

/// 扫雷（经典小游戏）
class MinesweeperTool extends StatefulWidget {
  const MinesweeperTool({super.key});
  @override
  State<MinesweeperTool> createState() => _MinesweeperToolState();
}

class _MinesweeperToolState extends State<MinesweeperTool> {
  static const int n = 9;
  static const int mines = 10;
  late List<List<int>> _board; // -1 地雷，其余为周围雷数
  late List<List<int>> _state; // 0 未开, 1 已开, 2 标旗
  bool _over = false;
  bool _win = false;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(n, (_) => List.filled(n, 0));
    _state = List.generate(n, (_) => List.filled(n, 0));
    _over = false;
    _win = false;
    _msg = '';
    final rnd = Random();
    var placed = 0;
    while (placed < mines) {
      final x = rnd.nextInt(n), y = rnd.nextInt(n);
      if (_board[y][x] == -1) continue;
      _board[y][x] = -1;
      placed++;
    }
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (_board[y][x] == -1) continue;
        var c = 0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= n || ny >= n) continue;
            if (_board[ny][nx] == -1) c++;
          }
        }
        _board[y][x] = c;
      }
    }
  }

  void _open(int x, int y) {
    if (_over || _state[y][x] != 0) return;
    setState(() {
      if (_board[y][x] == -1) {
        _over = true;
        _msg = '💥 踩到雷了！';
        for (int i = 0; i < n; i++) {
          for (int j = 0; j < n; j++) {
            if (_board[i][j] == -1) _state[i][j] = 1;
          }
        }
        return;
      }
      _flood(x, y);
      _checkWin();
    });
  }

  void _flood(int x, int y) {
    if (x < 0 || y < 0 || x >= n || y >= n) return;
    if (_state[y][x] != 0) return;
    if (_board[y][x] == -1) return;
    _state[y][x] = 1;
    if (_board[y][x] == 0) {
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          _flood(x + dx, y + dy);
        }
      }
    }
  }

  void _flag(int x, int y) {
    if (_over) return;
    setState(() {
      if (_state[y][x] == 0) {
        _state[y][x] = 2;
      } else if (_state[y][x] == 2) {
        _state[y][x] = 0;
      }
    });
  }

  void _checkWin() {
    var closed = 0;
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (_state[y][x] != 1) closed++;
      }
    }
    if (closed == mines) {
      _over = true;
      _win = true;
      _msg = '🎉 恭喜通关！';
    }
  }

  Color _numColor(int v) {
    switch (v) {
      case 1: return const Color(0xFF3B82F6);
      case 2: return const Color(0xFF10B981);
      case 3: return const Color(0xFFEF4444);
      case 4: return const Color(0xFF8B5CF6);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '扫雷',
      subtitle: '$n×$n  ·  $mines 雷',
      scroll: false,
      children: [
        if (_msg.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ToolResult(
              title: '状态',
              content: _msg,
              color: _win ? C.mint : C.danger,
            ),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: n,
                ),
                itemCount: n * n,
                itemBuilder: (_, i) {
                  final x = i % n, y = i ~/ n;
                  final st = _state[y][x];
                  final v = _board[y][x];
                  final opened = st == 1;
                  return GestureDetector(
                    onTap: () => _open(x, y),
                    onLongPress: () => _flag(x, y),
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: opened
                            ? (context.isDark
                                ? Colors.white.withAlpha(10)
                                : Colors.black.withAlpha(6))
                            : (context.isDark
                                ? Colors.white.withAlpha(22)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: C.stroke.withAlpha(40), width: 0.6),
                      ),
                      child: Center(
                        child: opened
                            ? (v == -1
                                ? const Text('💥',
                                    style: TextStyle(fontSize: 14))
                                : (v > 0
                                    ? Text('$v',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: _numColor(v)))
                                    : const SizedBox.shrink()))
                            : (st == 2
                                ? const Text('🚩',
                                    style: TextStyle(fontSize: 13))
                                : const SizedBox.shrink()),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ToolButton(label: '重新开始', icon: Icons.refresh_rounded, onPressed: () => setState(_reset)),
      ],
    );
  }
}

/// 手持弹幕
class DanmakuTool extends StatefulWidget {
  const DanmakuTool({super.key});
  @override
  State<DanmakuTool> createState() => _DanmakuToolState();
}

class _DanmakuToolState extends State<DanmakuTool> {
  final _in = TextEditingController(text: '你好呀');
  bool _playing = false;
  Color _color = Colors.white;

  static const _colors = [
    Colors.white, Color(0xFFFFD54F), Color(0xFFFF6B6B),
    Color(0xFF4B5EF5), Color(0xFF34D399), Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '手持弹幕',
      subtitle: '把手机变成 LED 滚动牌',
      children: [
        ToolCard(
          title: '弹幕内容',
          icon: Icons.closed_caption_rounded,
          children: [
            ToolField(controller: _in, hint: '输入要显示的文字'),
            const SizedBox(height: 12),
            Text('颜色', style: Ty.tiny.copyWith(color: context.t3)),
            const SizedBox(height: 8),
            Row(
              children: _colors
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == c ? C.brand : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
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
              child: Text(
                _in.text.isEmpty ? '请输入文字' : _in.text,
                style: TextStyle(
                    color: _color,
                    fontSize: 48,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        ToolButton(
          label: '开始全屏滚动',
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            if (_in.text.trim().isEmpty) return;
            setState(() => _playing = true);
          },
        ),
        if (_playing)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ToolResult(title: '提示', content: '点击下面按钮横屏显示大字号', color: C.cyan),
          ),
      ],
    );
  }
}
