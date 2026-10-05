import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 后台「工具」管理（v45 —— 对齐样本「简助手」工具体系）
///
/// 三个子页：
///   ① 分类   ② 工具   ③ 横幅
class AdminToolTab extends StatefulWidget {
  const AdminToolTab({super.key});

  @override
  State<AdminToolTab> createState() => _AdminToolTabState();
}

class _AdminToolTabState extends State<AdminToolTab>
    with SingleTickerProviderStateMixin {
  final _svc = AdminService.instance;
  late final TabController _tab = TabController(length: 3, vsync: this);

  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _tools = [];
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await _svc.jzsCats();
      final t = await _svc.jzsTools();
      final b = await _svc.jzsBanners();
      if (!mounted) return;
      setState(() {
        _cats = c;
        _tools = t;
        _banners = b;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.error('加载失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              const Text('工具体系',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 20)),
              IconButton(
                onPressed: () => _editTool(null),
                icon: Icon(Icons.add_circle_outline_rounded,
                    size: 22, color: C.brand),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tab,
          labelColor: C.brand,
          unselectedLabelColor: context.t3,
          indicatorColor: C.brand,
          tabs: const [
            Tab(text: '分类'),
            Tab(text: '工具'),
            Tab(text: '横幅'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4)))
              : TabBarView(
                  controller: _tab,
                  children: [_catList(), _toolList(), _bannerList()],
                ),
        ),
      ],
    );
  }

  // ═══════════ 分类 ═══════════

  Widget _catList() {
    if (_cats.isEmpty) return _empty('暂无分类');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      itemCount: _cats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (c, i) {
        final x = _cats[i];
        return _card(
          title: '${x['title'] ?? ''}',
          subtitle: '${x['hint'] ?? ''}  ·  ${x['tool_count'] ?? 0}个工具',
          trailing: '${x['enable_switch'] == 1 ? '启用' : '停用'}',
          onEdit: () => _editCat(x),
          onDelete: () => _del('jzs_cat_del', '${x['id']}', '分类'),
        );
      },
    );
  }

  // ═══════════ 工具 ═══════════

  Widget _toolList() {
    if (_tools.isEmpty) return _empty('暂无工具');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      itemCount: _tools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (c, i) {
        final x = _tools[i];
        return _card(
          title: '${x['icon'] ?? ''} ${x['title'] ?? ''}',
          subtitle:
              '${x['cat_title'] ?? ''} · ${x['subtitle'] ?? ''} · route=${x['route'] ?? ''}',
          trailing: '${x['need_ad'] == 1 ? '需广告' : '免费'}',
          onEdit: () => _editTool(x),
          onDelete: () => _del('jzs_tool_del', '${x['id']}', '工具'),
        );
      },
    );
  }

  // ═══════════ 横幅 ═══════════

  Widget _bannerList() {
    if (_banners.isEmpty) return _empty('暂无横幅');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      itemCount: _banners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (c, i) {
        final x = _banners[i];
        return _card(
          title: '${x['title'] ?? ''}',
          subtitle: '${x['type'] ?? ''} · ${x['subtitle'] ?? ''}',
          trailing: '${x['scene'] ?? ''}',
          onEdit: () => _editBanner(x),
          onDelete: () => _del('jzs_banner_del', '${x['id']}', '横幅'),
        );
      },
    );
  }

  // ═══════════ 通用卡片 ═══════════

  Widget _card({
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.stroke.withAlpha(50), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.t3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: C.brand.withAlpha(22),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(trailing,
                style: TextStyle(
                    fontSize: 10.5, color: C.brand, fontWeight: FontWeight.w700)),
          ),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18)),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFFB7185))),
        ],
      ),
    );
  }

  Widget _empty(String t) => Center(
        child: Text(t, style: TextStyle(color: context.t3)),
      );

  Future<void> _del(String action, String id, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('删除$label'),
        content: Text('确定要删除这个$label吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFFB7185)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      switch (action) {
        case 'jzs_cat_del':
          await _svc.deleteJzsCat(int.parse(id));
          break;
        case 'jzs_tool_del':
          await _svc.deleteJzsTool(int.parse(id));
          break;
        default:
          await _svc.deleteJzsBanner(int.parse(id));
      }
      ToastUtil.success('已删除');
      _load();
    } catch (e) {
      ToastUtil.error('$e');
    }
  }

  // ═══════════ 编辑弹窗 ═══════════

  Future<void> _editCat(Map<String, dynamic>? x) async {
    final title = TextEditingController(text: '${x?['title'] ?? ''}');
    final hint = TextEditingController(text: '${x?['hint'] ?? ''}');
    final weigh = TextEditingController(text: '${x?['weigh'] ?? 0}');
    await _sheet('分类', [
      _field('分类名', title, '如：常用工具'),
      _field('说明', hint, '如：日常高频，打开就能用'),
      _field('排序权重', weigh, '越大越靠前', number: true),
    ], () async {
      await _svc.saveJzsCat({
        if (x != null) 'id': x['id'],
        'title': title.text.trim(),
        'hint': hint.text.trim(),
        'weigh': int.tryParse(weigh.text) ?? 0,
        'enable_switch': 1,
      });
    });
  }

  Future<void> _editTool(Map<String, dynamic>? x) async {
    final title = TextEditingController(text: '${x?['title'] ?? ''}');
    final subtitle = TextEditingController(text: '${x?['subtitle'] ?? ''}');
    final icon = TextEditingController(text: '${x?['icon'] ?? ''}');
    final route = TextEditingController(text: '${x?['route'] ?? ''}');
    final target = TextEditingController(text: '${x?['target'] ?? ''}');
    final apiUrl = TextEditingController(text: '${x?['api_url'] ?? ''}');
    final weigh = TextEditingController(text: '${x?['weigh'] ?? 0}');
    int catId = int.tryParse('${x?['cat_id'] ?? 0}') ?? 0;
    if (catId == 0 && _cats.isNotEmpty) {
      catId = int.tryParse('${_cats.first['id']}') ?? 0;
    }
    int needAd = int.tryParse('${x?['need_ad'] ?? 0}') ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => StatefulBuilder(builder: (c, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(c).viewInsets.bottom + 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(x == null ? '新增工具' : '编辑工具',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _field('工具名', title, '如：计算器'),
                _field('副标题', subtitle, '如：科学计算'),
                _field('图标（emoji）', icon, '如：🔢'),
                _field('路由标识 route', route, '如：calculator（内置工具必填）'),
                _field('外链 target', target, 'http://...（外链工具填）'),
                _field('接口地址 api_url', apiUrl, '联网工具数据源，支持 {q}/{page} 占位符；后台可随时改'),
                _field('排序权重', weigh, '越大越靠前', number: true),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: catId == 0 ? null : catId,
                  decoration: const InputDecoration(
                      labelText: '所属分类', isDense: true),
                  items: _cats
                      .map((e) => DropdownMenuItem(
                            value: int.tryParse('${e['id']}') ?? 0,
                            child: Text('${e['title']}'),
                          ))
                      .toList(),
                  onChanged: (v) => catId = v ?? 0,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('使用需看广告', style: TextStyle(fontSize: 14)),
                  value: needAd == 1,
                  activeThumbColor: C.brand,
                  onChanged: (v) => setSheet(() => needAd = v ? 1 : 0),
                ),
                const SizedBox(height: 12),
                _saveBtn(() async {
                  if (title.text.trim().isEmpty) {
                    ToastUtil.error('请填写工具名');
                    return;
                  }
                  await _svc.saveJzsTool({
                    if (x != null) 'id': x['id'],
                    'cat_id': catId,
                    'title': title.text.trim(),
                    'subtitle': subtitle.text.trim(),
                    'icon': icon.text.trim(),
                    'route': route.text.trim(),
                    'target': target.text.trim(),
                    'api_url': apiUrl.text.trim(),
                    'weigh': int.tryParse(weigh.text) ?? 0,
                    'need_ad': needAd,
                    'kind': target.text.trim().isEmpty ? 'local' : 'link',
                    'enable_switch': 1,
                  });
                }),
              ],
            ),
          ),
        );
      }),
    );
    _load();
  }

  Future<void> _editBanner(Map<String, dynamic>? x) async {
    final title = TextEditingController(text: '${x?['title'] ?? ''}');
    final subtitle = TextEditingController(text: '${x?['subtitle'] ?? ''}');
    final image = TextEditingController(text: '${x?['image'] ?? ''}');
    final link = TextEditingController(text: '${x?['link'] ?? ''}');
    final weigh = TextEditingController(text: '${x?['weigh'] ?? 0}');
    await _sheet('横幅', [
      _field('标题', title, '如：简助手工具箱'),
      _field('副标题', subtitle, '如：免费的多功能工具箱'),
      _field('图片地址', image, 'https://...'),
      _field('跳转链接/群号', link, 'http://... 或 QQ群号'),
      _field('排序权重', weigh, '越大越靠前', number: true),
    ], () async {
      await _svc.saveJzsBanner({
        if (x != null) 'id': x['id'],
        'scene': 'home',
        'title': title.text.trim(),
        'subtitle': subtitle.text.trim(),
        'image': image.text.trim(),
        'type': link.text.trim().startsWith('http') ? '网址' : '群聊',
        'link': link.text.trim(),
        'weigh': int.tryParse(weigh.text) ?? 0,
        'enable_switch': 1,
      });
    });
  }

  Future<void> _sheet(String label, List<Widget> fields,
      Future<void> Function() onSave) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(c).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('编辑$label',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              ...fields,
              const SizedBox(height: 12),
              _saveBtn(onSave),
            ],
          ),
        ),
      ),
    );
    _load();
  }

  Widget _field(String label, TextEditingController c, String hint,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(R.md)),
        ),
      ),
    );
  }

  Widget _saveBtn(Future<void> Function() onSave) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: C.brand,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(R.full)),
        ),
        onPressed: () async {
          try {
            await onSave();
            if (!mounted) return;
            Navigator.pop(context);
            ToastUtil.success('已保存');
            _load();
          } catch (e) {
            ToastUtil.error('$e');
          }
        },
        child: const Text('保存',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
