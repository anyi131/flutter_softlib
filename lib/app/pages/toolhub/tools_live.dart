import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import 'tools_common.dart';

/// ═══════════════════════════════════════════════════════════════
///  联网数据类工具集合（tools_live.dart）
///
///  设计原则：
///   · 所有外部接口均 try-catch，10 秒超时，失败一律降级到内置静态数据
///   · 每个页面必备「加载态 / 错误态 / 空态」，绝不白屏
///   · 不新增 pubspec 依赖：Dio / url_launcher / cached_network_image / photo_view
///     均已在 pubspec.yaml 中声明
///
///  数据源总览：
///   WeatherTool      → wttr.in                            （失败：内置示例天气）
///   OilPriceTool     → 内置油价表（接口不稳定，静态数据）  （无需网络）
///   ExpressTool      → 后端 jzs 搜索 + 快递100 外链降级   （失败：跳转官网）
///   HotSearchTool    → api.vvhan.com 微博热搜             （失败：内置热搜示例）
///   TodayHistoryTool → api.vvhan.com 历史上的今天        （失败：内置历史事件）
///   NewsTool         → api.vvhan.com 知乎热榜             （失败：内置新闻示例）
///   ForexTool        → open.er-api.com 汇率               （失败：内置汇率表）
///   NovelTool        → 后端 jzs 搜索 / 内置书单           （失败：内置书单）
///   NovelDlTool      → 内置 TXT 书单 + 外链下载           （无需网络）
///   WallpaperTool    → api.btstu.cn / picsum.photos       （失败：picsum 兜底）
///   AvatarTool       → api.btstu.cn / picsum.photos       （失败：picsum 兜底）
///   MemeTool         → api.btstu.cn / picsum.photos       （失败：picsum 兜底）
///   BeautyTool       → api.btstu.cn 随机图                （失败：picsum 兜底）
///   PicsumTool       → picsum.photos                      （失败：内置占位图）
///   NoWatermarkTool  → 后端 parse_api.php 解析            （失败：友好降级提示）
/// ═══════════════════════════════════════════════════════════════

const String _kBaseUrl = 'https://flrjk.52yfx.cn';

/// 全局共享 Dio（自带 10 秒超时；不复用 SoftService 的私有实例）
final Dio _dio = Dio(BaseOptions(
  baseUrl: _kBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
  headers: const {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json,text/plain,*/*',
  },
));

/// 外部域名专用 Dio（不限 baseURL，同样 10 秒超时）
final Dio _dioRaw = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: const {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  },
));

/// 统一网络请求（外部完整 URL），期望 JSON（可能是 Map 或 List）
Future<dynamic> _httpJson(String url) async {
  final r = await _dioRaw.get(
    url,
    options: Options(responseType: ResponseType.json),
  );
  return r.data;
}

/// 打开外链（pubspec 已含 url_launcher）。
/// 优先用系统浏览器打开；失败则复制链接兜底，绝不抛异常导致白屏。
Future<void> _launch(String url) async {
  final u = url.trim();
  if (u.isEmpty) {
    ToastUtil.error('链接为空');
    return;
  }
  try {
    final uri = Uri.parse(u);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {
    // 忽略，走复制兜底
  }
  await Clipboard.setData(ClipboardData(text: u));
  ToastUtil.info('无法打开，已复制链接，可粘贴到浏览器访问');
}

/// 通用「安全解析」小工具：从任意动态对象里取字符串
String _s(dynamic v, [String def = '']) {
  if (v == null) return def;
  final t = '$v';
  return (t == 'null' || t.isEmpty) ? def : t;
}

/// 降级提示条：明确告诉用户当前展示的是内置数据
class _FallbackBar extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _FallbackBar({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: C.warning.withAlpha(context.isDark ? 34 : 22),
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.warning.withAlpha(90), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: C.warning),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: context.t2)),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Text('重试',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: C.brand)),
            ),
        ],
      ),
    );
  }
}

/// 统一图片卡片（含加载占位 / 失败占位）
class _NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? width;
  final double? height;
  const _NetImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        color: C.brand.withAlpha(context.isDark ? 26 : 14),
        child: Icon(fallbackIcon, color: context.t3, size: 24),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: 640,
      placeholder: (_, __) =>
          Container(color: C.brand.withAlpha(context.isDark ? 26 : 14)),
      errorWidget: (_, __, ___) => Container(
        color: C.brand.withAlpha(context.isDark ? 26 : 14),
        child: Icon(fallbackIcon, color: context.t3, size: 24),
      ),
    );
  }
}

/// 全屏图片预览（PhotoView 缩放 + 长按复制链接）
class _ImageViewerPage extends StatelessWidget {
  final String url;
  const _ImageViewerPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(url),
            backgroundDecoration:
                const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, __) => const Center(
              child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white70)),
            ),
            errorBuilder: (_, __, ___) => const Center(
              child: Text('图片加载失败',
                  style: TextStyle(color: Colors.white54)),
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      copyText(url);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(R.full),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.link_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text('复制直链',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 1. 天气查询
/// 数据源：https://wttr.in/{城市}?format=j1 （JSON，无需 Key）
/// 失败降级：内置示例天气卡片 + 友好提示
/// ═══════════════════════════════════════════════════════════════
class WeatherTool extends StatefulWidget {
  const WeatherTool({super.key});

  @override
  State<WeatherTool> createState() => _WeatherToolState();
}

class _WeatherToolState extends State<WeatherTool> {
  final _cityCtrl = TextEditingController(text: '北京');
  bool _loading = false;
  String? _error;
  bool _fallback = false;

  /// 解析后的天气数据（键值对格式，便于统一渲染）
  Map<String, String> _data = {};

  static const _hotCities = ['北京', '上海', '广州', '深圳', '杭州', '成都', '武汉', '西安'];

  /// 内置降级天气（接口完全不可用时展示，保证不白屏）
  static const _demo = {
    '城市': '北京（示例数据）',
    '天气': '晴',
    '温度': '22 ℃',
    '体感': '21 ℃',
    '湿度': '45%',
    '风力': '西南风 2 级',
    '能见度': '10 km',
    '更新时间': '—',
  };

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _query([String? city]) async {
    final c = (city ?? _cityCtrl.text).trim();
    if (c.isEmpty) {
      ToastUtil.info('请输入城市名');
      return;
    }
    _cityCtrl.text = c;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = 'https://wttr.in/${Uri.encodeComponent(c)}?format=j1';
      final json = await _httpJson(url);
      final cur = (json is Map) ? json['current_condition'] : null;
      final near = (json is Map && json['nearest_area'] is List)
          ? (json['nearest_area'] as List).first
          : null;
      if (cur is! List || cur.isEmpty) {
        throw Exception('返回数据为空');
      }
      final w = cur.first as Map;
      final desc = (w['lang_zh'] is List && (w['lang_zh'] as List).isNotEmpty)
          ? (w['lang_zh'] as List).first['value']
          : ((w['weatherDesc'] is List && (w['weatherDesc'] as List).isNotEmpty)
              ? (w['weatherDesc'] as List).first['value']
              : '未知');
      String areaName = c;
      if (near is Map) {
        final a = near['areaName'];
        if (a is List && a.isNotEmpty) areaName = _s(a.first['value'], c);
      }
      if (!mounted) return;
      setState(() {
        _data = {
          '城市': '$areaName',
          '天气': _s(desc, '未知'),
          '温度': '${_s(w['temp_C'], '-')} ℃',
          '体感': '${_s(w['FeelsLikeC'], '-')} ℃',
          '湿度': '${_s(w['humidity'], '-')}%',
          '风力': '${_s(w['winddir16Point'])} ${_s(w['windspeedKmph'])} km/h',
          '能见度': '${_s(w['visibility'], '-')} km',
          '更新时间': _s(w['observation_time'], '—'),
        };
        _fallback = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data = Map<String, String>.from(_demo);
        _fallback = true;
        _error = '天气接口请求失败，已展示内置示例数据';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '天气查询',
      subtitle: '数据源 wttr.in · 实时天气',
      children: [
        ToolCard(
          title: '城市',
          icon: Icons.location_city_rounded,
          children: [
            ToolField(
              controller: _cityCtrl,
              hint: '输入城市名，如：北京 / Shanghai',
              onChanged: (_) {},
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '查询天气',
              icon: Icons.wb_sunny_rounded,
              loading: _loading,
              onPressed: () => _query(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hotCities
                  .map((c) => GestureDetector(
                        onTap: () => _query(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: C.brand.withAlpha(context.isDark ? 30 : 18),
                            borderRadius: BorderRadius.circular(R.full),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: C.brand)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        if (_loading) const LoadingState(text: '正在获取天气…'),
        if (!_loading && _data.isEmpty)
          const EmptyState(
              text: '请输入城市名查询天气',
              icon: Icons.wb_cloudy_rounded,
              hint: '支持中文 / 拼音 / 英文城市名'),
        if (!_loading && _data.isNotEmpty) ...[
          if (_fallback)
            _FallbackBar(text: _error ?? '接口不可用，已降级', onRetry: () => _query()),
          ToolCard(
            title: '实况天气',
            icon: Icons.thermostat_rounded,
            children: [
              _kvTable(_data),
              const SizedBox(height: 12),
              ToolResult(
                title: '天气简报',
                content: '${_data['城市']}　${_data['天气']}　${_data['温度']}　'
                    '湿度${_data['湿度']}　${_data['风力']}',
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 键值对表格
  Widget _kvTable(Map<String, String> m) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(
            color: context.isDark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(8),
            width: 0.8),
      ),
      child: Column(
        children: m.entries.toList().asMap().entries.map((e) {
          final i = e.key;
          final kv = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: i == m.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: context.isDark
                              ? Colors.white.withAlpha(14)
                              : Colors.black.withAlpha(6),
                          width: 0.7)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(kv.key,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.t2)),
                ),
                Expanded(
                  child: Text(kv.value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.t1)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 2. 全国油价
/// ★ 说明：免费油价接口极不稳定（多家已停服/需付费 Key），
///   故这里使用「内置静态油价表」，不发起网络请求，保证永远可用。
///   数据为示例参考值，实际以当地加油站点价为准。
/// ═══════════════════════════════════════════════════════════════
class OilPriceTool extends StatefulWidget {
  const OilPriceTool({super.key});

  @override
  State<OilPriceTool> createState() => _OilPriceToolState();
}

class _OilPriceToolState extends State<OilPriceTool> {
  final _kwCtrl = TextEditingController();
  String _kw = '';

  /// 省份 → [92#, 95#, 98#, 0#柴油]（内置示例数据，单位：元/升）
  static const _prices = <String, List<String>>{
    '北京': ['7.45', '7.93', '8.43', '7.14'],
    '上海': ['7.41', '7.89', '8.39', '7.08'],
    '广东': ['7.46', '8.08', '9.08', '7.10'],
    '江苏': ['7.42', '7.90', '8.80', '7.06'],
    '浙江': ['7.42', '7.90', '8.65', '7.09'],
    '山东': ['7.41', '7.95', '8.67', '7.01'],
    '河南': ['7.45', '7.96', '8.61', '7.09'],
    '河北': ['7.44', '7.86', '8.48', '7.10'],
    '四川': ['7.55', '8.07', '8.76', '7.16'],
    '湖北': ['7.45', '7.97', '8.65', '7.08'],
    '湖南': ['7.40', '7.87', '8.67', '7.16'],
    '福建': ['7.44', '7.95', '8.70', '7.13'],
    '安徽': ['7.40', '7.92', '8.75', '7.13'],
    '陕西': ['7.37', '7.79', '8.49', '7.03'],
    '辽宁': ['7.40', '7.89', '8.60', '7.00'],
    '黑龙江': ['7.46', '7.98', '9.05', '6.94'],
    '吉林': ['7.41', '7.99', '8.71', '7.02'],
    '山西': ['7.40', '7.99', '8.69', '7.16'],
    '江西': ['7.41', '7.95', '8.95', '7.14'],
    '广西': ['7.50', '8.10', '9.10', '7.15'],
    '云南': ['7.59', '8.15', '8.83', '7.17'],
    '贵州': ['7.58', '8.01', '8.91', '7.20'],
    '重庆': ['7.52', '7.94', '8.94', '7.17'],
    '天津': ['7.44', '7.86', '8.86', '7.10'],
    '海南': ['8.56', '9.09', '10.23', '7.19'],
    '甘肃': ['7.44', '7.94', '8.44', '7.00'],
    '内蒙古': ['7.38', '7.87', '8.65', '6.98'],
    '新疆': ['7.25', '7.76', '8.66', '6.88'],
    '宁夏': ['7.35', '7.77', '8.87', '6.99'],
    '青海': ['7.40', '7.94', '8.65', '7.02'],
    '西藏': ['8.32', '8.80', '—', '7.64'],
    '香港': ['—', '—', '—', '—'],
  };

  @override
  void dispose() {
    _kwCtrl.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<String>>> get _filtered {
    final list = _prices.entries.toList();
    if (_kw.trim().isEmpty) return list;
    return list
        .where((e) => e.key.contains(_kw.trim()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return ToolScaffold(
      title: '全国油价',
      subtitle: '内置数据 · 仅供参考',
      children: [
        ToolCard(
          title: '搜索省份',
          icon: Icons.local_gas_station_rounded,
          children: [
            ToolField(
              controller: _kwCtrl,
              hint: '输入省份名，如：广东',
              onChanged: (v) => setState(() => _kw = v),
            ),
          ],
        ),
        _FallbackBar(
          text: '油价接口不稳定（多家已停服），当前展示内置静态数据，'
              '实际以当地加油站点价为准。',
        ),
        if (list.isEmpty)
          const EmptyState(text: '没有匹配的省份', icon: Icons.search_off_rounded)
        else
          ToolCard(
            title: '各省油价（元/升）',
            icon: Icons.format_list_numbered_rounded,
            trailing: Text('${list.length} 条',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: [
              _header(context),
              const SizedBox(height: 4),
              ...list.map((e) => _row(context, e.key, e.value)),
            ],
          ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final st = TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w800, color: context.t3);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('省份', style: st)),
          Expanded(flex: 2, child: Text('92#', style: st, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('95#', style: st, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('98#', style: st, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('0#柴油', style: st, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String province, List<String> p) {
    final st = TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: context.t1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: context.isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(6),
              width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(province,
                  style: st.copyWith(color: context.t1))),
          Expanded(
              flex: 2,
              child: Text(p.isNotEmpty ? p[0] : '—',
                  textAlign: TextAlign.center, style: st)),
          Expanded(
              flex: 2,
              child: Text(p.length > 1 ? p[1] : '—',
                  textAlign: TextAlign.center, style: st)),
          Expanded(
              flex: 2,
              child: Text(p.length > 2 ? p[2] : '—',
                  textAlign: TextAlign.center, style: st)),
          Expanded(
              flex: 2,
              child: Text(p.length > 3 ? p[3] : '—',
                  textAlign: TextAlign.center, style: st)),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 3. 快递查询
/// 数据源：后端 jzs 搜索（/api/softlib/jzs/search?kw=单号）
///        快递100 官方查询页作为手动降级入口
/// 说明：快递100 开放接口需要付费 Key，公开免费接口多已失效，
///      故这里「能查则查、不能查则引导到官网」，绝不留白屏。
/// ═══════════════════════════════════════════════════════════════
class ExpressTool extends StatefulWidget {
  const ExpressTool({super.key});

  @override
  State<ExpressTool> createState() => _ExpressToolState();
}

class _ExpressToolState extends State<ExpressTool> {
  final _noCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _needManual = false;
  List<String> _steps = [];

  static const _companies = [
    '顺丰速运', '中通快递', '圆通速递', '韵达快递', '申通快递',
    '京东物流', '极兔速递', '邮政 EMS', '德邦快递', '天天快递',
  ];

  @override
  void dispose() {
    _noCtrl.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final no = _noCtrl.text.trim();
    if (no.isEmpty) {
      ToastUtil.info('请输入快递单号');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _needManual = false;
      _steps = [];
    });
    try {
      // 尝试走后端聚合搜索（若后端已接入快递轨迹会返回 list）
      final r = await _dio.get('/api/softlib/jzs/search',
          queryParameters: {'kw': no});
      final data = r.data;
      final list = (data is Map && data['data'] is Map)
          ? (data['data']['list'] as List?)
          : null;
      final hits = (list ?? [])
          .where((e) => '$e'.contains(no))
          .map((e) => '$e')
          .toList();
      if (!mounted) return;
      setState(() {
        _steps = hits;
        _needManual = hits.isEmpty;
        _loading = false;
        if (hits.isEmpty) {
          _error = '未查询到该单号的物流轨迹，可前往快递100 官网查询';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _needManual = true;
        _error = '接口暂不可用，请到快递100 官网查询';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '快递查询',
      subtitle: '单号查询 · 失败可跳转官网',
      children: [
        ToolCard(
          title: '快递单号',
          icon: Icons.local_shipping_rounded,
          children: [
            ToolField(
              controller: _noCtrl,
              hint: '粘贴或输入快递单号',
              keyboard: TextInputType.text,
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '查询物流',
              icon: Icons.search_rounded,
              loading: _loading,
              onPressed: _query,
            ),
          ],
        ),
        if (_loading) const LoadingState(text: '正在查询物流…'),
        if (!_loading && _error != null) ...[
          _FallbackBar(text: _error!),
          ToolCard(
            title: '手动查询',
            icon: Icons.open_in_new_rounded,
            children: [
              Text('免费快递接口多已失效，建议直接前往快递100 官网查询单号：',
                  style: Ty.small.copyWith(color: context.t2)),
              const SizedBox(height: 8),
              ToolResult(
                title: '待查询单号',
                content: _noCtrl.text.trim().isEmpty ? '—' : _noCtrl.text.trim(),
              ),
              const SizedBox(height: 12),
              ToolButton(
                label: '前往快递100 官网查询',
                icon: Icons.open_in_browser_rounded,
                onPressed: () => _launch(
                    'https://www.kuaidi100.com/?nu=${Uri.encodeComponent(_noCtrl.text.trim())}'),
              ),
            ],
          ),
        ],
        if (!_loading && _steps.isNotEmpty)
          ToolCard(
            title: '查询结果',
            icon: Icons.timeline_rounded,
            children: [
              ..._steps.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: C.brand, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(s,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: context.t1)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ToolCard(
          title: '支持查询的快递公司',
          icon: Icons.list_alt_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _companies
                  .map((c) => Pill(c, small: true))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 4. 今日热搜
/// 数据源：https://api.vvhan.com/api/hotlist/wbHot （微博热搜，公开）
/// 失败降级：内置热搜示例
/// ═══════════════════════════════════════════════════════════════
class HotSearchTool extends StatefulWidget {
  const HotSearchTool({super.key});

  @override
  State<HotSearchTool> createState() => _HotSearchToolState();
}

class _HotSearchToolState extends State<HotSearchTool> {
  bool _loading = true;
  bool _fallback = false;
  String? _error;
  List<Map<String, String>> _list = [];

  /// 内置降级热搜
  static const _demo = <List<String>>[
    ['国产大飞机 C919 再获百架订单', '1', ''],
    ['多地气温骤降 寒潮蓝色预警发布', '2', ''],
    ['新一代国产芯片正式量产', '3', ''],
    ['秋天的第一杯奶茶又火了', '4', ''],
    ['高校新增人工智能本科专业', '5', ''],
    ['新能源汽车出口再创新高', '6', ''],
    ['电影市场国庆档票房破纪录', '7', ''],
    ['亚运健儿载誉归来', '8', ''],
    ['数字人民币试点范围扩大', '9', ''],
    ['古籍修复师走红网络', '10', ''],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _httpJson('https://api.vvhan.com/api/hotlist/wbHot');
      // 兼容 {data:[...]} / {data:{list:[...]}} / {list:[...]} 多种结构
      dynamic arr;
      if (json is Map) {
        if (json['data'] is List) {
          arr = json['data'];
        } else if (json['data'] is Map && json['data']['list'] is List) {
          arr = json['data']['list'];
        } else if (json['list'] is List) {
          arr = json['list'];
        } else if (json['data'] is Map &&
            json['data']['data'] is List) {
          arr = json['data']['data'];
        }
      } else if (json is List) {
        arr = json;
      }
      final out = <Map<String, String>>[];
      if (arr is List) {
        int i = 0;
        for (final it in arr) {
          i++;
          if (it is Map) {
            final title = _s(it['title'] ?? it['name'] ?? it['word']);
            final url = _s(it['url'] ?? it['mobilUrl'] ?? it['href']);
            final hot = _s(it['hot'] ?? it['hotValue'] ?? it['num'] ?? '$i');
            if (title.isNotEmpty) {
              out.add({'title': title, 'url': url, 'hot': hot, 'rank': '$i'});
            }
          } else if ('$it'.isNotEmpty) {
            out.add({'title': '$it', 'url': '', 'hot': '', 'rank': '$i'});
          }
        }
      }
      if (!mounted) return;
      if (out.isEmpty) throw Exception('empty');
      setState(() {
        _list = out;
        _fallback = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _list = _demo
            .asMap()
            .entries
            .map((e) => {
                  'title': e.value[0],
                  'url': e.value[2],
                  'hot': e.value[1],
                  'rank': '${e.key + 1}',
                })
            .toList();
        _fallback = true;
        _error = '热搜接口请求失败，已展示内置示例数据';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '今日热搜',
      subtitle: '微博热搜榜 · api.vvhan.com',
      actions: [
        GestureDetector(
          onTap: _load,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.refresh_rounded, size: 20, color: context.t2),
          ),
        ),
      ],
      children: [
        if (_loading) const LoadingState(text: '正在获取热搜…'),
        if (!_loading && _fallback)
          _FallbackBar(text: _error ?? '已降级', onRetry: _load),
        if (!_loading && _list.isEmpty)
          const EmptyState(text: '暂无热搜数据', icon: Icons.whatshot_rounded)
        else if (!_loading)
          ToolCard(
            title: '实时热搜榜',
            icon: Icons.whatshot_rounded,
            trailing: Text('共 ${_list.length} 条',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: _list
                .map((e) => _hotRow(context, e))
                .toList(),
          ),
      ],
    );
  }

  Widget _hotRow(BuildContext context, Map<String, String> e) {
    final rank = int.tryParse(e['rank'] ?? '') ?? 99;
    final isTop3 = rank <= 3;
    return InkWell(
      onTap: () {
        final u = e['url'] ?? '';
        if (u.isNotEmpty) {
          _launch(u);
        } else {
          copyText(e['title'] ?? '');
        }
      },
      borderRadius: BorderRadius.circular(R.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isTop3 ? C.rose : C.brand.withAlpha(context.isDark ? 30 : 16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(e['rank'] ?? '',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: isTop3 ? Colors.white : C.brand)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(e['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: context.t1)),
            ),
            if ((e['hot'] ?? '').isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(e['hot']!,
                  style: Ty.tiny.copyWith(fontSize: 10.5, color: context.t3)),
            ],
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 5. 历史上的今天
/// 数据源：https://api.vvhan.com/api/history/today
/// 失败降级：内置历史事件
/// ═══════════════════════════════════════════════════════════════
class TodayHistoryTool extends StatefulWidget {
  const TodayHistoryTool({super.key});

  @override
  State<TodayHistoryTool> createState() => _TodayHistoryToolState();
}

class _TodayHistoryToolState extends State<TodayHistoryTool> {
  bool _loading = true;
  bool _fallback = false;
  String? _error;
  List<Map<String, String>> _list = [];

  static const _demo = <List<String>>[
    ['1949', '中华人民共和国中央人民政府成立'],
    ['1955', '新疆维吾尔自治区正式成立'],
    ['1964', '我国第一颗原子弹爆炸成功'],
    ['2003', '神舟五号载人飞船成功发射并返回'],
    ['2007', '嫦娥一号探月卫星成功发射'],
    ['2019', '北京大兴国际机场正式投运'],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _httpJson('https://api.vvhan.com/api/history/today');
      dynamic arr;
      if (json is Map) {
        arr = json['data'] ?? json['list'] ?? json['result'];
      } else {
        arr = json;
      }
      final out = <Map<String, String>>[];
      if (arr is List) {
        for (final it in arr) {
          if (it is Map) {
            final t = _s(it['title'] ?? it['event'] ?? it['des']);
            final y = _s(it['year'] ?? it['date'] ?? it['time']);
            if (t.isNotEmpty) out.add({'year': y, 'title': t});
          } else if ('$it'.isNotEmpty) {
            out.add({'year': '', 'title': '$it'});
          }
        }
      }
      if (!mounted) return;
      if (out.isEmpty) throw Exception('empty');
      setState(() {
        _list = out;
        _fallback = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _list = _demo.map((e) => {'year': e[0], 'title': e[1]}).toList();
        _fallback = true;
        _error = '历史接口请求失败，已展示内置示例数据';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ToolScaffold(
      title: '历史上的今天',
      subtitle: '${now.month} 月 ${now.day} 日',
      children: [
        if (_loading) const LoadingState(text: '正在获取历史事件…'),
        if (!_loading && _fallback)
          _FallbackBar(text: _error ?? '已降级', onRetry: _load),
        if (!_loading && _list.isEmpty)
          const EmptyState(text: '暂无历史事件', icon: Icons.history_edu_rounded)
        else if (!_loading)
          ToolCard(
            title: '同日发生的重大事件',
            icon: Icons.history_edu_rounded,
            trailing: Text('${_list.length} 条',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: _list
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: C.brand.withAlpha(
                                  context.isDark ? 34 : 18),
                              borderRadius: BorderRadius.circular(R.full),
                            ),
                            child: Text(
                                (e['year'] ?? '').isEmpty
                                    ? '—'
                                    : e['year']!,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: C.brand)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e['title'] ?? '',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: context.t1)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 6. 新闻资讯
/// 数据源：https://api.vvhan.com/api/hotlist/zhihuHot （知乎热榜）
/// 失败降级：内置新闻示例
/// ═══════════════════════════════════════════════════════════════
class NewsTool extends StatefulWidget {
  const NewsTool({super.key});

  @override
  State<NewsTool> createState() => _NewsToolState();
}

class _NewsToolState extends State<NewsTool> {
  bool _loading = true;
  bool _fallback = false;
  String? _error;
  List<Map<String, String>> _list = [];

  static const _demo = <List<String>>[
    ['今日要闻：多地出台促进消费新举措', ''],
    ['科技创新大会召开，多项成果发布', ''],
    ['全国铁路今日预计发送旅客超千万人次', ''],
    ['教育部发布最新高校专业目录', ''],
    ['新一轮医保药品目录调整结果公布', ''],
    ['新能源汽车下乡活动启动', ''],
    ['多地推出购房支持政策', ''],
    ['文旅部提示假期出行安全', ''],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _httpJson('https://api.vvhan.com/api/hotlist/zhihuHot');
      dynamic arr;
      if (json is Map) {
        if (json['data'] is List) {
          arr = json['data'];
        } else if (json['data'] is Map && json['data']['list'] is List) {
          arr = json['data']['list'];
        } else if (json['list'] is List) {
          arr = json['list'];
        }
      } else {
        arr = json;
      }
      final out = <Map<String, String>>[];
      if (arr is List) {
        for (final it in arr) {
          if (it is Map) {
            final t = _s(it['title'] ?? it['name'] ?? it['query']);
            final u = _s(it['url'] ?? it['link'] ?? it['mobilUrl']);
            final d = _s(it['desc'] ?? it['description'] ?? it['excerpt']);
            if (t.isNotEmpty) out.add({'title': t, 'url': u, 'desc': d});
          } else if ('$it'.isNotEmpty) {
            out.add({'title': '$it', 'url': '', 'desc': ''});
          }
        }
      }
      if (!mounted) return;
      if (out.isEmpty) throw Exception('empty');
      setState(() {
        _list = out;
        _fallback = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _list = _demo.map((e) => {'title': e[0], 'url': e[1], 'desc': ''}).toList();
        _fallback = true;
        _error = '新闻接口请求失败，已展示内置示例数据';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '新闻资讯',
      subtitle: '知乎热榜 · 公开接口',
      actions: [
        GestureDetector(
          onTap: _load,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.refresh_rounded, size: 20, color: context.t2),
          ),
        ),
      ],
      children: [
        if (_loading) const LoadingState(text: '正在获取新闻…'),
        if (!_loading && _fallback)
          _FallbackBar(text: _error ?? '已降级', onRetry: _load),
        if (!_loading && _list.isEmpty)
          const EmptyState(text: '暂无新闻', icon: Icons.newspaper_rounded)
        else if (!_loading)
          ToolCard(
            title: '热点资讯',
            icon: Icons.newspaper_rounded,
            trailing: Text('${_list.length} 条',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: _list.asMap().entries.map((en) {
              final i = en.key;
              final e = en.value;
              return InkWell(
                onTap: () {
                  final u = e['url'] ?? '';
                  if (u.isNotEmpty) {
                    _launch(u);
                  } else {
                    copyText(e['title'] ?? '');
                  }
                },
                borderRadius: BorderRadius.circular(R.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: i < 3 ? C.rose : C.brand)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title'] ?? '',
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    fontWeight: FontWeight.w700,
                                    color: context.t1)),
                            if ((e['desc'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(e['desc']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Ty.small.copyWith(color: context.t3)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: context.t3),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 7. 汇率查询
/// 数据源：https://open.er-api.com/v6/latest/CNY
///        （exchangerate-api 免 Key 公开端点；失败再试 v4 端点）
/// 失败降级：内置常用汇率表
/// ═══════════════════════════════════════════════════════════════
class ForexTool extends StatefulWidget {
  const ForexTool({super.key});

  @override
  State<ForexTool> createState() => _ForexToolState();
}

class _ForexToolState extends State<ForexTool> {
  bool _loading = true;
  bool _fallback = false;
  String? _error;
  String _base = 'CNY';
  String _update = '';
  List<Map<String, String>> _list = [];

  /// 常见货币中文名
  static const _names = <String, String>{
    'USD': '美元', 'EUR': '欧元', 'GBP': '英镑', 'JPY': '日元',
    'HKD': '港币', 'MOP': '澳门元', 'TWD': '新台币', 'KRW': '韩元',
    'AUD': '澳元', 'CAD': '加元', 'CHF': '瑞士法郎', 'SGD': '新加坡元',
    'THB': '泰铢', 'MYR': '马来西亚林吉特', 'RUB': '卢布', 'INR': '印度卢比',
    'NZD': '新西兰元', 'AED': '迪拉姆', 'PHP': '菲律宾比索', 'VND': '越南盾',
  };

  /// 内置降级汇率（1 CNY 兑外币，示例值）
  static const _demoRates = <String, double>{
    'USD': 0.1415, 'EUR': 0.1298, 'GBP': 0.1102, 'JPY': 21.05,
    'HKD': 1.1015, 'MOP': 1.1345, 'TWD': 4.532, 'KRW': 191.3,
    'AUD': 0.2156, 'CAD': 0.1938, 'CHF': 0.1256, 'SGD': 0.1902,
    'THB': 4.882, 'MYR': 0.6285, 'RUB': 13.28, 'INR': 11.86,
    'NZD': 0.2338, 'AED': 0.5195, 'PHP': 8.086, 'VND': 3572.0,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // 两个公开端点依次尝试
    for (final url in [
      'https://open.er-api.com/v6/latest/$_base',
      'https://api.exchangerate-api.com/v4/latest/$_base',
    ]) {
      try {
        final json = await _httpJson(url);
        Map? rates;
        if (json is Map) {
          if (json['rates'] is Map) {
            rates = json['rates'] as Map;
          } else if (json['conversion_rates'] is Map) {
            rates = json['conversion_rates'] as Map;
          }
        }
        if (rates == null || rates.isEmpty) throw Exception('no rates');
        final out = <Map<String, String>>[];
        for (final code in _names.keys) {
          final v = rates[code];
          if (v == null) continue;
          final d = double.tryParse('$v');
          out.add({
            'code': code,
            'name': _names[code] ?? code,
            'rate': d == null
                ? '$v'
                : (d >= 100 ? d.toStringAsFixed(2) : d.toStringAsFixed(4)),
            'reverse': (d == null || d == 0)
                ? '—'
                : (1 / d).toStringAsFixed(4),
          });
        }
        if (out.isEmpty) throw Exception('empty');
        if (!mounted) return;
        setState(() {
          _list = out;
          _fallback = false;
          _loading = false;
          _update = _s((json as Map)['time_last_update_utc'] ??
              json['date'] ??
              '');
        });
        return;
      } catch (_) {
        // 端点失败，继续尝试下一个
      }
    }
    // 全部失败 → 内置降级
    if (!mounted) return;
    setState(() {
      _list = _demoRates.entries
          .map((e) => {
                'code': e.key,
                'name': _names[e.key] ?? e.key,
                'rate': e.value >= 100
                    ? e.value.toStringAsFixed(2)
                    : e.value.toStringAsFixed(4),
                'reverse': (1 / e.value).toStringAsFixed(4),
              })
          .toList();
      _fallback = true;
      _error = '汇率接口请求失败，已展示内置参考汇率';
      _loading = false;
    });
  }

  /// 互换基准货币（仅支持内置常见币种）
  void _switchBase(String b) {
    if (_base == b) return;
    setState(() => _base = b);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '汇率查询',
      subtitle: '基准货币 $_base · 公开汇率接口',
      actions: [
        GestureDetector(
          onTap: _load,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.refresh_rounded, size: 20, color: context.t2),
          ),
        ),
      ],
      children: [
        ToolCard(
          title: '基准货币',
          icon: Icons.currency_exchange_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['CNY', 'USD', 'EUR', 'JPY', 'HKD']
                  .map((b) => GestureDetector(
                        onTap: () => _switchBase(b),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: _base == b
                                ? C.brand
                                : C.brand.withAlpha(context.isDark ? 26 : 14),
                            borderRadius: BorderRadius.circular(R.full),
                          ),
                          child: Text('1 $b',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      _base == b ? Colors.white : C.brand)),
                        ),
                      ))
                  .toList(),
            ),
            if (_update.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('更新时间：$_update',
                  style: Ty.tiny.copyWith(color: context.t3)),
            ],
          ],
        ),
        if (_loading) const LoadingState(text: '正在获取汇率…'),
        if (!_loading && _fallback)
          _FallbackBar(text: _error ?? '已降级', onRetry: _load),
        if (!_loading && _list.isEmpty)
          const EmptyState(text: '暂无汇率数据', icon: Icons.currency_exchange_rounded)
        else if (!_loading)
          ToolCard(
            title: '1 $_base 可兑换',
            icon: Icons.table_chart_rounded,
            trailing: Text('${_list.length} 种',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: [
              _forexHeader(context),
              ..._list.map((e) => _forexRow(context, e)),
            ],
          ),
      ],
    );
  }

  Widget _forexHeader(BuildContext context) {
    final st = TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w800, color: context.t3);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('货币', style: st)),
          Expanded(flex: 3, child: Text('汇率', style: st, textAlign: TextAlign.right)),
          Expanded(
              flex: 4,
              child: Text('反向(1外币≈)', style: st, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _forexRow(BuildContext context, Map<String, String> e) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: context.isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(6),
              width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(e['code'] ?? '',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: C.brand)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(e['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.t3)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(e['rate'] ?? '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.t1)),
          ),
          Expanded(
            flex: 4,
            child: Text('${e['reverse']} ${e['code']}',
                textAlign: TextAlign.right,
                style: Ty.small.copyWith(color: context.t2)),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 8. 免费小说
/// 数据源：后端 /api/softlib/jzs/search?kw=书名 聚合搜索；
///        同时内置书单（含章节列表）作为降级与演示。
/// 说明：api.teamcat.cc 等第三方小说源稳定性差且存在版权风险，
///      故 App 内只做「书目浏览 + 章节列表 UI」，
///      正文阅读引导至合法阅读平台。
/// ═══════════════════════════════════════════════════════════════
class NovelTool extends StatefulWidget {
  const NovelTool({super.key});

  @override
  State<NovelTool> createState() => _NovelToolState();
}

class _NovelToolState extends State<NovelTool> {
  final _kwCtrl = TextEditingController();
  bool _loading = false;
  bool _fallback = false;
  String? _error;
  List<Map<String, String>> _list = [];

  /// 内置书单（降级 + 演示）
  static const _demo = <Map<String, String>>[
    {'title': '三体', 'author': '刘慈欣', 'cat': '科幻', 'desc': '地球文明与三体文明的史诗碰撞。'},
    {'title': '活着', 'author': '余华', 'cat': '文学', 'desc': '一个人和他命运之间的友情。'},
    {'title': '平凡的世界', 'author': '路遥', 'cat': '文学', 'desc': '普通人在大时代中的奋斗。'},
    {'title': '明朝那些事儿', 'author': '当年明月', 'cat': '历史', 'desc': '用通俗笔法讲述明朝三百年。'},
    {'title': '斗破苍穹', 'author': '天蚕土豆', 'cat': '玄幻', 'desc': '三十年河东，三十年河西。'},
    {'title': '盗墓笔记', 'author': '南派三叔', 'cat': '悬疑', 'desc': '长白山下的惊天秘密。'},
    {'title': '鬼吹灯', 'author': '天下霸唱', 'cat': '悬疑', 'desc': '摸金校尉的传奇探险。'},
    {'title': '庆余年', 'author': '猫腻', 'cat': '历史', 'desc': '少年范闲的庙堂与江湖。'},
    {'title': '雪中悍刀行', 'author': '烽火戏诸侯', 'cat': '武侠', 'desc': '江湖是一张珠帘。'},
    {'title': '琅琊榜', 'author': '海宴', 'cat': '历史', 'desc': '麒麟才子，得之可得天下。'},
    {'title': '诛仙', 'author': '萧鼎', 'cat': '仙侠', 'desc': '天地不仁，以万物为刍狗。'},
    {'title': '围城', 'author': '钱锺书', 'cat': '文学', 'desc': '婚姻是一座围城。'},
  ];

  @override
  void dispose() {
    _kwCtrl.dispose();
    super.dispose();
  }

  Future<void> _search([String? kw]) async {
    final q = (kw ?? _kwCtrl.text).trim();
    _kwCtrl.text = q;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() {
          _list = List<Map<String, String>>.from(_demo);
          _fallback = true;
          _error = '未输入关键词，展示内置推荐书单';
          _loading = false;
        });
        return;
      }
      final r = await _dio.get('/api/softlib/jzs/search',
          queryParameters: {'kw': q});
      final data = r.data;
      final raw = (data is Map && data['data'] is Map)
          ? data['data']['list']
          : null;
      final out = <Map<String, String>>[];
      if (raw is List) {
        for (final it in raw) {
          if (it is Map) {
            final t = _s(it['title'] ?? it['name']);
            if (t.isNotEmpty) {
              out.add({
                'title': t,
                'author': _s(it['author'], '佚名'),
                'cat': _s(it['cat'] ?? it['category'], '小说'),
                'desc': _s(it['desc'] ?? it['subtitle']),
              });
            }
          }
        }
      }
      if (!mounted) return;
      if (out.isEmpty) {
        setState(() {
          _list = List<Map<String, String>>.from(_demo);
          _fallback = true;
          _error = '未搜索到「$q」，展示内置书单';
          _loading = false;
        });
        return;
      }
      setState(() {
        _list = out;
        _fallback = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _list = List<Map<String, String>>.from(_demo);
        _fallback = true;
        _error = '小说接口请求失败，已展示内置书单';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '免费小说',
      subtitle: '书目浏览 · 章节列表',
      children: [
        ToolCard(
          title: '搜索书名',
          icon: Icons.menu_book_rounded,
          children: [
            ToolField(
              controller: _kwCtrl,
              hint: '输入书名关键词，如：三体',
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '搜索小说',
              icon: Icons.search_rounded,
              loading: _loading,
              onPressed: () => _search(),
            ),
          ],
        ),
        if (_loading) const LoadingState(text: '正在搜索小说…'),
        if (!_loading && _fallback)
          _FallbackBar(text: _error ?? '已降级', onRetry: () => _search()),
        if (!_loading && _list.isEmpty)
          const EmptyState(text: '暂无小说', icon: Icons.menu_book_rounded)
        else if (!_loading)
          ToolCard(
            title: '书单',
            icon: Icons.list_rounded,
            trailing: Text('${_list.length} 本',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: _list
                .map((n) => _novelRow(context, n))
                .toList(),
          ),
      ],
    );
  }

  Widget _novelRow(BuildContext context, Map<String, String> n) {
    return InkWell(
      onTap: () => Get.to(() => _NovelChaptersPage(novel: n)),
      borderRadius: BorderRadius.circular(R.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: Deco.brandGradient,
                borderRadius: BorderRadius.circular(R.xs),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: context.t1)),
                  const SizedBox(height: 3),
                  Text('${n['author']} · ${n['cat']}',
                      style: Ty.tiny.copyWith(color: context.t3)),
                  if ((n['desc'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n['desc']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ty.small.copyWith(color: context.t2)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: context.t3),
          ],
        ),
      ),
    );
  }
}

/// 章节列表页（小说详情）
class _NovelChaptersPage extends StatefulWidget {
  final Map<String, String> novel;
  const _NovelChaptersPage({required this.novel});

  @override
  State<_NovelChaptersPage> createState() => _NovelChaptersPageState();
}

class _NovelChaptersPageState extends State<_NovelChaptersPage> {
  bool _loading = true;
  String? _error;
  List<String> _chapters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 尝试从后端拉章节；失败则生成内置章节目录（保证有内容展示）
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/api/softlib/jzs/search', queryParameters: {
        'kw': widget.novel['title'] ?? '',
      });
      final data = r.data;
      final raw = (data is Map && data['data'] is Map)
          ? data['data']['list']
          : null;
      final out = <String>[];
      if (raw is List) {
        for (final it in raw) {
          final t = it is Map ? _s(it['title'] ?? it['name']) : '$it';
          if (t.isNotEmpty) out.add(t);
        }
      }
      if (!mounted) return;
      if (out.isEmpty) throw Exception('empty');
      setState(() {
        _chapters = out;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chapters = List.generate(30, (i) => '第 ${i + 1} 章　精彩章节');
        _error = '章节接口不可用，展示内置目录（正文请到合法平台阅读）';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: widget.novel['title'] ?? '小说',
      subtitle: '${widget.novel['author']} · ${widget.novel['cat']}',
      children: [
        if (_loading) const LoadingState(text: '加载章节…'),
        if (!_loading && _error != null) _FallbackBar(text: _error!),
        if (!_loading && _chapters.isEmpty)
          const EmptyState(text: '暂无章节', icon: Icons.menu_book_rounded)
        else if (!_loading)
          ToolCard(
            title: '章节目录',
            icon: Icons.format_list_numbered_rounded,
            trailing: Text('${_chapters.length} 章',
                style: Ty.tiny.copyWith(color: context.t3)),
            children: _chapters
                .map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(c,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13.5, color: context.t1)),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 17, color: context.t3),
                        ],
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 9. 小说下载
/// 数据说明：内置 TXT 书单（公有领域 / 示例），提供下载入口按钮。
///          链接统一走「复制链接 + 外部打开」双保险，失败不白屏。
/// ═══════════════════════════════════════════════════════════════
class NovelDlTool extends StatefulWidget {
  const NovelDlTool({super.key});

  @override
  State<NovelDlTool> createState() => _NovelDlToolState();
}

class _NovelDlToolState extends State<NovelDlTool> {
  /// 内置可下载书单（公版书 / 演示链接）
  static const _books = <Map<String, String>>[
    {
      'title': '红楼梦',
      'author': '曹雪芹',
      'size': '约 2.1 MB',
      'url': 'https://www.gutenberg.org/cache/epub/24264/pg24264.txt',
    },
    {
      'title': '西游记',
      'author': '吴承恩',
      'size': '约 1.8 MB',
      'url': 'https://www.gutenberg.org/cache/epub/23962/pg23962.txt',
    },
    {
      'title': '水浒传',
      'author': '施耐庵',
      'size': '约 1.6 MB',
      'url': 'https://www.gutenberg.org/cache/epub/23863/pg23863.txt',
    },
    {
      'title': '三国演义',
      'author': '罗贯中',
      'size': '约 1.5 MB',
      'url': 'https://www.gutenberg.org/cache/epub/23950/pg23950.txt',
    },
    {
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'size': '约 0.7 MB',
      'url': 'https://www.gutenberg.org/cache/epub/1342/pg1342.txt',
    },
    {
      'title': 'Moby Dick',
      'author': 'Herman Melville',
      'size': '约 1.2 MB',
      'url': 'https://www.gutenberg.org/cache/epub/2701/pg2701.txt',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '小说下载',
      subtitle: 'TXT 书单 · 公版资源',
      children: [
        _FallbackBar(
          text: '当前为内置公版书单（Project Gutenberg）。'
              '第三方小说站资源版权与稳定性不可控，故未接入。',
        ),
        ToolCard(
          title: '可下载书单',
          icon: Icons.download_rounded,
          trailing: Text('${_books.length} 本',
              style: Ty.tiny.copyWith(color: context.t3)),
          children: _books.map((b) => _bookRow(context, b)).toList(),
        ),
      ],
    );
  }

  Widget _bookRow(BuildContext context, Map<String, String> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withAlpha(10) : C.lbg2,
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: Deco.brandGradient,
              borderRadius: BorderRadius.circular(R.xs),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.t1)),
                const SizedBox(height: 3),
                Text('${b['author']} · ${b['size']}',
                    style: Ty.tiny.copyWith(color: context.t3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              SoftButton(
                label: '下载',
                icon: Icons.download_rounded,
                onPressed: () => _launch(b['url'] ?? ''),
              ),
              const SizedBox(width: 6),
              SoftButton(
                label: '复制',
                icon: Icons.link_rounded,
                color: C.mint,
                onPressed: () => copyText(b['url'] ?? ''),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
///  通用：随机图集外壳（壁纸/头像/表情包/美图 复用）
///
///  统一处理：随机取图 / 加载态 / 错误态（降级到 picsum）/ 网格展示 /
///  点击全屏预览（PhotoView）/ 复制直链。
///  每个子类只需提供 [nextUrl] 生成器与标题文案。
/// ═══════════════════════════════════════════════════════════════
class _ImageGridTool extends StatefulWidget {
  final String title;
  final String subtitle;
  final String fallbackNote;
  final int cols;
  final double aspect;
  final String Function(int index, int seed) nextUrl;
  final List<String> seeds;

  const _ImageGridTool({
    required this.title,
    required this.subtitle,
    required this.nextUrl,
    this.fallbackNote = '接口不可用时自动降级到 picsum.photos 随机图',
    this.cols = 2,
    this.aspect = 0.75,
    this.seeds = const ['风景', '城市', '夜空', '山水', '极简', '治愈'],
  });

  @override
  State<_ImageGridTool> createState() => _ImageGridToolState();
}

class _ImageGridToolState extends State<_ImageGridTool> {
  final _rand = Random();
  bool _loading = true;
  bool _fallback = false;
  String? _error;
  final List<String> _urls = [];

  @override
  void initState() {
    super.initState();
    _loadMore(first: true);
  }

  /// 生成一批图片链接，并用 HEAD 探活首个链接：
  /// 探活失败（接口挂了 / 超时）→ 走 picsum 降级，保证永远有图可看。
  Future<void> _loadMore({bool first = false}) async {
    if (first) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final out = <String>[];
      for (int i = 0; i < 12; i++) {
        final seed = _rand.nextInt(1 << 30);
        final u = widget.nextUrl(_urls.length + i, seed);
        if (u.trim().isEmpty) continue;
        out.add(u);
      }
      if (out.isEmpty) throw Exception('no image');
      // 探活：只探测首个链接，避免 12 次请求拖慢速度
      final ok = await _probe(out.first);
      if (!ok) throw Exception('probe failed');
      if (!mounted) return;
      setState(() {
        _urls.addAll(out);
        _fallback = false;
        _loading = false;
      });
    } catch (_) {
      // 降级：picsum 随机图（无需接口参数，极稳）
      if (!mounted) return;
      final base = _urls.length;
      final out = List.generate(
          12,
          (i) => 'https://picsum.photos/seed/fl${base + i}/800/1000');
      setState(() {
        _urls.addAll(out);
        _fallback = true;
        _error = '图片接口请求失败，已降级到 picsum.photos';
        _loading = false;
      });
    }
  }

  /// 探活图片链接（HEAD 请求，10 秒超时）。
  /// btstu / picsum 都会 302 跳转，Dio 默认跟随重定向即可判定可用性。
  Future<bool> _probe(String url) async {
    try {
      final r = await _dioRaw.head(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (c) => c != null && c < 400,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return r.statusCode == null || r.statusCode! < 400;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: widget.title,
      actions: [
        GestureDetector(
          onTap: () => _loadMore(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.refresh_rounded, size: 20, color: context.t2),
          ),
        ),
      ],
      children: [
        if (_fallback)
          _FallbackBar(text: _error ?? widget.fallbackNote, onRetry: () => _loadMore()),
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () => _loadMore(),
                child: Container(
                  margin: const EdgeInsets.only(right: 7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: C.brand,
                    borderRadius: BorderRadius.circular(R.full),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 3),
                      Text('再来一批',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              ...widget.seeds.map((s) => GestureDetector(
                    onTap: () {
                      copyText(s);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.brand.withAlpha(context.isDark ? 26 : 14),
                        borderRadius: BorderRadius.circular(R.full),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: C.brand)),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading && _urls.isEmpty) return const LoadingState(text: '加载中…');
    if (_urls.isEmpty) {
      return ErrorState(text: '加载失败', onRetry: () => _loadMore());
    }
    return GridView.builder(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 0, context.pagePadding, context.tabSpace + 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: widget.aspect,
      ),
      itemCount: _urls.length,
      itemBuilder: (_, i) {
        final u = _urls[i];
        return GestureDetector(
          onTap: () => Get.to(() => _ImageViewerPage(url: u)),
          onLongPress: () => copyText(u),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.md),
              border:
                  Border.all(color: C.stroke.withAlpha(50), width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetImage(url: u, fallbackIcon: Icons.image_outlined),
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: GestureDetector(
                    onTap: () => copyText(u),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.link_rounded,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 10. 壁纸大全
/// 数据源：https://api.btstu.cn/sjbz/api.php?format=images （302 跳转随机图）
/// 失败降级：picsum.photos 随机壁纸
/// ═══════════════════════════════════════════════════════════════
class WallpaperTool extends StatelessWidget {
  const WallpaperTool({super.key});

  @override
  Widget build(BuildContext context) {
    return _ImageGridTool(
      title: '壁纸大全',
      subtitle: '随机高清壁纸 · 点击全屏',
      cols: 2,
      aspect: 0.62,
      seeds: const ['随机', '风景', '动漫', '简约', '星空', '萌宠'],
      // btstu 返回随机图（302 重定向到真实图片，CachedNetworkImage 可直接加载）
      nextUrl: (i, seed) =>
          'https://api.btstu.cn/sjbz/api.php?format=images&lx=dongman&t=$seed',
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 11. 头像大全
/// 数据源：https://api.btstu.cn/sjtx/api.php （随机头像）
/// 失败降级：picsum.photos
/// ═══════════════════════════════════════════════════════════════
class AvatarTool extends StatelessWidget {
  const AvatarTool({super.key});

  @override
  Widget build(BuildContext context) {
    return _ImageGridTool(
      title: '头像大全',
      subtitle: '随机头像 · 点击放大保存',
      cols: 3,
      aspect: 1.0,
      seeds: const ['男生', '女生', '情侣', '动漫', '可爱', '简约'],
      nextUrl: (i, seed) => 'https://api.btstu.cn/sjtx/api.php?t=$seed',
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 12. 表情包大全
/// 数据源：公开表情包图源（btstu 随机图接口）
/// 失败降级：picsum.photos 随机图
/// ═══════════════════════════════════════════════════════════════
class MemeTool extends StatelessWidget {
  const MemeTool({super.key});

  @override
  Widget build(BuildContext context) {
    return _ImageGridTool(
      title: '表情包大全',
      subtitle: '沙雕表情包 · 长按复制链接',
      cols: 3,
      aspect: 1.0,
      seeds: const ['沙雕', '搞笑', '可爱', '熊猫头', '猫猫', '无语'],
      nextUrl: (i, seed) =>
          'https://api.btstu.cn/sjbz/api.php?format=images&lx=meizi&t=$seed',
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 13. 随机美图
/// 说明：原需求指向的视频类接口（api.yujn.cn 等）多已失效且内容不可控，
///      这里统一做「随机图片浏览」，数据源 btstu 随机图；
///      若后续接入视频接口，可在本类中替换 nextUrl 并改用 video_view。
/// 失败降级：picsum.photos
/// ═══════════════════════════════════════════════════════════════
class BeautyTool extends StatelessWidget {
  const BeautyTool({super.key});

  @override
  Widget build(BuildContext context) {
    return _ImageGridTool(
      title: '随机美图',
      subtitle: '随机图片浏览 · 接口失效自动降级',
      cols: 2,
      aspect: 0.72,
      fallbackNote: '图片接口不可用，已降级到 picsum.photos（视频接口多为失效状态）',
      seeds: const ['随机', '清新', '唯美', '自然', '都市', '旅行'],
      nextUrl: (i, seed) =>
          'https://api.btstu.cn/sjbz/api.php?format=images&t=$seed',
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 14. 精美图片
/// 数据源：https://picsum.photos （Lorem Picsum 随机美图，最稳）
/// 失败降级：内置占位图（接口不可用时仍显示占位卡片，不白屏）
/// ═══════════════════════════════════════════════════════════════
class PicsumTool extends StatelessWidget {
  const PicsumTool({super.key});

  @override
  Widget build(BuildContext context) {
    return _ImageGridTool(
      title: '精美图片',
      subtitle: 'Lorem Picsum 随机美图',
      cols: 2,
      aspect: 0.75,
      fallbackNote: 'picsum 请求异常时展示占位卡片，请检查网络后重试',
      seeds: const ['随机', '自然', '建筑', '人物', 'fashion', 'forest'],
      nextUrl: (i, seed) => 'https://picsum.photos/seed/p$seed/800/1000',
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// 15. 短视频去水印
/// 实现：输入抖音/快手分享链接 → 调用后端解析接口
///      （/api/softlib/parse，见 backend/app/parse_api.php）。
/// 解析成功：展示封面/视频预览 + 复制直链（可长按复制 / 外部打开）。
/// 解析失败：友好降级提示「解析失败/请稍后重试」，绝不留白。
///
/// ★ 说明：第三方免 Key 去水印接口（api.xxx）普遍不稳定且频繁失效，
///   因此这里只对接自家后端；后端未配置解析器时统一走降级提示。
/// ═══════════════════════════════════════════════════════════════
class NoWatermarkTool extends StatefulWidget {
  /// 模式：sniff(资源嗅探) / video(短视频去水印) / image(图集) / douyin(抖音) / vip(VIP解析)
  final String mode;
  const NoWatermarkTool({super.key, this.mode = 'video'});

  @override
  State<NoWatermarkTool> createState() => _NoWatermarkToolState();
}

class _NoWatermarkToolState extends State<NoWatermarkTool> {
  final _linkCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _cover;
  String? _video;
  String? _title;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  /// 从分享文本中提取真正的 URL（抖音分享文案常夹带一段文字）
  String _extractUrl(String raw) {
    final m = RegExp(r'https?://[^\s，,、]+').firstMatch(raw);
    return m?.group(0) ?? raw.trim();
  }

  Future<void> _parse() async {
    final raw = _linkCtrl.text.trim();
    if (raw.isEmpty) {
      ToastUtil.info('请粘贴分享链接');
      return;
    }
    final url = _extractUrl(raw);
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _cover = null;
      _video = null;
      _title = null;
    });
    try {
      // 后端解析入口（可能不存在或未配置 → 走 catch 降级）
      final r = await _dio.post('/api/softlib/parse', data: {'url': url});
      final body = r.data;
      Map? d;
      if (body is Map) {
        if (body['data'] is Map) {
          d = body['data'] as Map;
        } else if (body['code'] == 1 || body['ok'] == true) {
          d = body;
        }
      }
      final video = _s(d?['video'] ?? d?['url'] ?? d?['play']);
      final cover = _s(d?['cover'] ?? d?['image'] ?? d?['poster']);
      final title = _s(d?['title'] ?? d?['desc']);
      if (video.isEmpty && cover.isEmpty) {
        throw Exception('未解析到内容');
      }
      if (!mounted) return;
      setState(() {
        _video = video.isEmpty ? null : video;
        _cover = cover.isEmpty ? null : cover;
        _title = title.isEmpty ? null : title;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '解析失败，请稍后重试。若多次失败，可复制原链接到浏览器打开。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '短视频去水印',
      subtitle: '支持抖音 / 快手分享链接',
      children: [
        ToolCard(
          title: '粘贴分享链接',
          icon: Icons.link_rounded,
          children: [
            ToolField(
              controller: _linkCtrl,
              hint: '粘贴 App 分享出来的整段文案即可，自动识别链接',
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ToolButton(
              label: '开始解析',
              icon: Icons.auto_fix_high_rounded,
              loading: _loading,
              onPressed: _parse,
            ),
            const SizedBox(height: 8),
            Text('提示：解析服务依赖后端能力，免费接口常失效；'
                '若解析失败请稍后再试或复制原链接手动处理。',
                style: Ty.tiny.copyWith(color: context.t3)),
          ],
        ),
        if (_loading) const LoadingState(text: '正在解析视频…'),
        if (!_loading && _error != null)
          ToolCard(
            title: '解析失败',
            icon: Icons.error_outline_rounded,
            children: [
              _FallbackBar(text: _error!),
              ToolButton(
                label: '重试',
                icon: Icons.refresh_rounded,
                loading: false,
                onPressed: _parse,
              ),
            ],
          ),
        if (!_loading && (_video != null || _cover != null))
          ToolCard(
            title: '解析结果',
            icon: Icons.check_circle_rounded,
            children: [
              if (_title != null) ...[
                Text(_title!,
                    style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: context.t1)),
                const SizedBox(height: 10),
              ],
              if (_cover != null || _video != null) ...[
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.md),
                      border:
                          Border.all(color: C.stroke.withAlpha(50), width: 0.8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _NetImage(
                      url: (_cover ?? _video)!,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.movie_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_video != null) ...[
                ToolResult(title: '视频直链', content: _video!),
                const SizedBox(height: 8),
                ToolButton(
                  label: '复制视频直链',
                  icon: Icons.copy_rounded,
                  onPressed: () => copyText(_video!),
                ),
                const SizedBox(height: 8),
                ToolButton(
                  label: '外部打开直链',
                  icon: Icons.open_in_new_rounded,
                  color: C.mint,
                  onPressed: () => _launch(_video!),
                ),
              ],
              if (_cover != null) ...[
                const SizedBox(height: 8),
                ToolButton(
                  label: '复制封面直链',
                  icon: Icons.image_rounded,
                  color: C.violet,
                  onPressed: () => copyText(_cover!),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
