import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../design/ui.dart';
import '../../utils/toast_util.dart';

/// ═══════════════════════════════════════════════════════════════
/// 工具模块 v2 —— 全新重构
/// 旧 tools_local/ext/live/missing/sample/text 全部废弃删除。
/// 原则：每个工具必须真实可用；联网工具数据源可由后台 api_url 配置。
/// ═══════════════════════════════════════════════════════════════

/// 后台传来的可配置接口地址（openTool 经 Get.arguments 传入）
String v2ApiUrl([String fallback = '']) {
  final a = Get.arguments;
  if (a is Map) {
    final u = '${a['apiUrl'] ?? ''}';
    if (u.isNotEmpty) return u;
  }
  return fallback;
}

final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  validateStatus: (c) => c != null && c < 500,
));

Future<dynamic> v2Json(String url) async {
  final r = await _dio.get(url,
      options: Options(responseType: ResponseType.json, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Mobile',
      }));
  if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  return r.data;
}

/// 统一页面骨架
class V2Scaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  const V2Scaffold(
      {super.key, required this.title, this.subtitle, required this.body, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Deco.pageBackground(context),
        SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 16, 6),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withAlpha(10)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: TextStyle(
                                fontSize: 11, color: context.t3)),
                    ],
                  ),
                ),
                ...actions,
              ]),
            ),
            Expanded(child: body),
          ]),
        ),
      ]),
    );
  }
}

/// 加载 / 出错 / 空态
Widget v2Loading() => const Center(
    child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4)));

Widget v2Error(String msg, {VoidCallback? retry}) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        if (retry != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('重试')),
        ],
      ]),
    );

/// 通用条目（列表页共用）
class V2Item {
  final String title;
  final String sub;
  final String url;
  final String tail;
  V2Item({required this.title, this.sub = '', this.url = '', this.tail = ''});
}

/// ══════════ 1) 排行榜 / 新闻类通用列表页（后台可配接口）══════════
///
/// 适配数据格式（自动识别）：
///  - 60s 开源项目: {code:200, data:[{title, hot_value, link}]}
///  - 后端 news_list: {code:1, data:{list:[{title, time, url, col}]}}
///  - wrdan 地震: {data:[...] 或数组}
class V2ListPage extends StatefulWidget {
  final String title;
  final String fallbackUrl;
  const V2ListPage({super.key, required this.title, required this.fallbackUrl});

  @override
  State<V2ListPage> createState() => _V2ListPageState();
}

class _V2ListPageState extends State<V2ListPage> {
  List<V2Item> _items = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final url = v2ApiUrl(widget.fallbackUrl);
      final j = await v2Json(url);
      final out = <V2Item>[];
      List? arr;
      if (j is Map) {
        final d = j['data'];
        if (d is List) {
          arr = d;
        } else if (d is Map && d['list'] is List) {
          arr = d['list'];
        } else if (j['list'] is List) {
          arr = j['list'];
        }
      } else if (j is List) {
        arr = j;
      }
      int i = 0;
      for (final e in arr ?? const []) {
        i++;
        if (e is Map) {
          final title = '${e['title'] ?? e['name'] ?? ''}'.trim();
          if (title.isEmpty) continue;
          out.add(V2Item(
            title: title,
            sub: '${e['col'] ?? e['place'] ?? ''}',
            url: '${e['url'] ?? e['link'] ?? ''}',
            tail: '${e['hot_value'] ?? e['hot'] ?? e['time'] ?? ''}',
          ));
        }
      }
      if (!mounted) return;
      if (out.isEmpty) throw Exception('暂无数据');
      setState(() {
        _items = out;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: widget.title,
      body: _loading
          ? v2Loading()
          : (_err != null ? v2Error(_err!, retry: _load) : _list()),
    );
  }

  Widget _list() {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final it = _items[i];
          return GestureDetector(
            onTap: () {
              if (it.url.isNotEmpty) ToastUtil.info('链接已在剪贴板');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Row(children: [
                SizedBox(
                  width: 26,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: i < 3 ? const Color(0xFF4B5EF5) : Colors.grey.shade400)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      if (it.sub.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(it.sub,
                              style: TextStyle(
                                  fontSize: 11, color: context.t3)),
                        ),
                    ],
                  ),
                ),
                if (it.tail.isNotEmpty)
                  Text(it.tail,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// ══════════ 2) 每日60秒（图文日报，60s 开源项目）══════════
class V2DailyNewsPage extends StatefulWidget {
  const V2DailyNewsPage({super.key});
  @override
  State<V2DailyNewsPage> createState() => _V2DailyNewsPageState();
}

class _V2DailyNewsPageState extends State<V2DailyNewsPage> {
  List<String> _news = [];
  String _date = '';
  String? _tip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final j = await v2Json(v2ApiUrl('https://60s-api.viki.moe/v2/60s'));
      final d = j is Map ? j['data'] : null;
      if (d is Map) {
        _news = (d['news'] as List? ?? []).map((e) => '$e').toList();
        _date = '${d['date'] ?? ''}';
      }
      _tip = null;
    } catch (_) {
      _tip = '加载失败，下拉重试';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: '每日60秒',
      subtitle: _date,
      body: _loading
          ? v2Loading()
          : RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  for (int i = 0; i < _news.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: Color(0xFF4B5EF5), shape: BoxShape.circle),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_news[i],
                                style: const TextStyle(fontSize: 14, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  if (_tip != null)
                    Center(child: Text(_tip!, style: TextStyle(color: context.t3))),
                ],
              ),
            ),
    );
  }
}

/// ══════════ 3) 在线翻译（MyMemory 开源接口）══════════
class V2TranslatePage extends StatefulWidget {
  const V2TranslatePage({super.key});
  @override
  State<V2TranslatePage> createState() => _V2TranslatePageState();
}

class _V2TranslatePageState extends State<V2TranslatePage> {
  final _c = TextEditingController();
  String _result = '';
  bool _busy = false;
  bool _zh2en = false; // 默认英→中

  Future<void> _go() async {
    final q = _c.text.trim();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    try {
      final pair = _zh2en ? 'zh-CN|en' : 'en|zh-CN';
      final j = await v2Json(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(q)}&langpair=$pair');
      final t = j is Map && j['responseData'] is Map
          ? '${j['responseData']['translatedText'] ?? ''}'
          : '';
      setState(() => _result = t);
    } catch (_) {
      setState(() => _result = '');
      ToastUtil.error('翻译失败，请重试');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: '在线翻译',
      subtitle: 'MyMemory 开源引擎',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _chip(_zh2en ? '中 → 英' : '英 → 中', () => setState(() => _zh2en = !_zh2en)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: TextField(
              controller: _c,
              maxLines: 4,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: '输入要翻译的文本…'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _go,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4B5EF5),
                minimumSize: const Size.fromHeight(46)),
            child: Text(_busy ? '翻译中…' : '翻 译'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF4B5EF5).withAlpha(14),
                  borderRadius: BorderRadius.circular(14)),
              child: Text(_result,
                  style: const TextStyle(fontSize: 15, height: 1.6)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFF4B5EF5).withAlpha(18),
              borderRadius: BorderRadius.circular(20)),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFF4B5EF5), fontWeight: FontWeight.w700)),
        ),
      );
}

/// ══════════ 4) 汇率换算（open.er-api 开源接口）══════════
class V2ExchangePage extends StatefulWidget {
  const V2ExchangePage({super.key});
  @override
  State<V2ExchangePage> createState() => _V2ExchangePageState();
}

class _V2ExchangePageState extends State<V2ExchangePage> {
  final _c = TextEditingController(text: '100');
  Map<String, double> _rates = {};
  String _base = 'USD';
  bool _loading = true;
  String _target = 'CNY';
  String _out = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final j = await v2Json('https://open.er-api.com/v6/latest/$_base');
      final r = j is Map ? j['rates'] : null;
      if (r is Map) {
        _rates = r.map((k, v) => MapEntry('$k', (v is num) ? v.toDouble() : 0.0));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _calc() {
    final v = double.tryParse(_c.text) ?? 0;
    final rate = _rates[_target];
    setState(() => _out = rate == null ? '' : (v * rate).toStringAsFixed(2));
  }

  static const _common = ['CNY', 'USD', 'EUR', 'JPY', 'KRW', 'HKD', 'GBP', 'THB'];

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: '汇率换算',
      subtitle: 'open.er-api · 实时汇率',
      body: _loading
          ? v2Loading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('基准货币', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _common
                      .map((c) => GestureDetector(
                            onTap: () {
                              _base = c;
                              if (_target == c) _target = c == 'CNY' ? 'USD' : 'CNY';
                              _load().then((_) => _calc());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                              decoration: BoxDecoration(
                                color: _base == c
                                    ? const Color(0xFF4B5EF5)
                                    : const Color(0xFF4B5EF5).withAlpha(16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(c,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _base == c
                                          ? Colors.white
                                          : const Color(0xFF4B5EF5))),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: _c,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            border: InputBorder.none, hintText: '金额'),
                        onChanged: (_) => _calc(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonFormField<String>(
                        value: _target,
                        items: _rates.keys
                                .where((k) => _common.contains(k))
                                .map((k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k, style: const TextStyle(fontSize: 13))))
                                .toList() +
                            (_common.contains(_target)
                                ? <DropdownMenuItem<String>>[]
                                : [
                                    DropdownMenuItem(
                                        value: _target,
                                        child: Text(_target,
                                            style: const TextStyle(fontSize: 13)))
                                  ]),
                        onChanged: (v) {
                          setState(() => _target = v ?? _target);
                          _calc();
                        },
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _calc,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B5EF5),
                      minimumSize: const Size.fromHeight(46)),
                  child: const Text('换 算'),
                ),
                if (_out.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF4B5EF5).withAlpha(14),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Text('$_out $_target',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('1 $_base ≈ ${_rates[_target]?.toStringAsFixed(4) ?? '-'} $_target',
                          style: TextStyle(fontSize: 12, color: context.t3)),
                    ]),
                  ),
                ],
              ],
            ),
    );
  }
}

/// ══════════ 5) 二维码生成（本地 qr_flutter）══════════
class V2QrcodePage extends StatefulWidget {
  const V2QrcodePage({super.key});
  @override
  State<V2QrcodePage> createState() => _V2QrcodePageState();
}

class _V2QrcodePageState extends State<V2QrcodePage> {
  final _c = TextEditingController();
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: '二维码生成',
      subtitle: '本地生成 · 不联网',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _c,
              onChanged: (v) => setState(() => _text = v),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '输入文字 / 链接',
                  contentPadding: EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: _text.isEmpty
                  ? SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                          child: Text('输入内容生成二维码',
                              style: TextStyle(
                                  fontSize: 12, color: context.t3))))
                  : QrImageView(data: _text, size: 200),
            ),
          ),
        ],
      ),
    );
  }
}

/// ══════════ 6) 秒表（本地）══════════
class V2StopwatchPage extends StatefulWidget {
  const V2StopwatchPage({super.key});
  @override
  State<V2StopwatchPage> createState() => _V2StopwatchPageState();
}

class _V2StopwatchPageState extends State<V2StopwatchPage> {
  Timer? _t;
  int _ms = 0;
  final List<String> _laps = [];

  bool get _running => _t != null;

  void _toggle() {
    if (_running) {
      _t?.cancel();
      _t = null;
    } else {
      _t = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (mounted) setState(() => _ms += 50);
      });
    }
    if (mounted) setState(() {});
  }

  void _reset() {
    _t?.cancel();
    _t = null;
    setState(() {
      _ms = 0;
      _laps.clear();
    });
  }

  String get _fmt {
    final m = (_ms ~/ 60000).toString().padLeft(2, '0');
    final s = ((_ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final cs = ((_ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$cs';
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: '秒表',
      body: Column(children: [
        const Spacer(),
        Text(_fmt,
            style: const TextStyle(
                fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _btn(_running ? '停止' : '启动', _toggle,
              bg: _running ? const Color(0xFFFF5252) : const Color(0xFF4B5EF5)),
          const SizedBox(width: 14),
          _btn('计次', () => setState(() => _laps.insert(0, _fmt)),
              bg: const Color(0xFF4B5EF5).withAlpha(30), fg: const Color(0xFF4B5EF5)),
          const SizedBox(width: 14),
          _btn('重置', _reset, bg: const Color(0xFF4B5EF5).withAlpha(30), fg: const Color(0xFF4B5EF5)),
        ]),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _laps.length,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              title: Text('第 ${_laps.length - i} 次'),
              trailing: Text(_laps[i],
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _btn(String text, VoidCallback onTap,
          {Color bg = Colors.blue, Color fg = Colors.white}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(24)),
          child: Text(text,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
        ),
      );
}

/// ══════════ 7) 倒计时（本地）══════════
class V2CountdownPage extends StatefulWidget {
  const V2CountdownPage({super.key});
  @override
  State<V2CountdownPage> createState() => _V2CountdownPageState();
}

class _V2CountdownPageState extends State<V2CountdownPage> {
  int _left = 0;
  Timer? _t;

  void _start(int seconds) {
    _t?.cancel();
    setState(() => _left = seconds);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return _t?.cancel();
      if (_left <= 1) {
        _t?.cancel();
        _t = null;
        setState(() => _left = 0);
        ToastUtil.info('时间到！');
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  String get _fmt {
    final m = (_left ~/ 60).toString().padLeft(2, '0');
    final s = (_left % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: '倒计时',
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_fmt,
            style: const TextStyle(
                fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 30),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final v in [1, 3, 5, 10, 25, 60])
              GestureDetector(
                onTap: () => _start(v * 60),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF4B5EF5).withAlpha(18),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$v 分钟',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5EF5))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_left > 0)
          TextButton(
              onPressed: () {
                _t?.cancel();
                _t = null;
                setState(() => _left = 0);
              },
              child: const Text('停止')),
      ]),
    );
  }
}

/// ══════════ 8) IP 查询（ip-api 免费源）══════════
class V2IpPage extends StatefulWidget {
  const V2IpPage({super.key});
  @override
  State<V2IpPage> createState() => _V2IpPageState();
}

class _V2IpPageState extends State<V2IpPage> {
  Map _info = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final j = await v2Json('http://ip-api.com/json/?lang=zh-CN');
      if (j is Map) _info = j;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return V2Scaffold(
      title: 'IP 查询',
      subtitle: 'ip-api · 免费',
      body: _loading
          ? v2Loading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in {
                  'IP 地址': _info['query'],
                  '国家': _info['country'],
                  '省份': _info['regionName'],
                  '城市': _info['city'],
                  '运营商': _info['isp'],
                  '时区': _info['timezone'],
                }.entries)
                  if ('${e.value}'.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        SizedBox(
                            width: 80,
                            child: Text(e.key,
                                style: TextStyle(
                                    fontSize: 13, color: context.t3))),
                        Expanded(
                            child: Text('${e.value}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700))),
                      ]),
                    ),
              ],
            ),
    );
  }
}
