import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../utils/toast_util.dart';
import 'collect_account_card.dart';
import 'collect_dirs_view.dart';
import 'collect_logs_view.dart';
import 'collect_lzy_account_view.dart';

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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _svc = AdminService.instance;
  final _kwCtrl = TextEditingController();
  late final TabController _sub = TabController(length: 4, vsync: this);

  /// 子页：0=采集 1=目录 2=日志 3=蓝奏云账号
  int get _subIndex => _sub.index;

  bool _loading = true;
  bool _loggedIn = false;
  String _user = '';
  int _page = 1;
  int _totalPages = 1;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _selected = {};

  // 采集任务
  String _taskId = '';
  bool _running = false;
  int _cur = 0, _total = 0, _ok = 0, _fail = 0;
  String _status = '';
  String _err = '';
  int _taskAt = 0;
  List<String> _pendingNames = [];
  List<Map<String, dynamic>> _results = [];
  List<String> _logs = [];
  Timer? _poll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sub.addListener(() => setState(() {}));
    _init();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _sub.dispose();
    _kwCtrl.dispose();
    super.dispose();
  }

  /// 把原始异常翻成人话（500 这类要给出可操作的建议）
  String _friendly(Object e) {
    final s = e.toString().replaceFirst('Exception: ', '');
    if (s.contains('500')) {
      return '服务器处理出错。可尝试：①点击「重新检测」②退出后重新登录采集账号';
    }
    if (s.contains('登录') || s.contains('Cookie')) return s;
    if (s.contains('timeout') || s.contains('超时')) return '网络超时，请重试';
    return s;
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _err = '';
    });
    try {
      final cfg = await _svc.collectConfig();
      if (!mounted) return;
      setState(() {
        _loggedIn = cfg['logged_in'] == true || cfg['logged_in'] == 1;
        _totalPages = (cfg['total_pages'] as num?)?.toInt() ?? 1;
        _user = (cfg['collect_user'] ?? '').toString();
        _loading = false;
      });
      if (_loggedIn) await _load();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(_friendly(e));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = '';
    });
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
      setState(() {
        _loading = false;
        // 列表拉取失败不再吞掉、也不再误报「Cookie 过期」
        _err = _friendly(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _items.isEmpty && !_loggedIn) {
      return const LoadingState(text: '加载采集数据…');
    }
    if (!_loggedIn) return _needCookie();
    return Column(
      children: [
        _subBar(),
        Expanded(
          child: IndexedStack(
            index: _subIndex,
            children: [
              _collectPane(),
              const CollectDirsView(),
              const CollectLogsView(),
              const CollectLzyAccountView(),
            ],
          ),
        ),
      ],
    );
  }

  /// 子页切换（分段控件）
  Widget _subBar() {
    const items = ['采集', '目录', '日志', '蓝奏云'];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 10, context.pagePadding, 6),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: context.isDark ? Colors.white.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(R.full),
          border: Border.all(color: C.stroke),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: List.generate(items.length, (i) {
            final sel = _subIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _sub.animateTo(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: sel ? Deco.brandGradient : null,
                    borderRadius: BorderRadius.circular(R.full),
                  ),
                  child: Text(
                    items[i],
                    style: Ty.tiny.copyWith(
                      fontSize: 12.5,
                      color: sel ? Colors.white : context.t2,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 采集子页
  Widget _collectPane() {
    return Column(
      children: [
        _toolbar(),
        if (_running || _results.isNotEmpty) _progressCard(),
        Expanded(child: _list()),
      ],
    );
  }

  /// 未登录：引导配置采集账号（账号密码自动登录优先，Cookie 兜底）
  Widget _needCookie() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectAccountCard(
            loggedIn: false,
            totalPages: _totalPages,
            onChanged: _init,
          ),
          const SizedBox(height: 12),
          KitCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: C.brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '登录后即可浏览采集平台的软件列表，勾选后一键上传到'
                    '「你自己的蓝奏云」，再把生成的链接导入软件库。',
                    style: Ty.tiny.copyWith(color: context.t3, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    if (_err.isNotEmpty) {
      return ErrorState(
        text: '采集数据加载失败',
        hint: _err,
        onRetry: _load,
      );
    }
    if (_items.isEmpty) {
      return EmptyState(
        text: '没有采集到数据',
        hint: '可能是 Cookie 已过期，请重新登录采集账号',
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
            itemCount: _items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              // 列表头：采集账号入口（点开可改账号/重新登录）
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _accountEntry(),
                );
              }
              return _itemCard(_items[i - 1]);
            },
          ),
        ),
        _pager(),
        _bottomBar(),
      ],
    );
  }

  /// 已登录时的账号入口条（收起状态，点开抽屉里的完整设置）
  Widget _accountEntry() {
    return KitCard(
      radius: R.md,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: _showAccountSheet,
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 17, color: C.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _user.isEmpty ? '采集账号已登录' : '采集账号：$_user',
              style: Ty.tiny.copyWith(color: context.t2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('账号设置',
              style: Ty.tiny.copyWith(
                  color: C.brand, fontWeight: FontWeight.w800)),
          Icon(Icons.chevron_right_rounded, size: 16, color: C.brand),
        ],
      ),
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.isDark ? C.bg2 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(R.lg)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('采集账号设置', style: Ty.h3.copyWith(color: ctx.t1)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: ctx.t2),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CollectAccountCard(
                loggedIn: _loggedIn,
                totalPages: _totalPages,
                onChanged: () {
                  Navigator.pop(ctx);
                  _init();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
        // 记录本次要采集的软件名（完成后到日志页反查链接用）
        _pendingNames =
            apps.map((a) => '${a['appname'] ?? ''}').where((s) => s.isNotEmpty).toList();
      });
      _startPoll();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _startPoll() {
    _poll?.cancel();
    _taskAt = DateTime.now().millisecondsSinceEpoch;
    int expiredTicks = 0;

    _poll = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (_taskId.isEmpty) {
        t.cancel();
        return;
      }
      try {
        final r = await _svc.collectStatus(_taskId);
        if (!mounted) return;

        // 任务记录已被站点清理（任务早已结束）
        if (r['expired'] == true) {
          expiredTicks++;
          if (expiredTicks >= 2 || !_running) {
            t.cancel();
            await _finishFromLog();
          }
          return;
        }
        expiredTicks = 0;

        setState(() {
          _status = (r['status'] ?? '').toString();
          _total = (r['total'] as num?)?.toInt() ?? _total;
          _cur = (r['current'] as num?)?.toInt() ?? _cur;
          _ok = (r['success'] as num?)?.toInt() ?? _ok;
          _fail = (r['fail'] as num?)?.toInt() ?? _fail;
          _results = ((r['results'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          // ★ 站点每 2 秒返回真实进度日志，直接展示，用户能实时看到在干什么
          _logs = ((r['logs'] as List?) ?? [])
              .map((e) => e.toString())
              .toList();
        });

        // 进度满了就说明该完成的都完成了（站点可能稍后才给 done）
        if (_status == 'done' || (_results.isNotEmpty && _cur >= _total && _total > 0)) {
          t.cancel();
          await _finishFromLog();
        }
      } catch (e) {
        // 单次查询失败不中断，继续轮询
      }
    });
  }

  /// ★ 任务结束后从站点「采集日志」按软件名反查蓝奏云链接
  ///   （站点 task_status 不返回已完成任务的 results，这是唯一可靠的取法）
  Future<void> _finishFromLog() async {
    final names = _pendingNames.isNotEmpty
        ? _pendingNames
        : _results.map((r) => '${r['name']}').toList();
    try {
      final r = await _svc.collectResults(names, at: _taskAt);
      if (!mounted) return;
      final list = ((r['results'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _running = false;
        _status = 'done';
        if (list.isNotEmpty) {
          _results = list;
          _ok = list.where((x) => x['ok'] == true).length;
          _fail = list.length - _ok;
          _cur = list.length;
          _total = list.length;
        } else {
          _cur = _total;
          _ok = 0;
          _fail = _total;
        }
      });
      if (_ok > 0) {
        ToastUtil.success('采集完成：成功 $_ok，失败 $_fail');
      } else {
        ToastUtil.info('任务已结束，但未在站点日志中找到链接');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _status = 'done';
        _cur = _total;
      });
      ToastUtil.info('任务已提交完成，请到「日志」页查看结果链接');
    }
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
                if (_running)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.check_circle_rounded,
                      size: 17, color: C.success),
                const SizedBox(width: 8),
                Text(
                  _running ? '正在上传到你的蓝奏云…' : '采集结束',
                  style: Ty.h3.copyWith(fontSize: 13.5, color: context.t1),
                ),
                const Spacer(),
                Text('$_cur/$_total',
                    style: Ty.small.copyWith(color: context.t2)),
              ],
            ),
            const SizedBox(height: 9),
            KitProgress(value: pct, color: _running ? C.brand : C.success),
            const SizedBox(height: 7),
            Row(
              children: [
                _miniStat('成功', _ok, C.success),
                const SizedBox(width: 14),
                _miniStat('失败', _fail, C.danger),
                const SizedBox(width: 14),
                _miniStat('总数', _total, C.brand),
                const Spacer(),
                if (_running)
                  GestureDetector(
                    onTap: _finishFromLog,
                    child: Text('立即取结果',
                        style: Ty.tiny.copyWith(
                            color: C.brand, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            // ★ 站点每 2 秒返回的真实进度日志 —— 直接展示，用户能看到在干什么
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 13, color: context.t3),
                  const SizedBox(width: 5),
                  Text('实时日志',
                      style: Ty.tiny.copyWith(
                          color: context.t2, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                height: 116,
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: context.isDark ? Colors.black38 : const Color(0xFF10131C),
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: ListView(
                  reverse: true,
                  children: _logs
                      .map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              l,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.5,
                                fontFamily: 'monospace',
                                color: Color(0xFF9FE8B5),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            if (doneLinks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('已生成蓝奏云链接（${doneLinks.length}）',
                  style: Ty.tiny.copyWith(
                      color: context.t2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...doneLinks.take(8).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 13, color: C.success),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${r['name']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Ty.tiny.copyWith(color: context.t1),
                          ),
                        ),
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
            if (!_running && _logs.isEmpty && doneLinks.isEmpty) ...[
              const SizedBox(height: 8),
              Text('任务已结束，可到「日志」子页查看结果链接。',
                  style: Ty.tiny.copyWith(color: context.t3)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int v, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$v',
              style: Ty.small
                  .copyWith(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 3),
          Text(label, style: Ty.tiny.copyWith(fontSize: 10.5, color: context.t3)),
        ],
      );

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
