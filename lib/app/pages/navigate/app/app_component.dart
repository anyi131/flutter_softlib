import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/lzy_folder_parser.dart';
import '../../../api/soft_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/ui.dart';
import '../../../models/app_cat.dart';
import '../../../models/app_config.dart';
import '../../../models/app_item.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/tab_bottom_pad.dart';

/// 软件库 —— 分类 + 卡片列表（支持下拉刷新/上拉加载）
class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  State<AppComponent> createState() => _AppComponentState();
}

class _AppComponentState extends State<AppComponent> {
  final _svc = SoftService.instance;
  final _refreshCtrl = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<AppCat> _cats = [];
  List<AppItem> _apps = [];
  int _cat = 0;
  bool _loading = true;
  /// 列表正在加载更多（不遮全屏，只在底部转圈）
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _size = 15;
  String _kw = '';

  /// 数据源（后台可配）：all / local / lzy
  String _source = 'all';
  bool _folderParsing = false;
  String _folderProgress = '';

  @override
  void initState() {
    super.initState();
    _initSource();
    _loadCats();
  }

  Future<void> _initSource() async {
    // ★ 并发：配置与列表同时请求，不再串行等待（首屏快一倍）
    final results = await Future.wait([
      _svc.fetchConfig(),
      _svc.fetchApps(
        catId: _cat,
        keyword: _kw,
        provider: '', // 先用全部，配置回来后再决定是否重取
        force: false,
      ),
    ]);
    if (!mounted) return;
    final cfg = results[0] as AppConfig?;
    final list = results[1] as List<AppItem>;
    final src = cfg?.appSource ?? 'all';
    setState(() {
      _source = src;
      _apps = list;
      _loading = false;
    });
    // 若配置指定了数据源筛选，且与「全部」结果不同，再静默重取一次
    if (src != 'all') {
      await _load(reset: true);
    }
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCats() async {
    final c = await _svc.fetchCats();
    if (!mounted) return;
    setState(() => _cats = [
          AppCat(id: 0, title: '全部', count: 0),
          ...c.where((e) => e.id != 0),
        ]);
  }

  Future<void> _load({bool reset = false}) async {
    final cat = _currentCat;
    final isFolder = cat != null && cat.isFolder;
    if (reset) {
      _page = 1;
      _hasMore = true;
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final cat = _currentCat;
      // ★ 蓝奏云文件夹分类：优先用【客户端本地解析】
      //   （服务器 IP 会被蓝奏云限流只能拿 500 条，客户端可拿全部）
      List<AppItem>? folderItems;
      if (cat != null && cat.isFolder) {
        setState(() {
          _folderParsing = true;
          _folderProgress = '正在打开文件夹…';
        });
        try {
          folderItems = await LzyFolderParser.instance.parse(
            cat.url,
            pwd: cat.pwd.isEmpty ? 'password' : cat.pwd,
            onProgress: (pg, cnt) {
              if (mounted) {
                setState(() {
                  _folderProgress = '已解析 $cnt 个（第 $pg 页）';
                });
              }
            },
          );
        } catch (e) {
          // 客户端解析失败 → 退回服务端缓存/解析
          debugPrint('[Softlib] client parse failed: $e');
          folderItems = null;
        } finally {
          if (mounted) {
            setState(() {
              _folderParsing = false;
              _folderProgress = '';
            });
          }
        }
      }

      final all = (folderItems != null)
          ? folderItems
          : ((cat != null && cat.isFolder)
              ? await _svc.fetchFolder(cat.url, pwd: cat.pwd, pgs: _page)
              : await _svc.fetchApps(
              catId: _cat,
              keyword: _kw,
              provider: _source == 'all' ? '' : _source,
              force: reset,
            ));
      final isFolderMode = cat != null && cat.isFolder;
      debugPrint('[Softlib] _load: cat=${cat?.title} isFolder=$isFolderMode '
          'folderItems=${folderItems?.length} all=${all.length} page=$_page reset=$reset');
      List<AppItem> slice;
      bool hasMore;
      if (isFolderMode) {
        // ★ 文件夹模式：客户端一次性解析出全部（几百条），
        //   本地切片展示：首批 50 条，滚到底自动加载下一批，
        //   这样避免一次性渲染几百张远程图标导致卡顿。
        final src = all;
        final start = reset ? 0 : _apps.length;
        slice = start >= src.length
            ? <AppItem>[]
            : src.sublist(start, (start + _size).clamp(0, src.length));
        hasMore = (start + slice.length) < src.length;
        if (!mounted) return;
        setState(() {
          if (reset) {
            _apps = slice;
          } else {
            _apps.addAll(slice);
          }
          _hasMore = hasMore;
          _loading = false;
          _loadingMore = false;
        });
        return;
      }
      {
        final start = (_page - 1) * _size;
        slice = start >= all.length
            ? <AppItem>[]
            : all.sublist(start, (start + _size).clamp(0, all.length));
        hasMore = slice.length >= _size;
      }
      if (!mounted) return;
      setState(() {
        if (reset) {
          _apps = slice;
        } else {
          _apps.addAll(slice);
        }
        _hasMore = hasMore;
        if (hasMore) _page++;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  /// 当前分类（用于判断是否蓝奏云文件夹）
  AppCat? get _currentCat =>
      _cats.where((c) => c.id == _cat).isEmpty
          ? null
          : _cats.firstWhere((c) => c.id == _cat);

  void _switch(int id) {
    if (_cat == id) return;
    setState(() {
      _cat = id;
      _apps = [];
      _loading = true;
    });
    _load(reset: true);
  }

  /// 搜索（弹窗输入关键词）
  Future<void> _search() async {
    final ctrl = TextEditingController(text: _kw);
    final v = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg)),
        title: const Text('搜索软件',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入软件名称',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (s) => Get.back(result: s.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: ''), child: const Text('重置')),
          FilledButton(
              onPressed: () => Get.back(result: ctrl.text.trim()),
              child: const Text('搜索')),
        ],
      ),
    );
    if (v == null) return;
    setState(() {
      _kw = v;
      _apps = [];
      _loading = true;
    });
    _load(reset: true);
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
                _catBar(),
                Expanded(child: _body()),
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
      padding: EdgeInsets.fromLTRB(context.pagePadding, 14, 12, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('软件库', style: Ty.display.copyWith(color: context.t1)),
                const SizedBox(height: 5),
                Text(
                  _kw.isEmpty ? '为你精选 · 综合软件合集' : '搜索「$_kw」',
                  style: Ty.small.copyWith(color: context.t3),
                ),
              ],
            ),
          ),
          _circleBtn(
            _kw.isEmpty ? Icons.search_rounded : Icons.close_rounded,
            () {
              if (_kw.isEmpty) {
                _search();
              } else {
                setState(() {
                  _kw = '';
                  _apps = [];
                  _loading = true;
                });
                _load(reset: true);
              }
            },
          ),
          _circleBtn(Icons.download_rounded, () => Get.toNamed(Routes.appDownload)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData i, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: f,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withAlpha(14) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.isDark
                    ? Colors.white.withAlpha(22)
                    : Colors.black.withAlpha(8),
              ),
              boxShadow: context.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF2C3550).withAlpha(18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(i, size: 20, color: context.t2),
          ),
        ),
      );

  // ───── 分类 ─────
  Widget _catBar() {
    if (_cats.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(
            context.pagePadding, 14, context.pagePadding, 8),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _cats[i];
          final sel = _cat == c.id;
          return GestureDetector(
            onTap: () => _switch(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: sel ? Deco.brandGradient : null,
                color: sel
                    ? null
                    : (context.isDark ? Colors.white.withAlpha(12) : Colors.white),
                borderRadius: BorderRadius.circular(R.full),
                border: Border.all(
                  color: sel
                      ? Colors.transparent
                      : (context.isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.black.withAlpha(8)),
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: C.brand.withAlpha(72),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : (context.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF2C3550).withAlpha(14),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.isFolder)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.cloud_outlined,
                        size: 13,
                        color: sel ? Colors.white : C.cyan,
                      ),
                    ),
                  Text(
                    c.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                      color: sel ? Colors.white : context.t2,
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

  // ───── 列表 ─────
  Widget _body() {
    if (_loading) {
      final cat = _currentCat;
      final folder = cat != null && cat.isFolder;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: folder ? C.brand : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(folder ? '正在解析蓝奏云文件夹' : '加载中…',
                  style: Ty.body.copyWith(
                      color: context.t1, fontWeight: FontWeight.w700)),
              if (folder) ...[
                const SizedBox(height: 8),
                Text('文件夹较大时需要一点时间，请稍候',
                    style: Ty.tiny.copyWith(color: context.t3)),
                if (_folderProgress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: C.brand.withAlpha(context.isDark ? 34 : 20),
                      borderRadius: BorderRadius.circular(R.full),
                    ),
                    child: Text(_folderProgress,
                        style: Ty.small.copyWith(
                            color: C.brand, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }
    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: context.t3.withAlpha(90)),
            const SizedBox(height: 12),
            Text(_kw.isEmpty ? '该分类暂无软件' : '没有找到「$_kw」',
                style: Ty.small.copyWith(color: context.t3)),
          ],
        ),
      );
    }
    return EasyRefresh(
      controller: _refreshCtrl,
      header: const MaterialHeader(),
      footer: const MaterialFooter(),
      onRefresh: () async {
        await _load(reset: true);
        _refreshCtrl.finishRefresh();
      },
      onLoad: () async {
        if (!_hasMore) {
          _refreshCtrl.finishLoad(IndicatorResult.noMore);
          return;
        }
        await _load();
        _refreshCtrl.finishLoad(
            _hasMore ? IndicatorResult.success : IndicatorResult.noMore);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.only(
            top: 8, bottom: tabBottomPadding(context) + 12),
        itemCount: _apps.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _apps.length) return _loadMoreFooter();
          return _card(_apps[i]);
        },
      ),
    );
  }

  /// 底部「加载更多」指示（文件夹模式分批加载时显示）
  Widget _loadMoreFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: C.brand),
          ),
          const SizedBox(width: 10),
          Text('正在加载更多…', style: Ty.tiny.copyWith(color: context.t3)),
        ],
      ),
    );
  }

  // ───── 卡片 ─────
  Widget _card(AppItem a) {
    final vip = a.isVipItem;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 5, context.pagePadding, 5),
      child: Deco.glass(
        context,
        radius: R.lg,
        alpha: 0.075,
        onTap: () => Get.toNamed(Routes.appDetails,
            arguments: {'appId': a.id.toString(), 'item': a}),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.md),
                boxShadow: [
                  BoxShadow(
                    color: C.brand.withAlpha(context.isDark ? 45 : 26),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(R.md),
                    child: a.icon.isEmpty
                        ? _ph()
                        : CachedNetworkImage(
                            imageUrl: a.icon,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _ph(),
                            errorWidget: (_, __, ___) => _ph(),
                          ),
                  ),
                  // ★ NEW 角标（图标左上角）
                  if (a.isNew)
                    Positioned(
                      left: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFB923C)]),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withAlpha(120),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.4,
                                height: 1.1)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题 + 版本
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.title.isEmpty ? '未知应用' : a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: context.t1,
                          ),
                        ),
                      ),
                      if (a.version.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(a.version,
                            style: TextStyle(
                                fontSize: 10.5, color: context.t3)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 一行装完：会员/免费 + 评分 + 大小
                  Row(
                    children: [
                      _pill(vip ? '会员' : '免费', vip ? C.amber : C.mint),
                      const SizedBox(width: 7),
                      if (a.scoreCount > 0) ...[
                        const Icon(Icons.star_rounded, size: 12, color: C.amber),
                        const SizedBox(width: 2),
                        Text(a.scoreAvg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: C.amber)),
                        const SizedBox(width: 8),
                      ],
                      if (a.size.isNotEmpty)
                        Text(a.size,
                            style: TextStyle(
                                fontSize: 11, color: context.t3)),
                    ],
                  ),
                  if (a.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      a.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: context.t3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: context.t3),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData i, String t) {
    if (t.isEmpty || t == '0') return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 12, color: context.t3),
        const SizedBox(width: 3),
        Text(t, style: Ty.tiny.copyWith(color: context.t3)),
      ],
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: color.withAlpha(context.isDark ? 36 : 24),
          borderRadius: BorderRadius.circular(R.full),
          border: Border.all(color: color.withAlpha(70), width: 0.7),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );

  Widget _ph() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [C.brand.withAlpha(50), C.violet.withAlpha(50)],
          ),
        ),
        child: const Icon(Icons.android_rounded, color: Colors.white, size: 28),
      );
}
