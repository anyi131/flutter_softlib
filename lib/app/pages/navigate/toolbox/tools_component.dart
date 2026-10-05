import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/jump_util.dart';
import '../../../utils/toast_util.dart';

/// 工具 Tab（v43 #5）
///
/// 结构：
///   ① 顶部标题栏（右上角：布局切换 + 全部工具）
///   ② 按「分类」分组的工具卡片流
///   ③ 每个分组：渐变图标 + 中英文标题 + 「N个工具」胶囊 + 工具图标网格
///
/// 三种布局（对齐用户截图里的「列表样式」）：
///   circle  圆形宫格
///   square  矩形宫格（默认）
///   flow    流式布局（胶囊 chips 自动换行）
enum ToolLayout { circle, square, flow }

class ToolsComponent extends StatefulWidget {
  const ToolsComponent({super.key});

  @override
  State<ToolsComponent> createState() => _ToolsComponentState();
}

class _ToolsComponentState extends State<ToolsComponent> {
  List<Map<String, dynamic>> _cats = [];
  bool _loading = true;
  ToolLayout _layout = ToolLayout.square;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await SoftService.instance.fetchTools();
    if (!mounted) return;
    setState(() {
      _cats = list;
      _loading = false;
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
                Expanded(
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                              width: 26,
                              height: 26,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4)))
                      : (_cats.isEmpty
                          ? _empty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding: EdgeInsets.fromLTRB(
                                    context.pagePadding,
                                    4,
                                    context.pagePadding,
                                    context.tabSpace + 30),
                                children: [
                                  for (final c in _cats) ...[
                                    _catHeader(c),
                                    const SizedBox(height: 12),
                                    _toolsOf(c),
                                    const SizedBox(height: 18),
                                  ],
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

  // ───── 顶部 ─────
  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 12, context.pagePadding, 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (r) => Deco.aurora().createShader(r),
            child:
                Text('工具', style: Ty.display.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Text('${_total()} 个', style: Ty.tiny.copyWith(color: context.t3)),
          const Spacer(),
          _circleBtn(Icons.dashboard_customize_outlined, _pickLayout),
          const SizedBox(width: 8),
          _circleBtn(Icons.apps_rounded, _showAll),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark ? Colors.white.withAlpha(14) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.isDark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(8),
          ),
        ),
        child: Icon(icon, size: 19, color: context.t2),
      ),
    );
  }

  /// 布局切换（圆形宫格 / 矩形宫格 / 流式布局）
  Future<void> _pickLayout() async {
    final picked = await Get.dialog<ToolLayout>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('列表样式',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _layoutOpt(ToolLayout.circle, Icons.blur_on_rounded, '圆形宫格'),
            _layoutOpt(ToolLayout.square, Icons.grid_view_rounded, '矩形宫格'),
            _layoutOpt(ToolLayout.flow, Icons.view_stream_rounded, '流式布局'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _layout = picked);
  }

  Widget _layoutOpt(ToolLayout l, IconData icon, String name) {
    final sel = _layout == l;
    return InkWell(
      onTap: () => Get.back(result: l),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: sel ? C.brand : context.t3),
            const SizedBox(width: 12),
            Text(name,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
            const Spacer(),
            Icon(
              sel
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: sel ? C.brand : context.t3,
            ),
          ],
        ),
      ),
    );
  }

  /// 全部工具汇总
  void _showAll() {
    final all = <Map<String, dynamic>>[];
    for (final c in _cats) {
      for (final t in (c['tools'] as List? ?? [])) {
        all.add({...Map<String, dynamic>.from(t), 'cat': '${c['title']}'});
      }
    }
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.75),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.apps_rounded, color: C.brand, size: 20),
                  const SizedBox(width: 8),
                  Text('全部工具（${all.length}）',
                      style: Ty.h2.copyWith(fontSize: 16, color: context.t1)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Get.back()),
                ],
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final t = all[i];
                    return ListTile(
                      dense: true,
                      leading: _letterIcon('${t['title']}', 36),
                      title: Text('${t['title']}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: Text('${t['cat']}',
                          style: Ty.tiny.copyWith(color: context.t3)),
                      trailing: Icon(Icons.open_in_new_rounded,
                          size: 16, color: context.t3),
                      onTap: () => _open(t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───── 分组头 ─────
  Widget _catHeader(Map<String, dynamic> c) {
    final color = _parseColor('${c['color']}');
    return KitCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withAlpha(context.isDark ? 150 : 110),
                  color.withAlpha(context.isDark ? 80 : 60),
                ],
              ),
              borderRadius: BorderRadius.circular(R.md),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                Icon(_catIcon('${c['icon']}'), size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['title']}',
                    style:
                        Ty.h3.copyWith(fontSize: 15.5, color: context.t1)),
                const SizedBox(height: 2),
                Text('${c['subtitle']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.tiny
                        .copyWith(fontSize: 10.5, color: context.t3)),
              ],
            ),
          ),
          Pill('${c['count'] ?? 0} 个', color: color, small: true),
        ],
      ),
    );
  }

  // ───── 工具区（三种布局）─────
  Widget _toolsOf(Map<String, dynamic> c) {
    final tools = (c['tools'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (tools.isEmpty) return const SizedBox.shrink();

    switch (_layout) {
      case ToolLayout.circle:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemCount: tools.length,
          itemBuilder: (_, i) => _gridItem(tools[i], true),
        );
      case ToolLayout.square:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.86,
          ),
          itemCount: tools.length,
          itemBuilder: (_, i) => _gridItem(tools[i], false),
        );
      case ToolLayout.flow:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools.map(_flowItem).toList(),
        );
    }
  }

  Widget _gridItem(Map<String, dynamic> t, bool circle) {
    return GestureDetector(
      onTap: () => _open(t),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.isDark
                  ? Colors.white.withAlpha(12)
                  : C.brand.withAlpha(14),
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circle ? null : BorderRadius.circular(14),
              border: Border.all(
                color: context.isDark
                    ? Colors.white.withAlpha(22)
                    : Colors.black.withAlpha(8),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _toolIcon('${t['icon']}', '${t['title']}', 50),
          ),
          const SizedBox(height: 7),
          Text('${t['title']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: context.t2)),
        ],
      ),
    );
  }

  Widget _flowItem(Map<String, dynamic> t) {
    return GestureDetector(
      onTap: () => _open(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.white.withAlpha(10)
              : C.brand.withAlpha(12),
          borderRadius: BorderRadius.circular(R.full),
          border: Border.all(
            color: context.isDark
                ? Colors.white.withAlpha(20)
                : Colors.black.withAlpha(8),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 18,
                height: 18,
                child: _toolIcon('${t['icon']}', '${t['title']}', 18)),
            const SizedBox(width: 6),
            Text('${t['title']}',
                style: TextStyle(fontSize: 12.5, color: context.t2)),
          ],
        ),
      ),
    );
  }

  /// 图标：优先用后台配的图片 URL，否则用首字色块
  Widget _toolIcon(String icon, String title, double size) {
    if (icon.startsWith('http')) {
      return Image.network(
        icon,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _letterIcon(title, size),
      );
    }
    return _letterIcon(title, size);
  }

  Widget _letterIcon(String title, double size) {
    final colors = [C.brand, C.cyan, C.mint, C.violet, C.amber, C.pink];
    final c = colors[title.hashCode.abs() % colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: c.withAlpha(30),
      child: Text(
        title.isNotEmpty ? title.characters.first : '·',
        style: TextStyle(
            fontSize: size * 0.42, fontWeight: FontWeight.w900, color: c),
      ),
    );
  }

  void _open(Map<String, dynamic> t) {
    final target = '${t['target'] ?? ''}';
    if (target.isEmpty) {
      ToastUtil.error('该工具暂未配置链接');
      return;
    }
    if ('${t['type']}' == 'page' && target.startsWith('/')) {
      Get.toNamed(target);
      return;
    }
    JumpUtil.openUrl(target);
  }

  int _total() {
    var n = 0;
    for (final c in _cats) {
      n += (c['count'] as num?)?.toInt() ?? 0;
    }
    return n;
  }

  Color _parseColor(String s) {
    var v = s.trim().replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    final n = int.tryParse(v, radix: 16);
    return n == null ? C.brand : Color(n);
  }

  IconData _catIcon(String key) {
    const map = {
      'movie': Icons.movie_rounded,
      'link': Icons.link_rounded,
      'tool': Icons.handyman_rounded,
      'news': Icons.newspaper_rounded,
      'image': Icons.image_rounded,
      'text': Icons.text_fields_rounded,
      'calc': Icons.calculate_rounded,
      'game': Icons.sports_esports_rounded,
    };
    return map[key] ?? Icons.widgets_rounded;
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.widgets_outlined, size: 44, color: context.t3),
          const SizedBox(height: 14),
          Text('暂无工具', style: Ty.h3.copyWith(color: context.t1)),
          const SizedBox(height: 8),
          Text('管理员可在后台「内容 → 工具」中添加',
              style: Ty.small.copyWith(color: context.t3)),
        ],
      ),
    );
  }
}
