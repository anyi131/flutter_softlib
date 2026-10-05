import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/jump_util.dart';
import '../../utils/toast_util.dart';
import 'tool_router.dart';

/// 工具页布局
enum ToolLayout { circle, square, flow }

extension ToolLayoutX on ToolLayout {
  String get label => switch (this) {
        ToolLayout.circle => '圆形宫格',
        ToolLayout.square => '方形宫格',
        ToolLayout.flow => '流式列表',
      };

  IconData get icon => switch (this) {
        ToolLayout.circle => Icons.circle_outlined,
        ToolLayout.square => Icons.grid_view_rounded,
        ToolLayout.flow => Icons.view_stream_rounded,
      };

  static ToolLayout parse(String s) => switch (s) {
        'circle' => ToolLayout.circle,
        'flow' => ToolLayout.flow,
        _ => ToolLayout.square,
      };
}

/// 工具图标映射（route -> IconData）
class ToolIcons {
  static IconData of(String route) {
    switch (route) {
      case 'calculator':
        return Icons.calculate_rounded;
      case 'qrcode':
        return Icons.qr_code_2_rounded;
      case 'compass':
        return Icons.explore_rounded;
      case 'level':
        return Icons.straighten_rounded;
      case 'stopwatch':
        return Icons.timer_rounded;
      case 'countdown':
        return Icons.hourglass_bottom_rounded;
      case 'decibel':
        return Icons.graphic_eq_rounded;
      case 'protractor':
        return Icons.architecture_rounded;
      case 'sniff':
        return Icons.radar_rounded;
      case 'nowatermark':
      case 'nowatermark_img':
        return Icons.auto_fix_high_rounded;
      case 'douyin':
        return Icons.music_note_rounded;
      case 'videoparse':
        return Icons.play_circle_fill_rounded;
      case 'musicparse':
        return Icons.headphones_rounded;
      case 'lanzou':
        return Icons.cloud_download_rounded;
      case 'wallpaper':
        return Icons.wallpaper_rounded;
      case 'avatar':
        return Icons.account_circle_rounded;
      case 'meme':
        return Icons.emoji_emotions_rounded;
      case 'beauty':
        return Icons.videocam_rounded;
      case 'herogallery':
        return Icons.sports_martial_arts_rounded;
      case 'picsum':
        return Icons.photo_library_rounded;
      case 'movie':
      case 'moviesearch':
        return Icons.movie_rounded;
      case 'music':
        return Icons.library_music_rounded;
      case 'cctv':
        return Icons.live_tv_rounded;
      case 'shortvideo':
        return Icons.smart_display_rounded;
      case 'comic':
        return Icons.menu_book_rounded;
      case 'novel':
      case 'noveldl':
        return Icons.auto_stories_rounded;
      case 'compress':
        return Icons.compress_rounded;
      case 'jiugongge':
        return Icons.grid_on_rounded;
      case 'colorpick':
        return Icons.colorize_rounded;
      case 'imagestitch':
        return Icons.view_column_rounded;
      case 'sketch':
        return Icons.draw_rounded;
      case 'blur':
        return Icons.blur_on_rounded;
      case 'roundpic':
        return Icons.circle_rounded;
      case 'watermark':
        return Icons.branding_watermark_rounded;
      case 'pinyin':
        return Icons.abc_rounded;
      case 'base64':
        return Icons.code_rounded;
      case 'morse':
        return Icons.radio_rounded;
      case 'rc4':
        return Icons.vpn_key_rounded;
      case 'fancytext':
        return Icons.auto_awesome_rounded;
      case 'numtocn':
        return Icons.pin_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'pinyinabbr':
        return Icons.sort_by_alpha_rounded;
      case 'textimage':
        return Icons.text_fields_rounded;
      case 'bmi':
        return Icons.monitor_weight_rounded;
      case 'relative':
        return Icons.family_restroom_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'bloodtype':
        return Icons.bloodtype_rounded;
      case 'unit':
        return Icons.swap_horiz_rounded;
      case 'exchange':
        return Icons.currency_exchange_rounded;
      case 'loan':
        return Icons.home_work_rounded;
      case 'wheel':
        return Icons.casino_rounded;
      case 'game2048':
        return Icons.grid_4x4_rounded;
      case 'minesweeper':
        return Icons.flag_rounded;
      case 'snake':
        return Icons.sports_esports_rounded;
      case 'danmaku':
        return Icons.campaign_rounded;
      case 'piano':
        return Icons.piano_rounded;
      case 'drawboard':
        return Icons.brush_rounded;
      case 'joke':
        return Icons.sentiment_very_satisfied_rounded;
      case 'tiangou':
        return Icons.pets_rounded;
      case 'kfc':
        return Icons.fastfood_rounded;
      case 'weather':
        return Icons.wb_sunny_rounded;
      case 'oilprice':
        return Icons.oil_barrel_rounded;
      case 'express':
        return Icons.local_shipping_rounded;
      case 'hotsearch':
        return Icons.local_fire_department_rounded;
      case 'todayhistory':
        return Icons.calendar_month_rounded;
      case 'news':
        return Icons.newspaper_rounded;
      case 'forex':
        return Icons.trending_up_rounded;
      case 'deviceinfo':
        return Icons.phone_android_rounded;
      case 'deadpixel':
        return Icons.monitor_rounded;
      case 'argb':
        return Icons.palette_rounded;
      case 'mdcolor':
        return Icons.format_paint_rounded;
      case 'appmanager':
        return Icons.apps_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}

/// 统一的工具条目点击（搜索/收藏/历史 共用）
void openTool(Map<String, dynamic> t) {
  final id = (t['id'] is int) ? t['id'] as int : int.tryParse('${t['id']}') ?? 0;
  if (id > 0) SoftService.instance.jzsAddHistory(id);
  final title = '${t['title'] ?? ''}';
  final route = '${t['route'] ?? ''}';
  final target = '${t['target'] ?? ''}';
  final fn = toolRoute(title, target: target, route: route);
  if (fn != null) {
    fn();
    return;
  }
  if (target.startsWith('http')) {
    JumpUtil.openUrl(target);
    return;
  }
  ToastUtil.info('「$title」开发中，敬请期待');
}

// ═══════════════════ 搜索页 ═══════════════════

class ToolSearchPage extends StatefulWidget {
  const ToolSearchPage({super.key});

  @override
  State<ToolSearchPage> createState() => _ToolSearchPageState();
}

class _ToolSearchPageState extends State<ToolSearchPage> {
  final TextEditingController _c = TextEditingController();
  final FocusNode _f = FocusNode();
  List<Map<String, dynamic>> _list = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _f.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () => _do(v));
  }

  Future<void> _do(String v) async {
    final kw = v.trim();
    if (kw.isEmpty) {
      setState(() {
        _list = [];
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    final r = await SoftService.instance.jzsSearch(kw);
    if (!mounted) return;
    setState(() {
      _list = r;
      _loading = false;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: C.stroke.withAlpha(60), width: 0.9),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  size: 20, color: context.t3),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _c,
                                  focusNode: _f,
                                  onChanged: _onChanged,
                                  onSubmitted: _do,
                                  textInputAction: TextInputAction.search,
                                  style: const TextStyle(fontSize: 14.5),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: '搜索工具、功能',
                                    hintStyle: TextStyle(
                                        fontSize: 14.5, color: context.t3),
                                  ),
                                ),
                              ),
                              if (_c.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _c.clear();
                                    _onChanged('');
                                  },
                                  child: Icon(Icons.cancel_rounded,
                                      size: 18, color: context.t3),
                                ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('取消')),
                    ],
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4)));
    }
    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: context.t3),
            const SizedBox(height: 10),
            Text('输入关键词搜索工具', style: TextStyle(color: context.t3)),
          ],
        ),
      );
    }
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: context.t3),
            const SizedBox(height: 10),
            Text('没有找到相关工具', style: TextStyle(color: context.t3)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
      itemCount: _list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (c, i) => _tile(_list[i]),
    );
  }

  Widget _tile(Map<String, dynamic> t) {
    final icon = '${t['icon'] ?? ''}';
    final isEmoji = icon.isNotEmpty && icon.runes.first > 0x2000;
    return GestureDetector(
      onTap: () {
        Get.back(result: t);
        openTool(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.stroke.withAlpha(60), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: C.brand.withAlpha(20),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: isEmoji
                  ? Text(icon, style: const TextStyle(fontSize: 21))
                  : Icon(ToolIcons.of('${t['route'] ?? ''}'),
                      size: 22, color: C.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t['title'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${t['subtitle'] ?? ''}  ·  ${t['cat'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.t3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.t3),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════ 收藏页 ═══════════════════

class ToolFavPage extends StatefulWidget {
  const ToolFavPage({super.key});

  @override
  State<ToolFavPage> createState() => _ToolFavPageState();
}

class _ToolFavPageState extends State<ToolFavPage> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await SoftService.instance.jzsFavList();
    if (!mounted) return;
    setState(() {
      _list = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolListShell(
      title: '我的收藏',
      loading: _loading,
      list: _list,
      emptyIcon: Icons.star_border_rounded,
      emptyText: '还没有收藏任何工具\n去工具页点☆收藏吧',
      onRefresh: _load,
    );
  }
}

// ═══════════════════ 历史页 ═══════════════════

class ToolHistoryPage extends StatefulWidget {
  const ToolHistoryPage({super.key});

  @override
  State<ToolHistoryPage> createState() => _ToolHistoryPageState();
}

class _ToolHistoryPageState extends State<ToolHistoryPage> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await SoftService.instance.jzsHistory();
    if (!mounted) return;
    setState(() {
      _list = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolListShell(
      title: '使用历史',
      loading: _loading,
      list: _list,
      emptyIcon: Icons.history_rounded,
      emptyText: '还没有使用记录',
      onRefresh: _load,
    );
  }
}

/// 收藏/历史 共用的列表外壳
class _ToolListShell extends StatelessWidget {
  const _ToolListShell({
    required this.title,
    required this.loading,
    required this.list,
    required this.emptyIcon,
    required this.emptyText,
    required this.onRefresh,
  });

  final String title;
  final bool loading;
  final List<Map<String, dynamic>> list;
  final IconData emptyIcon;
  final String emptyText;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 19),
                      ),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Expanded(
                  child: loading
                      ? const Center(
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4)))
                      : (list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(emptyIcon, size: 48, color: context.t3),
                                  const SizedBox(height: 12),
                                  Text(emptyText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: context.t3, height: 1.6)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: onRefresh,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 6, 16, 40),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (c, i) => _tile(context, list[i]),
                              ),
                            )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Map<String, dynamic> t) {
    final icon = '${t['icon'] ?? ''}';
    final isEmoji = icon.isNotEmpty && icon.runes.first > 0x2000;
    return GestureDetector(
      onTap: () => openTool(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.stroke.withAlpha(60), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: C.brand.withAlpha(20),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: isEmoji
                  ? Text(icon, style: const TextStyle(fontSize: 21))
                  : Icon(ToolIcons.of('${t['route'] ?? ''}'),
                      size: 22, color: C.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${t['title'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right_rounded, color: context.t3),
          ],
        ),
      ),
    );
  }
}
