import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/jump_util.dart';
import '../../../utils/toast_util.dart';
import '../../toolhub/tool_router.dart';
import '../../toolhub/tools_hub_page.dart';

/// 工具 Tab（v45 —— 全面复刻样本「简助手」工具体系）
///
/// 样本结构（从 APK 布局文件还原）：
///   fragment_home_tool  工具主页
///   activity_tool_search 搜索页
///   item_tool / item_tool_grid  工具图标（列表 / 宫格）
///   item_tool_group     分类分组
///   item_tool_chip      分类胶囊
///   item_tool_history   使用历史
///
/// 页面结构：
///   ① 顶部：标题 + 搜索入口 + 收藏/历史/布局
///   ② 横幅轮播（来自后台）
///   ③ 分类胶囊（横向，点击定位到分组）
///   ④ 分组列表：分组头 + 工具宫格（圆形/方形/流式 三种）
class ToolsComponent extends StatefulWidget {
  const ToolsComponent({super.key});

  @override
  State<ToolsComponent> createState() => _ToolsComponentState();
}

class _ToolsComponentState extends State<ToolsComponent> {
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  ToolLayout _layout = ToolLayout.square;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _groupKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cfg = await SoftService.instance.fetchJzsConfig(force: true);
    if (!mounted) return;
    final groups = (cfg?['groups'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final banners = (cfg?['banners'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final st = '${cfg?['default_style'] ?? ''}';
    setState(() {
      _groups = groups;
      _banners = banners;
      _layout = ToolLayoutX.parse(st);
      _loading = false;
      _groupKeys.clear();
      for (var i = 0; i < _groups.length; i++) {
        _groupKeys[i] = GlobalKey();
      }
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
            bottom: false,
            child: Column(
              children: [
                _header(),
                _searchBar(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 2.4)))
                      : (_groups.isEmpty
                          ? _empty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: CustomScrollView(
                                controller: _scroll,
                                slivers: [
                                  if (_banners.isNotEmpty)
                                    SliverToBoxAdapter(child: _bannerArea()),
                                  SliverToBoxAdapter(child: _catChips()),
                                  ..._groupSlivers(),
                                  const SliverToBoxAdapter(
                                      child: SizedBox(height: 120)),
                                ],
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

  // ═══════════ 顶部栏 ═══════════

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 6),
      child: Row(
        children: [
          const Text('工具',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: C.brand.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${_groups.fold<int>(0, (a, g) => a + ((g['tools'] as List?)?.length ?? 0))}个',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w800, color: C.brand)),
          ),
          const Spacer(),
          _iconBtn(Icons.history_rounded, '历史',
              () => Get.to(() => const ToolHistoryPage())),
          _iconBtn(Icons.star_rounded, '收藏',
              () => Get.to(() => const ToolFavPage())),
          _iconBtn(_layout.icon, '布局', _pickLayout),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.stroke.withAlpha(60), width: 0.8),
        ),
        child: Icon(icon, size: 19, color: context.t2),
      ),
    );
  }

  // ═══════════ 搜索入口 ═══════════

  Widget _searchBar() {
    return GestureDetector(
      onTap: () async {
        final r = await Get.to(() => const ToolSearchPage());
        if (r is Map) _open(r);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.stroke.withAlpha(60), width: 0.9),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: context.t3),
            const SizedBox(width: 9),
            Text('搜索工具、功能',
                style: TextStyle(fontSize: 14, color: context.t3)),
          ],
        ),
      ),
    );
  }

  // ═══════════ 横幅轮播 ═══════════

  Widget _bannerArea() {
    final h = 128.0;
    return SizedBox(
      height: h + 14,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: _banners.length,
        itemBuilder: (c, i) {
          final b = _banners[i];
          final img = '${b['image'] ?? ''}';
          return GestureDetector(
            onTap: () => _onBanner(b),
            child: Container(
              margin: const EdgeInsets.fromLTRB(6, 4, 6, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: Deco.brandGradient,
                boxShadow: [
                  BoxShadow(
                      color: C.brand.withAlpha(60),
                      blurRadius: 18,
                      offset: const Offset(0, 8)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img.isNotEmpty)
                    Image.network(img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withAlpha(120),
                          Colors.black.withAlpha(20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${b['title'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        if ('${b['subtitle'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text('${b['subtitle']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withAlpha(220))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onBanner(Map<String, dynamic> b) {
    final link = '${b['link'] ?? ''}';
    final type = '${b['type'] ?? ''}';
    if (type == '公告') {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${b['title'] ?? '提示'}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: Text('${b['subtitle'] ?? ''}'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(c), child: const Text('知道了')),
          ],
        ),
      );
      return;
    }
    if (link.isEmpty) return;
    if (link.startsWith('http')) {
      JumpUtil.openUrl(link);
    } else {
      ToastUtil.info('$type：$link');
    }
  }

  // ═══════════ 分类胶囊 ═══════════

  Widget _catChips() {
    if (_groups.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
        itemCount: _groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final g = _groups[i];
          return GestureDetector(
            onTap: () => _jumpTo(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.stroke.withAlpha(60), width: 0.8),
              ),
              child: Text('${g['title'] ?? ''}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: context.t1)),
            ),
          );
        },
      ),
    );
  }

  void _jumpTo(int i) {
    final k = _groupKeys[i];
    if (k?.currentContext != null) {
      Scrollable.ensureVisible(k!.currentContext!,
          duration: const Duration(milliseconds: 320), alignment: 0.02);
    }
  }

  // ═══════════ 分组 ═══════════

  List<Widget> _groupSlivers() {
    final out = <Widget>[];
    for (var i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      final tools = (g['tools'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      if (tools.isEmpty) continue;
      out.add(SliverToBoxAdapter(
        child: Container(
          key: _groupKeys[i],
          child: _groupBlock(g, tools),
        ),
      ));
    }
    return out;
  }

  Widget _groupBlock(Map<String, dynamic> g, List<Map<String, dynamic>> tools) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.stroke.withAlpha(60), width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(context.isDark ? 60 : 10),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 15,
                decoration: BoxDecoration(
                  gradient: Deco.brandGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text('${g['title'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Text('${g['hint'] ?? ''}',
                  style: TextStyle(fontSize: 11.5, color: context.t3)),
              const Spacer(),
              Text('${tools.length}个',
                  style: TextStyle(fontSize: 11.5, color: context.t3)),
            ],
          ),
          const SizedBox(height: 14),
          _toolsOf(tools),
        ],
      ),
    );
  }

  Widget _toolsOf(List<Map<String, dynamic>> tools) {
    switch (_layout) {
      case ToolLayout.circle:
        return Wrap(
          spacing: 4,
          runSpacing: 14,
          children: tools
              .map((t) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - 32) / 4,
                  child: _gridItem(t, circle: true)))
              .toList(),
        );
      case ToolLayout.square:
        return Wrap(
          spacing: 4,
          runSpacing: 14,
          children: tools
              .map((t) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - 32) / 4,
                  child: _gridItem(t, circle: false)))
              .toList(),
        );
      case ToolLayout.flow:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools.map((t) => _flowItem(t)).toList(),
        );
    }
  }

  Widget _gridItem(Map<String, dynamic> t, {required bool circle}) {
    final icon = '${t['icon'] ?? ''}';
    final isEmoji = _isEmoji(icon);
    return GestureDetector(
      onTap: () => _open(t),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _iconBg(t),
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circle ? null : BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: isEmoji
                ? Text(icon, style: const TextStyle(fontSize: 24))
                : Icon(_iconOf('${t['route'] ?? ''}'),
                    size: 25, color: C.brand),
          ),
          const SizedBox(height: 6),
          Text('${t['title'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _flowItem(Map<String, dynamic> t) {
    final icon = '${t['icon'] ?? ''}';
    return GestureDetector(
      onTap: () => _open(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _iconBg(t),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEmoji(icon))
              Text(icon, style: const TextStyle(fontSize: 15))
            else
              Icon(_iconOf('${t['route'] ?? ''}'), size: 15, color: C.brand),
            const SizedBox(width: 6),
            Text('${t['title'] ?? ''}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _iconBg(Map<String, dynamic> t) {
    return C.brand.withAlpha(context.isDark ? 34 : 20);
  }

  bool _isEmoji(String s) {
    if (s.isEmpty) return false;
    final r = s.runes.first;
    return r > 0x2000;
  }

  IconData _iconOf(String route) => ToolIcons.of(route);

  // ═══════════ 打开工具 ═══════════

  void _open(Map<String, dynamic> t) {
    final id = (t['id'] is int) ? t['id'] as int : int.tryParse('${t['id']}') ?? 0;
    if (id > 0) SoftService.instance.jzsAddHistory(id);

    final route = '${t['route'] ?? ''}';
    final title = '${t['title'] ?? ''}';
    final target = '${t['target'] ?? ''}';

    // 1) 内置路由命中 → 开真实页面
    final fn = toolRoute(title, target: target, route: route);
    if (fn != null) {
      fn();
      return;
    }
    // 2) 外链
    if (target.startsWith('http')) {
      JumpUtil.openUrl(target);
      return;
    }
    ToastUtil.info('「$title」开发中，敬请期待');
  }

  // ═══════════ 布局切换 ═══════════

  Future<void> _pickLayout() async {
    final r = await showModalBottomSheet<ToolLayout>(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const Text('工具布局',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final l in ToolLayout.values)
              ListTile(
                leading: Icon(l.icon, color: C.brand),
                title: Text(l.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: _layout == l
                    ? Icon(Icons.check_circle_rounded, color: C.brand)
                    : null,
                onTap: () => Navigator.pop(c, l),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (r != null) setState(() => _layout = r);
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.widgets_outlined, size: 46, color: context.t3),
          const SizedBox(height: 10),
          Text('暂无工具', style: TextStyle(color: context.t3)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('重新加载')),
        ],
      ),
    );
  }
}
