import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../design/adaptive.dart';
import '../../../design/ui.dart';
import '../../../models/app_cat.dart';
import '../../../models/app_item.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/tab_bottom_pad.dart';

/// 软件列表 —— 沉浸式布局（顶部大标题 + 悬浮分类胶囊 + 玻璃卡片）
class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  State<AppComponent> createState() => _AppComponentState();
}

class _AppComponentState extends State<AppComponent> {
  final _svc = SoftService.instance;
  final _scroll = ScrollController();

  List<AppCat> _cats = [];
  List<AppItem> _apps = [];
  int _cat = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _size = 15;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 260 &&
          !_loadingMore &&
          _hasMore) {
        _load();
      }
    });
    _loadCats();
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
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
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final all = await _svc.fetchApps(catId: _cat);
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

  void _switch(int id) {
    if (_cat == id) return;
    setState(() {
      _cat = id;
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
                _title(),
                _catBar(),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 14, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('软件库', style: Ty.display.copyWith(color: context.t1)),
                const SizedBox(height: 5),
                Text('为你精选 · 综合软件合集',
                    style: Ty.small.copyWith(color: context.t3)),
              ],
            ),
          ),
          _icon(Icons.search_rounded, () => Get.toNamed(Routes.appSearch)),
          _icon(Icons.download_rounded, () => Get.toNamed(Routes.appDownload)),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _icon(IconData i, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: context.isDark ? Colors.white.withAlpha(12) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(8),
            ),
          ),
          child: Icon(i, size: 19, color: context.t2),
        ),
      );

  Widget _catBar() {
    if (_cats.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(
          context.pagePadding, 12, context.pagePadding, 8),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _cats[i];
          final sel = _cat == c.id;
          return GestureDetector(
            onTap: () => _switch(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: sel ? Deco.brandGradient : null,
                color: sel
                    ? null
                    : (context.isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.white),
                borderRadius: BorderRadius.circular(R.full),
                border: Border.all(
                  color: sel
                      ? Colors.transparent
                      : (context.isDark
                          ? Colors.white.withAlpha(18)
                          : Colors.black.withAlpha(8)),
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: C.brand.withAlpha(70),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
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
            Text('该分类暂无软件',
                style: Ty.small.copyWith(color: context.t3)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
            top: 6, bottom: tabBottomPadding(context) + 10),
        itemCount: _apps.length + 1,
        itemBuilder: (context, i) {
          if (i == _apps.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            return const SizedBox(height: 12);
          }
          return _card(_apps[i]);
        },
      ),
    );
  }

  // ───────── 软件卡片（玻璃 + 渐变图标 + 光晕） ─────────
  Widget _card(AppItem a) {
    final vip = a.isVipItem;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding, 6, context.pagePadding, 6),
      child: Deco.glass(
        context,
        radius: R.lg,
        alpha: 0.055,
        onTap: () => Get.toNamed(Routes.appDetails,
            arguments: {'appId': a.id.toString(), 'item': a}),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标（带光晕）
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.md + 2),
                boxShadow: [
                  BoxShadow(
                    color: C.brand.withAlpha(context.isDark ? 55 : 34),
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
                        width: 58,
                        height: 58,
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
                  Text(
                    a.title.isEmpty ? '未知应用' : a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.h3.copyWith(color: context.t1),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _pill(
                        vip ? '会员' : '免费',
                        vip ? C.amber : C.mint,
                      ),
                      const SizedBox(width: 5),
                      _pill('人工亲测', C.brandBright),
                      if (a.version.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(a.version,
                            style:
                                Ty.tiny.copyWith(color: context.t3)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (a.scoreCount > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 13, color: C.amber),
                        const SizedBox(width: 3),
                        Text(a.scoreAvg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: C.amber)),
                        const SizedBox(width: 10),
                      ],
                      if (a.size.isNotEmpty)
                        _meta(Icons.sd_storage_rounded, a.size),
                      const SizedBox(width: 10),
                      _meta(Icons.visibility_rounded, '${a.views}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 箭头按钮
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 34,
              height: 34,
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
                  size: 17, color: Colors.white),
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
          color: color.withAlpha(context.isDark ? 36 : 26),
          borderRadius: BorderRadius.circular(R.full),
          border: Border.all(color: color.withAlpha(70), width: 0.7),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );

  Widget _ph() => Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              C.brand.withAlpha(50),
              C.violet.withAlpha(50),
            ],
          ),
        ),
        child: const Icon(Icons.android_rounded, color: Colors.white, size: 28),
      );
}
