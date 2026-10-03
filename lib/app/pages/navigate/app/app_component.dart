import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/soft_service.dart';
import '../../../models/app_cat.dart';
import '../../../models/app_item.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/tab_bottom_pad.dart';

/// 软件 - 综合类软件大合集（分类 Tab + 卡片列表）
class AppComponent extends StatefulWidget {
  const AppComponent({super.key});

  @override
  State<AppComponent> createState() => _AppComponentState();
}

class _AppComponentState extends State<AppComponent> {
  final SoftService _service = SoftService.instance;
  final ScrollController _scroll = ScrollController();

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
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 240) {
      if (!_loadingMore && _hasMore) _loadApps();
    }
  }

  Future<void> _loadCats() async {
    final cats = await _service.fetchCats();
    if (!mounted) return;
    setState(() {
      _cats = [AppCat(id: 0, title: '全部资源', count: 0), ...cats.where((c) => c.id != 0)];
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
      // 前端分页（后端一次返回 300 条）
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
    final bg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F6F7);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('软件',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            Text('综合类软件大合集',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(Routes.appSearch),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => Get.toNamed(Routes.appDownload),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCatBar(isDark),
          Expanded(child: _buildList(isDark)),
        ],
      ),
    );
  }

  /// 分类 Tab 条（可横向滚动）
  Widget _buildCatBar(bool isDark) {
    if (_cats.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _cats[i];
          final selected = _currentCat == cat.id;
          return GestureDetector(
            onTap: () => _switchCat(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF465CFF)
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 60, color: Colors.grey.withAlpha(100)),
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
        padding: EdgeInsets.only(top: 6, bottom: tabBottomPadding(context)),
        itemCount: _apps.length + 1,
        itemBuilder: (context, index) {
          if (index == _apps.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            if (!_hasMore && _apps.length > _pageSize) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text('已经到底啦',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[400])),
                ),
              );
            }
            return const SizedBox(height: 8);
          }
          return _buildCard(_apps[index], isDark);
        },
      ),
    );
  }

  /// 软件卡片（图标 + 名称 + 认证标签 + 来源 + 大小/时间/浏览量 + 查看按钮）
  Widget _buildCard(AppItem item, bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.toNamed(Routes.appDetails, arguments: {
            'appId': item.id.toString(),
            'item': item,
          }),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.icon.isEmpty
                      ? _phIcon(scheme)
                      : CachedNetworkImage(
                          imageUrl: item.icon,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _phIcon(scheme),
                          errorWidget: (_, __, ___) => _phIcon(scheme),
                        ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? '未知应用' : item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      // 价格 / 认证标签
                      Row(
                        children: [
                          if (item.isVipItem)
                            _tag('会员', const Color(0xFFB45309),
                                const Color(0xFFFEF3C7))
                          else
                            _tag('免费', const Color(0xFF16A34A),
                                const Color(0xFFDCFCE7)),
                          const SizedBox(width: 5),
                          _tag('人工亲测', const Color(0xFF2563EB),
                              const Color(0xFFDBEAFE)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (item.size.isNotEmpty) item.size,
                          if (item.uploadDate.isNotEmpty)
                            '上传时间 ${item.uploadDate}',
                          if (item.views > 0) '${item.views} 浏览',
                        ].join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('查看',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phIcon(ColorScheme scheme) => Container(
        width: 52,
        height: 52,
        color: scheme.primaryContainer.withAlpha(110),
        child: Icon(Icons.android, color: scheme.primary, size: 26),
      );

  Widget _tag(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      );
}
