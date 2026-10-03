import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/ui.dart';
import '../../../models/app_cat.dart';
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
  bool _hasMore = true;
  int _page = 1;
  static const _size = 15;
  String _kw = '';

  @override
  void initState() {
    super.initState();
    _loadCats();
    _load(reset: true);
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
    if (reset) {
      _page = 1;
      _hasMore = true;
      setState(() => _loading = true);
    }
    try {
      final all = await _svc.fetchApps(catId: _cat, keyword: _kw);
      final start = (_page - 1) * _size;
      final slice = start >= all.length
          ? <AppItem>[]
          : all.sublist(start, (start + _size).clamp(0, all.length));
      if (!mounted) return;
      setState(() {
        if (reset) {
          _apps = slice;
        } else {
          _apps.addAll(slice);
        }
        _hasMore = slice.length >= _size;
        if (_hasMore) _page++;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasMore = false;
      });
    }
  }

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
              child: Text(
                c.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                  color: sel ? Colors.white : context.t2,
                ),
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
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
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
        itemCount: _apps.length,
        itemBuilder: (context, i) => _card(_apps[i]),
      ),
    );
  }

  // ───── 卡片 ─────
  Widget _card(AppItem a) {
    final vip = a.isVipItem;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 6, context.pagePadding, 6),
      child: Deco.glass(
        context,
        radius: R.lg,
        alpha: 0.07,
        onTap: () => Get.toNamed(Routes.appDetails,
            arguments: {'appId': a.id.toString(), 'item': a}),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 图标
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.md + 2),
                boxShadow: [
                  BoxShadow(
                    color: C.brand.withAlpha(context.isDark ? 50 : 30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.md + 2),
                child: a.icon.isEmpty
                    ? _ph()
                    : CachedNetworkImage(
                        imageUrl: a.icon,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ph(),
                        errorWidget: (_, __, ___) => _ph(),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.title.isEmpty ? '未知应用' : a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Ty.h3.copyWith(color: context.t1, fontSize: 15.5),
                        ),
                      ),
                      if (a.version.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? Colors.white.withAlpha(18)
                                : const Color(0xFFF1F3F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            a.version,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.t3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  // 标签行
                  Row(
                    children: [
                      _pill(vip ? '会员' : '免费', vip ? C.amber : C.mint),
                      const SizedBox(width: 5),
                      _pill('亲测可用', C.brandBright),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 元信息行
                  Row(
                    children: [
                      if (a.scoreCount > 0) ...[
                        const Icon(Icons.star_rounded, size: 13, color: C.amber),
                        const SizedBox(width: 3),
                        Text(a.scoreAvg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: C.amber)),
                        Text('(${a.scoreCount})',
                            style: TextStyle(fontSize: 10.5, color: context.t3)),
                        const SizedBox(width: 9),
                      ],
                      if (a.size.isNotEmpty) ...[
                        _meta(Icons.sd_storage_rounded, a.size),
                        const SizedBox(width: 9),
                      ],
                      _meta(Icons.visibility_rounded, '${a.views}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // 箭头
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: Deco.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: C.brand.withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.white),
            ),
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
