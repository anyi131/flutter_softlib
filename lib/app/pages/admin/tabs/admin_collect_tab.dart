import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';

/// 后台 · 采集（版权梦）
///
/// 流程：列出采集平台的软件 → 勾选 → 开始采集
///       → 平台把软件上传到「你自己的蓝奏云」
///       → 完成后拿到蓝奏云链接 → 一键导入你的软件库
class AdminCollectTab extends StatefulWidget {
  const AdminCollectTab({super.key});

  @override
  State<AdminCollectTab> createState() => _AdminCollectTabState();
}

class _AdminCollectTabState extends State<AdminCollectTab>
    with AutomaticKeepAliveClientMixin {
  final _svc = AdminService.instance;
  final _kwCtrl = TextEditingController();

  bool _loading = true;
  bool _loggedIn = false;
  int _page = 1;
  int _totalPages = 1;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _selected = {};

  // 采集任务
  String _taskId = '';
  bool _running = false;
  int _cur = 0, _total = 0, _ok = 0, _fail = 0;
  String _status = '';
  List<Map<String, dynamic>> _results = [];
  List<String> _logs = [];
  Timer? _poll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _kwCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final cfg = await _svc.collectConfig();
      if (!mounted) return;
      setState(() {
        _loggedIn = cfg['logged_in'] == true || cfg['logged_in'] == 1;
        _totalPages = (cfg['total_pages'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
      if (_loggedIn) await _load();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _svc.collectList(
          page: _page, keyword: _kwCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _items = ((r['items'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _totalPages = (r['total_pages'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _items.isEmpty) {
      return const LoadingState(text: '加载采集数据…');
    }
    if (!_loggedIn) return _needCookie();
    return Column(
      children: [
        _toolbar(),
        if (_running || _results.isNotEmpty) _progressCard(),
        Expanded(child: _list()),
      ],
    );
  }

  /// 未登录：引导粘贴 Cookie
  Widget _needCookie() {
    final ctrl = TextEditingController();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: KitCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link_rounded, color: C.warning, size: 20),
                  const SizedBox(width: 8),
                  Text('需要配置采集平台登录态',
                      style: Ty.h3.copyWith(color: context.t1)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '采集平台（版权梦）登录需要图形验证码，请：\n'
                '1. 在浏览器登录 app.125ks.cn\n'
                '2. 按 F12 → Network → 任意请求 → 复制 Cookie\n'
                '3. 粘贴到下面（需含 PHPSESSID）',
                style: Ty.small.copyWith(color: context.t2, height: 1.6),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'PHPSESSID=xxx; ol_token=xxx; ...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.md)),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: '保存并验证',
                icon: Icons.check_circle_rounded,
                height: 46,
                onPressed: () async {
                  final v = ctrl.text.trim();
                  if (v.isEmpty) {
                    ToastUtil.info('请粘贴 Cookie');
                    return;
                  }
                  try {
                    final ok = await _svc.saveCollectCookie(v);
                    if (ok) {
                      ToastUtil.success('登录成功，可以采集了');
                      _init();
                    } else {
                      ToastUtil.error('Cookie 无效或已过期');
                    }
                  } catch (e) {
                    ToastUtil.error(
                        e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 10, context.pagePadding, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kwCtrl,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: '搜索软件名称…',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.full)),
                  ),
                  onSubmitted: (_) {
                    _page = 1;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SoftButton(
                label: '搜索',
                height: 42,
                onPressed: () {
                  _page = 1;
                  _load();
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _init,
                icon: Icon(Icons.refresh_rounded, color: context.t2, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('第 $_page / $_totalPages 页 · 共 ${_items.length} 条',
                  style: Ty.tiny.copyWith(color: context.t3)),
              const Spacer(),
              if (_selected.isNotEmpty) ...[
                Text('已选 ${_selected.length}',
                    style: Ty.tiny.copyWith(color: C.brand)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(_selected.clear),
                  child: Text('清空',
                      style: Ty.tiny.copyWith(color: C.danger)),
                ),
                const SizedBox(width: 10),
              ],
              GestureDetector(
                onTap: _selectAllMatched,
                child: Text('全选本页',
                    style: Ty.tiny.copyWith(
                        color: C.brand, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectAllMatched() {
    setState(() {
      for (final it in _items) {
        if (it['matched'] == true) {
          _selected.add((it['appid'] ?? '').toString());
        }
      }
    });
  }

  Widget _list() {
    if (_items.isEmpty) {
      return EmptyState(
        text: '没有采集到数据',
        hint: '可能是 Cookie 已过期，请重新获取',
        icon: Icons.cloud_download_outlined,
        action: SoftButton(label: '重新检测', onPressed: _init),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
                context.pagePadding, 4, context.pagePadding, 12),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _itemCard(_items[i]),
          ),
        ),
        _pager(),
        _bottomBar(),
      ],
    );
  }

  Widget _itemCard(Map<String, dynamic> it) {
    final appid = (it['appid'] ?? '').toString();
    final matched = it['matched'] == true;
    final sel = _selected.contains(appid);
    return KitCard(
      radius: R.md,
      padding: const EdgeInsets.all(11),
      onTap: matched
          ? () => setState(() {
                if (sel) {
                  _selected.remove(appid);
                } else {
                  _selected.add(appid);
                }
              })
          : () => ToastUtil.info('该软件未匹配到蓝奏云目录，无法采集'),
      child: Row(
        children: [
          Opacity(
            opacity: matched ? 1 : 0.4,
            child: Icon(
              sel
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: sel ? C.brand : context.t3,
            ),
          ),
          const SizedBox(width: 10),
          AppImage(
            url: (it['logo'] ?? '').toString(),
            width: 42,
            height: 42,
            radius: R.sm,
            placeholderIcon: Icons.android,
            errorIcon: Icons.android,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((it['name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.h3.copyWith(fontSize: 14, color: context.t1)),
                const SizedBox(height: 4),
                Text(
                  'v${it['version'] ?? ''} · ${it['size'] ?? ''} · ${it['category'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ty.tiny.copyWith(color: context.t3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            matched ? ((it['config_name'] ?? '').toString()) : '未匹配',
            color: matched ? C.mint : C.warning,
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _pager() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SoftButton(
            label: '上一页',
            height: 36,
            color: _page > 1 ? C.brand : context.t3,
            onPressed: _page > 1
                ? () {
                    _page--;
                    _load();
                  }
                : () {},
          ),
          const SizedBox(width: 14),
          Text('$_page / $_totalPages',
              style: Ty.small.copyWith(color: context.t2)),
          const SizedBox(width: 14),
          SoftButton(
            label: '下一页',
            height: 36,
            color: _page < _totalPages ? C.brand : context.t3,
            onPressed: _page < _totalPages
                ? () {
                    _page++;
                    _load();
                  }
                : () {},
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.pagePadding, 6, context.pagePadding, 10),
        child: PrimaryButton(
          label: _selected.isEmpty
              ? '请选择要采集的软件'
              : '开始采集（${_selected.length}）',
          icon: Icons.cloud_upload_rounded,
          height: 48,
          enabled: _selected.isNotEmpty && !_running,
          onPressed: _start,
        ),
      ),
    );
  }

  Future<void> _start() async {
    final apps = _items
        .where((it) => _selected.contains((it['appid'] ?? '').toString()))
        .map((it) => {
              'appid': it['appid'],
              'appname': it['name'],
              'config_id': it['config_id'],
              'dir_id': it['dir_id'],
              'config_name': it['config_name'],
              'is_fallback': it['is_fallback'],
            })
        .toList();
    if (apps.isEmpty) return;
    final go = await Get.dialog<bool>(AlertDialog(
      title: const Text('开始采集'),
      content: Text('将把选中的 ${apps.length} 个软件上传到【你自己的蓝奏云】目录，'
          '完成后可一键导入软件库。\n\n是否继续？'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false), child: const Text('取消')),
        FilledButton(
            onPressed: () => Get.back(result: true), child: const Text('开始')),
      ],
    ));
    if (go != true) return;
    try {
      final taskId = await _svc.collectStart(apps);
      if (taskId.isEmpty) {
        ToastUtil.error('任务提交失败');
        return;
      }
      setState(() {
        _taskId = taskId;
        _running = true;
        _cur = 0;
        _total = apps.length;
        _ok = 0;
        _fail = 0;
        _status = '';
        _results = [];
        _logs = [];
      });
      _startPoll();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (_taskId.isEmpty) {
        t.cancel();
        return;
      }
      try {
        final r = await _svc.collectStatus(_taskId);
        if (!mounted) return;
        setState(() {
          _status = (r['status'] ?? '').toString();
          _total = (r['total'] as num?)?.toInt() ?? _total;
          _cur = (r['current'] as num?)?.toInt() ?? _cur;
          _ok = (r['success'] as num?)?.toInt() ?? _ok;
          _fail = (r['fail'] as num?)?.toInt() ?? _fail;
          _results = ((r['results'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _logs = ((r['logs'] as List?) ?? [])
              .map((e) => e.toString())
              .toList();
        });
        if (_status == 'done') {
          t.cancel();
          setState(() => _running = false);
          ToastUtil.success('采集完成：成功 $_ok，失败 $_fail');
        }
      } catch (e) {
        // 单次查询失败不中断
      }
    });
  }

  Widget _progressCard() {
    final pct = _total > 0 ? (_cur / _total).clamp(0.0, 1.0) : 0.0;
    final doneLinks = _results.where((r) => r['ok'] == true).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 4, context.pagePadding, 4),
      child: KitCard(
        radius: R.md,
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _running
                      ? Icons.cloud_upload_rounded
                      : Icons.check_circle_rounded,
                  size: 17,
                  color: _running ? C.brand : C.success,
                ),
                const SizedBox(width: 7),
                Text(
                  _running ? '正在上传到你的蓝奏云…' : '采集完成',
                  style: Ty.h3.copyWith(fontSize: 13.5, color: context.t1),
                ),
                const Spacer(),
                Text('$_cur/$_total',
                    style: Ty.small.copyWith(color: context.t2)),
              ],
            ),
            const SizedBox(height: 8),
            KitProgress(value: pct, color: _running ? C.brand : C.success),
            const SizedBox(height: 6),
            Text('成功 $_ok · 失败 $_fail',
                style: Ty.tiny.copyWith(color: context.t3)),
            if (doneLinks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('已生成蓝奏云链接：',
                  style: Ty.tiny.copyWith(
                      color: context.t2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...doneLinks.take(5).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${r['name']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Ty.tiny.copyWith(color: context.t1),
                          ),
                        ),
                        Text('已生成',
                            style: Ty.tiny.copyWith(color: C.success)),
                      ],
                    ),
                  )),
              const SizedBox(height: 10),
              PrimaryButton(
                label: '导入软件库（${doneLinks.length}）',
                icon: Icons.download_done_rounded,
                height: 42,
                onPressed: () => _import(doneLinks),
              ),
            ],
            if (!_running && _logs.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? Colors.black26
                        : Colors.black.withAlpha(6),
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: ListView(
                    children: _logs
                        .map((l) => Text(
                              l.replaceAll(RegExp(r'\|URL:.*$'), ''),
                              style: Ty.tiny.copyWith(color: context.t3),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _import(List<Map<String, dynamic>> results) async {
    final items = results
        .map((r) => {
              'name': r['name'],
              'url': r['url'],
              'desc': r['desc'],
              'category': r['category'],
            })
        .toList();
    if (items.isEmpty) return;
    try {
      final r = await _svc.collectImport(items);
      ToastUtil.success(
          '已导入 ${r['added']} 条，跳过重复 ${r['skipped']} 条');
      setState(() {
        _results = [];
        _logs = [];
      });
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
