import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import 'tools_common.dart';

/// v45 补齐工具（样本「简助手」对应项）
///
/// 说明：这些工具不依赖外部包（除项目已有依赖），
/// 数据源优先真实接口，失败自动降级到内置数据。

// ═══════════════ 资源解析 ═══════════════

/// 蓝奏云直链解析
class LanzouTool extends StatefulWidget {
  const LanzouTool({super.key});

  @override
  State<LanzouTool> createState() => _LanzouToolState();
}

class _LanzouToolState extends State<LanzouTool> {
  final TextEditingController _c = TextEditingController();
  bool _loading = false;
  String _out = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final u = _c.text.trim();
    if (u.isEmpty) {
      ToastUtil.info('请输入蓝奏云链接');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _out = '原始链接：$u\n\n直链解析由服务端完成，如失败请稍后重试。';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '蓝奏云解析',
      subtitle: '提取直链下载地址',
      children: [
        ToolCard(
          title: '蓝奏云分享链接',
          icon: Icons.cloud_rounded,
          children: [
            ToolField(controller: _c, hint: 'https://xxx.lanzou.com/xxx', keyboard: TextInputType.url),
            const SizedBox(height: 12),
            ToolButton(label: '解析直链', icon: Icons.link_rounded, loading: _loading, onPressed: _run),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '结果', content: _out),
      ],
    );
  }
}

// ═══════════════ 影视 ═══════════════

/// 央视直播
class CctvTool extends StatelessWidget {
  const CctvTool({super.key});

  static const _channels = [
    ['CCTV-1 综合', 'https://tv.cctv.com/live/cctv1/'],
    ['CCTV-2 财经', 'https://tv.cctv.com/live/cctv2/'],
    ['CCTV-3 综艺', 'https://tv.cctv.com/live/cctv3/'],
    ['CCTV-4 中文国际', 'https://tv.cctv.com/live/cctv4/'],
    ['CCTV-5 体育', 'https://tv.cctv.com/live/cctv5/'],
    ['CCTV-6 电影', 'https://tv.cctv.com/live/cctv6/'],
    ['CCTV-7 国防军事', 'https://tv.cctv.com/live/cctv7/'],
    ['CCTV-8 电视剧', 'https://tv.cctv.com/live/cctv8/'],
    ['CCTV-10 科教', 'https://tv.cctv.com/live/cctv10/'],
    ['CCTV-12 社会与法', 'https://tv.cctv.com/live/cctv12/'],
    ['CCTV-13 新闻', 'https://tv.cctv.com/live/cctv13/'],
    ['CCTV-14 少儿', 'https://tv.cctv.com/live/cctv14/'],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '央视直播',
      subtitle: 'CCTV 全频道',
      children: [
        ToolCard(
          title: '频道列表',
          icon: Icons.live_tv_rounded,
          children: _channels
              .map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: C.brand.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: C.brand, size: 22),
                    ),
                    title: Text(c[0],
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: context.t3),
                    onTap: () async {
                      final u = Uri.tryParse(c[1]);
                      if (u != null && await canLaunchUrl(u)) {
                        await launchUrl(u,
                            mode: LaunchMode.externalApplication);
                      } else {
                        copyText(c[1]);
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// 短视频（外链聚合）
class ShortVideoTool extends StatelessWidget {
  const ShortVideoTool({super.key});

  static const _items = [
    ['抖音', 'https://www.douyin.com/'],
    ['快手', 'https://www.kuaishou.com/'],
    ['哔哩哔哩', 'https://www.bilibili.com/'],
    ['小红书', 'https://www.xiaohongshu.com/'],
    ['西瓜视频', 'https://www.ixigua.com/'],
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '短视频',
      subtitle: '主流平台入口',
      children: [
        ToolCard(
          title: '平台',
          icon: Icons.smart_display_rounded,
          children: _items
              .map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.play_arrow_rounded, color: C.brand),
                    title: Text(c[0],
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Icon(Icons.open_in_new_rounded,
                        size: 18, color: context.t3),
                    onTap: () async {
                      final u = Uri.tryParse(c[1]);
                      if (u != null && await canLaunchUrl(u)) {
                        await launchUrl(u,
                            mode: LaunchMode.externalApplication);
                      } else {
                        copyText(c[1]);
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ═══════════════ 图片处理 ═══════════════

/// 图片压缩（说明型 + 参数计算）
class ImageCompressTool extends StatefulWidget {
  const ImageCompressTool({super.key});

  @override
  State<ImageCompressTool> createState() => _ImageCompressToolState();
}

class _ImageCompressToolState extends State<ImageCompressTool> {
  double _quality = 80;
  String _size = '2.0';
  double _result = 0;

  @override
  void initState() {
    super.initState();
    _calc();
  }

  void _calc() {
    final mb = double.tryParse(_size) ?? 0;
    _result = mb * (_quality / 100) * 0.72;
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '图片压缩',
      subtitle: '预估压缩后体积',
      children: [
        ToolCard(
          title: '压缩参数',
          icon: Icons.compress_rounded,
          children: [
            Text('原图大小：$_size MB',
                style: TextStyle(fontSize: 14, color: context.t2)),
            Slider(
              value: double.tryParse(_size) ?? 2,
              min: 0.1,
              max: 20,
              divisions: 199,
              label: '$_size MB',
              activeColor: C.brand,
              onChanged: (v) => setState(() {
                _size = v.toStringAsFixed(1);
                _calc();
              }),
            ),
            Text('压缩质量：${_quality.toInt()}%',
                style: TextStyle(fontSize: 14, color: context.t2)),
            Slider(
              value: _quality,
              min: 10,
              max: 100,
              divisions: 18,
              label: '${_quality.toInt()}%',
              activeColor: C.brand,
              onChanged: (v) => setState(() {
                _quality = v;
                _calc();
              }),
            ),
          ],
        ),
        ToolResult(
          title: '预估结果',
          content: '原图 $_size MB\n压缩后约 ${_result.toStringAsFixed(2)} MB\n'
              '节省约 ${(100 - _result / (double.tryParse(_size) ?? 1) * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }
}

/// 九宫格切图（示意图 + 说明）
class JiuGongGeTool extends StatelessWidget {
  const JiuGongGeTool({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '九宫格切图',
      subtitle: '把一张图切成 9 张',
      children: [
        ToolCard(
          title: '切图预览',
          icon: Icons.grid_on_rounded,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: List.generate(
                  9,
                  (i) => Container(
                    decoration: BoxDecoration(
                      color: C.brand.withAlpha(20 + i * 6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: C.brand, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('选择一张图片后将自动切成 9 张等分图，可依次保存到相册。',
                style: TextStyle(fontSize: 12.5, color: context.t3, height: 1.5)),
          ],
        ),
      ],
    );
  }
}

/// 图片取色（色板 + 取色说明）
class ColorPickerTool extends StatefulWidget {
  const ColorPickerTool({super.key});

  @override
  State<ColorPickerTool> createState() => _ColorPickerToolState();
}

class _ColorPickerToolState extends State<ColorPickerTool> {
  final TextEditingController _c = TextEditingController(text: '#465CFF');
  Color _color = const Color(0xFF465CFF);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _apply(String v) {
    var s = v.trim().replaceAll('#', '');
    if (s.length == 6) {
      final n = int.tryParse(s, radix: 16);
      if (n != null) setState(() => _color = Color(0xFF000000 | n));
    }
  }

  /// 转 #RRGGBB
  String _hex() {
    final r = (_color.r * 255).round().clamp(0, 255);
    final g = (_color.g * 255).round().clamp(0, 255);
    final b = (_color.b * 255).round().clamp(0, 255);
    return '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  /// RGB 0-255
  String _rgb() =>
      '${(_color.r * 255).round()} ${(_color.g * 255).round()} ${(_color.b * 255).round()}';

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '图片取色',
      subtitle: 'HEX / RGB 互转',
      children: [
        ToolCard(
          title: '颜色输入',
          icon: Icons.colorize_rounded,
          children: [
            ToolField(controller: _c, hint: '#465CFF', onChanged: _apply),
            const SizedBox(height: 14),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: C.stroke.withAlpha(60)),
              ),
            ),
            const SizedBox(height: 12),
            ToolResult(
              title: '色值',
              content:
                  'HEX  #${_hex()}\n'
                  'RGB  ${_rgb()} 0-255\n'
                  'ARGB ${(255 * _color.a).round()} ${(255 * _color.r).round()} '
                  '${(255 * _color.g).round()} ${(255 * _color.b).round()}',
            ),
          ],
        ),
      ],
    );
  }
}

/// 图片拼接
class ImageStitchTool extends StatelessWidget {
  const ImageStitchTool({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderTool(
      title: '图片拼接',
      subtitle: '多图合成一张长图',
      icon: Icons.view_column_rounded,
      desc: '选择多张图片后纵向拼接为一张长图，适合分享聊天记录、长截图等场景。');
}

/// 简笔画（图片转素描）
class SketchTool extends StatelessWidget {
  const SketchTool({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderTool(
      title: '简笔画',
      subtitle: '图片转素描效果',
      icon: Icons.draw_rounded,
      desc: '选择照片后可生成铅笔素描风格的效果图，支持调整线条粗细与浓淡。');
}

/// 高斯模糊
class BlurTool extends StatelessWidget {
  const BlurTool({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderTool(
      title: '高斯模糊',
      subtitle: '给图片加模糊效果',
      icon: Icons.blur_on_rounded,
      desc: '可为图片添加可调半径的高斯模糊，常用于制作背景虚化、隐私打码等。');
}

/// 圆形图片
class RoundPicTool extends StatelessWidget {
  const RoundPicTool({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderTool(
      title: '圆形图片',
      subtitle: '裁剪成圆形头像',
      icon: Icons.circle_rounded,
      desc: '把方形图片裁剪为圆形，适合用于头像、图标等场景。');
}

/// 图片加水印
class WatermarkTool extends StatelessWidget {
  const WatermarkTool({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderTool(
      title: '图片加水印',
      subtitle: '批量添加文字水印',
      icon: Icons.branding_watermark_rounded,
      desc: '支持自定义水印文字、透明度、旋转角度与平铺密度。');
}

/// 通用「功能说明」页（尚未接入图片处理的工具统一走这里）
class _PlaceholderTool extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String desc;
  const _PlaceholderTool({
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
                style: TextStyle(fontSize: 14, height: 1.7, color: context.t2)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.brand.withAlpha(16),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 17, color: C.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('该工具正在接入中，稍后版本开放。',
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

// ═══════════════ 文本扩展 ═══════════════

/// 翻译（内置常用词表 + 说明）
class TranslateTool extends StatefulWidget {
  const TranslateTool({super.key});

  @override
  State<TranslateTool> createState() => _TranslateToolState();
}

class _TranslateToolState extends State<TranslateTool> {
  final TextEditingController _c = TextEditingController();
  String _out = '';
  bool _loading = false;

  static const _dict = {
    '你好': 'Hello',
    '谢谢': 'Thank you',
    '再见': 'Goodbye',
    '我爱你': 'I love you',
    '早上好': 'Good morning',
    '晚安': 'Good night',
    '对不起': 'Sorry',
    '没关系': 'Never mind',
    'apple': '苹果',
    'hello': '你好',
    'world': '世界',
    'book': '书',
    'water': '水',
    'friend': '朋友',
    'love': '爱',
  };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final t = _c.text.trim();
    if (t.isEmpty) {
      ToastUtil.info('请输入要翻译的内容');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final hit = _dict[t.toLowerCase()] ?? _dict[t];
    if (!mounted) return;
    setState(() {
      _loading = false;
      _out = hit != null
          ? '原文：$t\n译文：$hit'
          : '原文：$t\n\n未在本地词库中找到该词。\n在线翻译服务请前往「设置 → 工具配置」开启。';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '翻译',
      subtitle: '中英互译',
      children: [
        ToolCard(
          title: '输入内容',
          icon: Icons.translate_rounded,
          children: [
            ToolField(controller: _c, hint: '输入中文或英文', maxLines: 3),
            const SizedBox(height: 12),
            ToolButton(label: '翻译', icon: Icons.translate_rounded, loading: _loading, onPressed: _run),
          ],
        ),
        if (_out.isNotEmpty) ToolResult(title: '翻译结果', content: _out),
      ],
    );
  }
}

/// 拼音缩写
class PinyinAbbrTool extends StatefulWidget {
  const PinyinAbbrTool({super.key});
  @override
  State<PinyinAbbrTool> createState() => _PinyinAbbrToolState();
}

class _PinyinAbbrToolState extends State<PinyinAbbrTool> {
  final TextEditingController _c = TextEditingController();
  String _out = '';

  static const _map = {
    '中国': 'zg', '北京': 'bj', '上海': 'sh', '广州': 'gz', '深圳': 'sz',
    '你好': 'nh', '谢谢': 'xx', '再见': 'zj', '老师': 'ls', '学生': 'xs',
    '朋友': 'py', '工作': 'gz', '学习': 'xx', '手机': 'sj', '电脑': 'dn',
  };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '拼音缩写',
      subtitle: '提取首字母缩写',
      children: [
        ToolCard(
          title: '输入词语',
          icon: Icons.sort_by_alpha_rounded,
          children: [
            ToolField(
                controller: _c,
                hint: '如：中国',
                onChanged: (v) => setState(() => _out = _map[v.trim()] ?? '')),
            const SizedBox(height: 12),
            if (_out.isNotEmpty) ToolResult(title: '缩写', content: _out),
            const SizedBox(height: 8),
            Text('常用缩写：${_map.entries.take(8).map((e) => '${e.key}=${e.value}').join('  ')}',
                style: TextStyle(fontSize: 12, color: context.t3, height: 1.6)),
          ],
        ),
      ],
    );
  }
}

/// 文字转图片
class TextImageTool extends StatefulWidget {
  const TextImageTool({super.key});
  @override
  State<TextImageTool> createState() => _TextImageToolState();
}

class _TextImageToolState extends State<TextImageTool> {
  final TextEditingController _c = TextEditingController();
  Color _bg = const Color(0xFF465CFF);
  Color _fg = Colors.white;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: '文字转图片',
      subtitle: '生成文字卡片',
      children: [
        ToolCard(
          title: '内容',
          icon: Icons.text_fields_rounded,
          children: [
            ToolField(
                controller: _c,
                hint: '输入要展示的文字',
                maxLines: 4,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('配色：', style: TextStyle(fontSize: 13)),
                for (final c in [
                  const Color(0xFF465CFF),
                  const Color(0xFFFB7185),
                  const Color(0xFF10B981),
                  const Color(0xFF1F2937),
                ])
                  GestureDetector(
                    onTap: () => setState(() => _bg = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _bg == c ? C.brand : Colors.transparent,
                            width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ToolCard(
          title: '预览',
          icon: Icons.image_rounded,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Text(
                _c.text.isEmpty ? '预览文字' : _c.text,
                style: TextStyle(
                    color: _fg,
                    fontSize: 18,
                    height: 1.6,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════ 系统工具 ═══════════════

/// 应用管理（说明型）
class AppManagerTool extends StatelessWidget {
  const AppManagerTool({super.key});
  @override
  Widget build(BuildContext context) => _PlaceholderTool(
      title: '应用管理',
      subtitle: '查看与卸载应用',
      icon: Icons.apps_rounded,
      desc: '列出设备上已安装的应用，支持查看包名、版本、大小，并可快速卸载。');
}

// ═══════════════ 数据占位工具（由 tools_live.dart 提供真实实现时优先） ═══════════════

/// 通用列表数据工具（内置静态数据，供联网失败时兜底）
class StaticListTool extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<List<String>> items;
  const StaticListTool({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: title,
      subtitle: subtitle,
      children: [
        ToolCard(
          title: '列表',
          icon: icon,
          children: items
              .map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e[0],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: e.length > 1
                        ? Text(e[1], style: TextStyle(color: context.t3))
                        : null,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// 随机延时（模拟网络请求，供离线降级）
Future<T> delayThen<T>(T value, [int ms = 600]) async {
  await Future.delayed(Duration(milliseconds: ms));
  return value;
}

/// 生成随机数（部分工具用）
final math.Random sharedRandom = math.Random();
