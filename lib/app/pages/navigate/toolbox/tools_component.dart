import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/jump_util.dart';
import '../../../utils/toast_util.dart';
import '../../toolhub/tool_router.dart';
import '../../toolhub/tools_hub_page.dart';

/// 工具 Tab（v46 —— 按样本「简助手」录屏 1:1 复刻）
///
/// 与样本一致的要点（逐帧比对录屏确认）：
///   ① 顶部只有「工具」大标题 + 右上 2 个图标（布局切换 / 主题）—— 无搜索栏、无横幅
///   ② 分类 = 白色圆角大卡：
///        · 卡头：左侧 56x56 浅紫圆角图标块 + 中文名(17sp粗) + 英文副标题(灰12sp)
///                + 右侧「N个应用」浅紫胶囊
///        · 卡体：工具为**自适应胶囊 chips**（浅紫灰底 + 大圆角 + 小图标 + 文字）
///   ③ 页面底色米白(#FAF9FE)，卡片纯白，点缀色淡紫
class ToolsComponent extends StatefulWidget {
  const ToolsComponent({super.key});

  @override
  State<ToolsComponent> createState() => _ToolsComponentState();
}

class _ToolsComponentState extends State<ToolsComponent> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  ToolLayout _layout = ToolLayout.flow;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cfg = await SoftService.instance.fetchJzsConfig(force: true);
    if (!mounted) return;
    final groups = (cfg?['groups'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final st = '${cfg?['default_style'] ?? 'flow'}';
    setState(() {
      _groups = groups;
      _layout = ToolLayoutX.parse(st);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
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
                          color: const Color(0xFF4B5EF5),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: _groups.length,
                            itemBuilder: (c, i) => _groupCard(_groups[i]),
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════ 顶部标题栏（样本：无搜索栏）═══════════

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
      child: Row(
        children: [
          const Text('工具',
              style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14161E),
                  letterSpacing: 0.3)),
          const Spacer(),
          _topIcon(Icons.account_tree_outlined, _pickLayout),
          const SizedBox(width: 4),
          _topIcon(Icons.brightness_6_outlined, _toggleTheme),
        ],
      ),
    );
  }

  Widget _topIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 23, color: const Color(0xFF14161E)),
      ),
    );
  }

  void _toggleTheme() {
    final t = Get.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    Get.changeThemeMode(t);
  }

  // ═══════════ 分类卡片（样本核心）═══════════

  Widget _groupCard(Map<String, dynamic> g) {
    final tools = (g['tools'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (tools.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B7FD4).withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _catHead(g, tools.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: _toolChips(tools),
          ),
        ],
      ),
    );
  }

  /// 卡头：图标块 + 中英文名 + N个应用
  Widget _catHead(Map<String, dynamic> g, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          // 左侧图标块（浅紫圆角方块）
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E4F8),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              _catIcon('${g['title'] ?? ''}'),
              size: 26,
              color: const Color(0xFF5B6BC0),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${g['title'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14161E))),
                const SizedBox(height: 3),
                Text('${g['hint'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9BA1B0),
                        letterSpacing: 0.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧「N个应用」胶囊
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count个应用',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B72C9))),
          ),
        ],
      ),
    );
  }

  /// 工具区：三种布局（样本默认「流式布局」= 胶囊 chips 自适应换行）
  Widget _toolChips(List<Map<String, dynamic>> tools) {
    switch (_layout) {
      case ToolLayout.flow:
        return Wrap(
          spacing: 8,
          runSpacing: 9,
          children: tools.map((t) => _chip(t)).toList(),
        );
      case ToolLayout.square:
        return _grid(tools, circle: false);
      case ToolLayout.circle:
        return _grid(tools, circle: true);
    }
  }

  /// 单个工具胶囊（样本样式：浅紫灰底 + 大圆角 + 图标 + 文字）
  Widget _chip(Map<String, dynamic> t) {
    return GestureDetector(
      onTap: () => _open(t),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 14, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1FC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolIcon(t, 22),
            const SizedBox(width: 7),
            Text('${t['title'] ?? ''}',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2A2D3A))),
          ],
        ),
      ),
    );
  }

  /// 宫格布局（切换用）
  Widget _grid(List<Map<String, dynamic>> tools, {required bool circle}) {
    final w = (MediaQuery.of(context).size.width - 28 - 28) / 4;
    return Wrap(
      spacing: 6,
      runSpacing: 14,
      children: tools
          .map((t) => SizedBox(
                width: w,
                child: GestureDetector(
                  onTap: () => _open(t),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F1FC),
                          shape: circle ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius:
                              circle ? null : BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: _toolIcon(t, 24),
                      ),
                      const SizedBox(height: 6),
                      Text('${t['title'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2A2D3A))),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// 工具图标（emoji 直接渲染，否则用 Icon）
  Widget _toolIcon(Map<String, dynamic> t, double size) {
    final icon = '${t['icon'] ?? ''}';
    if (icon.isNotEmpty && icon.runes.first > 0x2000) {
      return Text(icon, style: TextStyle(fontSize: size * 0.86));
    }
    return Icon(ToolIcons.of('${t['route'] ?? ''}'),
        size: size, color: const Color(0xFF5B6BC0));
  }

  /// 分类图标（按分类名映射）
  IconData _catIcon(String name) {
    switch (name) {
      case '影音书漫':
        return Icons.movie_filter_rounded;
      case '资源解析':
        return Icons.inventory_2_rounded;
      case '生活便捷':
        return Icons.work_rounded;
      case '信息资讯':
        return Icons.newspaper_rounded;
      case '美图资源':
        return Icons.image_rounded;
      case '图片处理':
        return Icons.auto_fix_high_rounded;
      case '系统极客':
        return Icons.settings_suggest_rounded;
      case '设计配色':
        return Icons.palette_rounded;
      case '趣味娱乐':
        return Icons.sports_esports_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  // ═══════════ 打开工具 ═══════════

  void _open(Map<String, dynamic> t) {
    final id = (t['id'] is int)
        ? t['id'] as int
        : int.tryParse('${t['id']}') ?? 0;
    if (id > 0) SoftService.instance.jzsAddHistory(id);

    final route = '${t['route'] ?? ''}';
    final title = '${t['title'] ?? ''}';
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

  // ═══════════ 布局切换（样本：底部 sheet「外观样式」）═══════════

  Future<void> _pickLayout() async {
    final r = await showModalBottomSheet<ToolLayout>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 20, 22, 6),
                child: Text('列表样式',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 6),
              for (final l in ToolLayout.values)
                InkWell(
                  onTap: () => Navigator.pop(c, l),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                    child: Row(
                      children: [
                        Text(l.label,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Icon(
                          _layout == l
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 22,
                          color: _layout == l
                              ? const Color(0xFF4B5EF5)
                              : const Color(0xFFC5C9D4),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('取消',
                            style: TextStyle(
                                fontSize: 15.5, color: Color(0xFF8A90A2))),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(c, _layout),
                        child: const Text('确定',
                            style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4B5EF5))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          Icon(Icons.widgets_outlined, size: 46, color: const Color(0xFF9BA1B0)),
          const SizedBox(height: 10),
          const Text('暂无工具', style: TextStyle(color: Color(0xFF9BA1B0))),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('重新加载')),
        ],
      ),
    );
  }
}
