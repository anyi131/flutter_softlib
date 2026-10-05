import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// ═══════════════════════════════════════════════════════════
/// 工具管理系统 v2 —— 一体化：总览 + 分类 + 工具 + 接口测试
/// ═══════════════════════════════════════════════════════════
class AdminToolsV2Tab extends StatefulWidget {
  const AdminToolsV2Tab({super.key});
  @override
  State<AdminToolsV2Tab> createState() => _AdminToolsV2TabState();
}

class _AdminToolsV2TabState extends State<AdminToolsV2Tab>
    with SingleTickerProviderStateMixin {
  late TabController _tab = TabController(length: 2, vsync: this);
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _tools = [];
  bool _loading = true;
  String _kw = '';
  int _catFilter = 0; // 0=全部
  int _testingToolId = 0;
  Map<int, String> _testResult = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await AdminService.instance.jzsCats();
      final tools = await AdminService.instance.jzsTools();
      if (!mounted) return;
      setState(() {
        _cats = cats;
        _tools = tools;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.error('加载失败');
    }
  }

  int _countOf(int catId) =>
      _tools.where((t) => (t['cat_id'] ?? 0) == catId).length;

  List<Map<String, dynamic>> get _filtered {
    var l = _tools;
    if (_catFilter > 0) {
      l = l.where((t) => (t['cat_id'] ?? 0) == _catFilter).toList();
    }
    if (_kw.isNotEmpty) {
      l = l
          .where((t) =>
              '${t['title'] ?? ''}'.contains(_kw) ||
              '${t['route'] ?? ''}'.contains(_kw.toLowerCase()))
          .toList();
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 顶部总览条
        _overview(),
        TabBar(
          controller: _tab,
          labelColor: C.brand,
          unselectedLabelColor: context.t3,
          indicatorColor: C.brand,
          tabs: const [Tab(text: '工具管理'), Tab(text: '分类管理')],
        ),
        Expanded(
          child: _loading
              ? const LoadingState(text: '加载中…')
              : TabBarView(
                  controller: _tab,
                  children: [_toolsTab(), _catsTab()],
                ),
        ),
      ],
    );
  }

  Widget _overview() {
    final online = _tools.where((t) => '${t['api_url'] ?? ''}'.isNotEmpty).length;
    final off = _tools.where((t) => '${t['enable_switch'] ?? 1}' == '0').length;
    return Container(
      margin: EdgeInsets.fromLTRB(
          context.pagePadding, 10, context.pagePadding, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: Deco.brandGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ov('分类', '${_cats.length}'),
          _ov('工具', '${_tools.length}'),
          _ov('联网工具', '$online'),
          _ov('已停用', '$off'),
        ],
      ),
    );
  }

  Widget _ov(String label, String v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      );

  // ═══════════ 工具管理 ═══════════
  Widget _toolsTab() {
    final list = _filtered;
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.fromLTRB(context.pagePadding, 8, context.pagePadding, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _kw = v.trim()),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: '搜索工具名 / route',
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _catFilter,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: 0, child: Text('全部分类')),
                ..._cats.map((c) => DropdownMenuItem(
                    value: (c['id'] ?? 0) as int, child: Text('${c['title']}'))),
              ],
              onChanged: (v) => setState(() => _catFilter = v ?? 0),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(context.pagePadding, 10,
                  context.pagePadding, 40),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _toolRow(list[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toolRow(Map<String, dynamic> t) {
    final id = (t['id'] ?? 0) as int;
    final online = '${t['api_url'] ?? ''}'.isNotEmpty;
    final enabled = '${t['enable_switch'] ?? 1}' != '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: enabled
                ? Colors.transparent
                : Colors.orange.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('${t['icon'] ?? '🧩'} ',
                style: const TextStyle(fontSize: 16)),
            Expanded(
              child: Text('${t['title'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800)),
            ),
            if (online)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('API',
                    style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w800)),
              ),
            const SizedBox(width: 6),
            Switch(
              value: enabled,
              activeColor: C.brand,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => _toggle(t, v),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (k) {
                if (k == 'edit') _editTool(t);
                if (k == 'del') _delTool(t);
                if (k == 'test') _testApi(t);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'test', child: Text('测试接口')),
                PopupMenuItem(value: 'del', child: Text('删除')),
              ],
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'route: ${t['route'] ?? '-'}'
            '${online ? ' · 接口: ${_shortUrl(t['api_url'])}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.t3),
          ),
          if (_testResult[id] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_testResult[id]!,
                  style: TextStyle(
                      fontSize: 11,
                      color: _testResult[id]!.startsWith('✅')
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))),
            ),
        ],
      ),
    );
  }

  String _shortUrl(dynamic u) {
    final s = '$u';
    return s.length > 40 ? '${s.substring(0, 40)}…' : s;
  }

  Future<void> _toggle(Map<String, dynamic> t, bool v) async {
    try {
      await AdminService.instance.saveJzsTool({...t, 'enable_switch': v ? 1 : 0});
      await _load();
    } catch (_) {
      ToastUtil.error('操作失败');
    }
  }

  Future<void> _testApi(Map<String, dynamic> t) async {
    final id = (t['id'] ?? 0) as int;
    if ('${t['api_url'] ?? ''}'.isEmpty) {
      ToastUtil.info('该工具未配置接口');
      return;
    }
    setState(() {
      _testingToolId = id;
      _testResult[id] = '⏳ 测试中…';
    });
    try {
      final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          validateStatus: (c) => c != null && c < 600));
      final r = await dio.get('${t['api_url']}');
      final ok = r.statusCode == 200;
      String detail = 'HTTP ${r.statusCode}';
      final d = r.data;
      if (d is Map) detail += ' · JSON✓ keys=${d.keys.take(4).toList()}';
      setState(() => _testResult[id] =
          '${ok ? "✅" : "❌"} $detail');
    } catch (e) {
      setState(() => _testResult[id] = '❌ 失败：${e.toString().substring(0, e.toString().length.clamp(0, 60))}');
    }
    setState(() => _testingToolId = 0);
  }

  Future<void> _editTool([Map<String, dynamic>? t]) async {
    final title = TextEditingController(text: '${t?['title'] ?? ''}');
    final icon = TextEditingController(text: '${t?['icon'] ?? ''}');
    final route = TextEditingController(text: '${t?['route'] ?? ''}');
    final target = TextEditingController(text: '${t?['target'] ?? ''}');
    final apiUrl = TextEditingController(text: '${t?['api_url'] ?? ''}');
    int? catId = t?['cat_id'];

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF23252B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t == null ? '新增工具' : '编辑工具',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            _f('名称', title),
            _f('图标 emoji', icon),
            DropdownButtonFormField<int>(
              value: catId,
              decoration: const InputDecoration(labelText: '分类'),
              items: _cats
                  .map((c) => DropdownMenuItem(
                      value: (c['id'] ?? 0) as int,
                      child: Text('${c['title']}')))
                  .toList(),
              onChanged: (v) => catId = v,
            ),
            _f('路由 route（内置工具标识）', route),
            _f('外链 target（可选）', target),
            _f('接口地址 api_url（联网数据源，支持 {q}/{page}）', apiUrl, maxLines: 2),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Get.back(), child: const Text('取消')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.brand),
                onPressed: () => Get.back(result: true),
                child: const Text('保存'),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.instance.saveJzsTool({
        if (t != null) 'id': t['id'],
        'cat_id': catId ?? 0,
        'title': title.text.trim(),
        'subtitle': t?['subtitle'] ?? '',
        'icon': icon.text.trim(),
        'route': route.text.trim(),
        'target': target.text.trim(),
        'api_url': apiUrl.text.trim(),
        'kind': '${target.text.trim()}'.isEmpty ? 'local' : 'link',
        'need_ad': t?['need_ad'] ?? 0,
        'enable_switch': t?['enable_switch'] ?? 1,
      });
      ToastUtil.success('已保存');
      await _load();
    } catch (e) {
      ToastUtil.error('保存失败');
    }
  }

  Widget _f(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Future<void> _delTool(Map<String, dynamic> t) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除工具'),
        content: Text('确定删除「${t['title']}」？不可恢复。'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('删除',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.instance.deleteJzsTool((t['id'] ?? 0) as int);
      ToastUtil.success('已删除');
      await _load();
    } catch (_) {
      ToastUtil.error('删除失败');
    }
  }

  // ═══════════ 分类管理 ═══════════
  Widget _catsTab() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 12, context.pagePadding, 40),
      itemCount: _cats.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == _cats.length) {
          return OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('新增分类'),
            style: OutlinedButton.styleFrom(
                foregroundColor: C.brand,
                side: BorderSide(color: C.brand.withAlpha(80))),
            onPressed: () => _editCat(),
          );
        }
        final c = _cats[i];
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.isDark ? Colors.white.withAlpha(10) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text('${c['icon'] ?? '📁'} ',
                style: const TextStyle(fontSize: 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${c['title'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w800)),
                  Text('提示: ${c['hint'] ?? '-'}',
                      style: TextStyle(fontSize: 11, color: context.t3)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: C.brand.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${_countOf((c['id'] ?? 0) as int)} 个',
                  style: TextStyle(
                      fontSize: 11, color: C.brand,
                      fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _editCat(c),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _editCat([Map<String, dynamic>? c]) async {
    final title = TextEditingController(text: '${c?['title'] ?? ''}');
    final hint = TextEditingController(text: '${c?['hint'] ?? ''}');
    final icon = TextEditingController(text: '${c?['icon'] ?? ''}');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF23252B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(c == null ? '新增分类' : '编辑分类',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          _f('分类名', title),
          _f('英文/提示', hint),
          _f('图标 emoji', icon),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (c != null)
              TextButton(
                onPressed: () => Get.back(result: 'del'),
                child: const Text('删除分类',
                    style: TextStyle(color: Color(0xFFEF4444))),
              )
            else
              const SizedBox(),
            Row(children: [
              TextButton(onPressed: () => Get.back(), child: const Text('取消')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.brand),
                onPressed: () => Get.back(result: true),
                child: const Text('保存'),
              ),
            ]),
          ]),
        ]),
      ),
    );
    if (ok == null) return;
    try {
      if (ok == 'del') {
        await AdminService.instance.deleteJzsCat((c!['id'] ?? 0) as int);
      } else {
        await AdminService.instance.saveJzsCat({
          if (c != null) 'id': c['id'],
          'title': title.text.trim(),
          'hint': hint.text.trim(),
          'icon': icon.text.trim(),
        });
      }
      ToastUtil.success('已保存');
      await _load();
    } catch (e) {
      ToastUtil.error('操作失败：${e.toString().substring(0, e.toString().length.clamp(0, 40))}');
    }
  }
}
