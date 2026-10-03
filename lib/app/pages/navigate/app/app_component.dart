import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../models/app_cat.dart';
import '../../../models/app_item.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/tab_bottom_pad.dart';

/// 软件 - 综合类软件大合集
class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  State<AppComponent> createState() => _AppComponentState();
}

class _AppComponentState extends State<AppComponent> {
  final SoftService _service = SoftService.instance;
  final ScrollController _scroll = ScrollController();

  static const Color kBrand = Color(0xFF465CFF);
  static const Color kVip = Color(0xFFC9A227);

  List<AppCat> _cats = [];
  List<AppItem> _apps = [];
  int _currentCat = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadCats();
    _loadApps(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 260 &&
        !_loadingMore &&
        _hasMore) {
      _loadApps();
    }
  }

  Future<void> _loadCats() async {
    final cats = await _service.fetchCats();
    if (!mounted) return;
    setState(() {
      _cats = [
        AppCat(id: 0, title: '全部资源', count: 0),
        ...cats.where((c) => c.id != 0),
      ];
    });
  }

  Future<void> _loadApps({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      setState(() => _loading = true);
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final all = await _service.fetchApps(catId: _currentCat);
      final start = (_page - 1) * _pageSize;
      final slice = start >= all.length
          ? <AppItem>[]
          : all.sublist(start, (start + _pageSize).clamp(0, all.length));
      if (!mounted) return;
      setState(() {
        if (reset) {
          _apps = slice;
        } else {
          _apps.addAll(slice);
        }
        _hasMore = slice.length >= _pageSize;
        if (_hasMore) _page++;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  void _switchCat(int id) {
    if (_currentCat == id) return;
    setState(() {
      _currentCat = id;
      _apps = [];
    });
    _loadApps(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF1F2F6);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(isDark),
            _catBar(isDark),
            Expanded(child: _list(isDark)),
          ],
        ),
      ),
    );
  }

  // ===== 顶部标题 =====
  Widget _topBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('软件',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                SizedBox(height: 2),
                Text('综合类软件大合集',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey)),
              ],
            ),
          ),
          _circleBtn(Icons.search_rounded,
              () => Get.toNamed(Routes.appSearch)),
          _circleBtn(Icons.download_rounded,
              () => Get.toNamed(Routes.appDownload)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF262626)
                : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
        ),
      ),
    );
  }

  // ===== 分类胶囊条 =====
  Widget _catBar(bool isDark) {
    if (_cats.isEmpty) return const SizedBox(height: 10);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _cats[i];
          final selected = _currentCat == cat.id;
          return GestureDetector(
            onTap: () => _switchCat(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF5B6EFF), Color(0xFF465CFF)])
                    : null,
                color: selected
                    ? null
                    : (isDark ? const Color(0xFF242424) : Colors.white),
                borderRadius: BorderRadius.circular(19),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: kBrand.withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                cat.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== 列表 =====
  Widget _list(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 58, color: Colors.grey.withAlpha(95)),
            const SizedBox(height: 12),
            Text('该分类暂无软件',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadApps(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.only(top: 2, bottom: tabBottomPadding(context)),
        itemCount: _apps.length + 1,
        itemBuilder: (context, index) {
          if (index == _apps.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }
            if (!_hasMore && _apps.length > _pageSize) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('已经到底啦',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ),
              );
            }
            return const SizedBox(height: 10);
          }
          return _card(_apps[index], isDark);
        },
      ),
    );
  }

  // ===== 软件卡片 =====
  Widget _card(AppItem item, bool isDark) {
    final isVipItem = item.isVipItem;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(Routes.appDetails, arguments: {
            'appId': item.id.toString(),
            'item': item,
          }),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kBrand.withAlpha(isDark ? 40 : 26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: item.icon.isEmpty
                        ? _ph()
                        : CachedNetworkImage(
                            imageUrl: item.icon,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _ph(),
                            errorWidget: (_, __, ___) => _ph(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? '未知应用' : item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _tag(
                            isVipItem ? '会员' : '免费',
                            isVipItem ? kVip : const Color(0xFF0E9F6E),
                            isVipItem
                                ? const Color(0xFFFFF4D6)
                                : const Color(0xFFE3F9F0),
                          ),
                          const SizedBox(width: 5),
                          _tag('人工亲测', const Color(0xFF2563EB),
                              const Color(0xFFE8EEFF)),
                          if (item.version.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(item.version,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey[500])),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _meta(Icons.sd_storage_rounded, item.size),
                          const SizedBox(width: 10),
                          _meta(Icons.visibility_rounded, '${item.views}'),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5B6EFF), Color(0xFF465CFF)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kBrand.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text('查看',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    if (text.isEmpty || text == '0') return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[400]),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _tag(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
      );

  Widget _ph() => Container(
        width: 56,
        height: 56,
        color: kBrand.withAlpha(30),
        child: const Icon(Icons.android, color: kBrand, size: 27),
      );
}
