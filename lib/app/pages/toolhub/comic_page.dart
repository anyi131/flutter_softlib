import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import 'hero_gallery_page.dart';

/// 漫画书城（真实体内置工具）
///
/// 数据源：api.teamcat.cc（经后端中转 + 缓存）
/// 结构：分类标签 → 漫画列表 → 章节列表 → 图片阅读
class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  bool _listLoading = false;
  String _curTag = '';
  String _kw = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final tags = await SoftService.instance.comicTags();
      if (mounted) setState(() => _tags = tags);
    } catch (_) {}
    await _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _listLoading = true);
    try {
      if (_kw.isNotEmpty) {
        // 搜索模式：后端暂无搜索接口时用列表过滤兜底
        final l = await SoftService.instance.comicList(tag: _curTag);
        if (!mounted) return;
        setState(() {
          _list = l
              .where((c) => '${c['title']}'.toLowerCase().contains(_kw.toLowerCase()))
              .toList();
          _listLoading = false;
          _loading = false;
        });
        return;
      }
      final l = await SoftService.instance.comicList(tag: _curTag);
      if (!mounted) return;
      setState(() {
        _list = l;
        _listLoading = false;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _listLoading = false;
        _loading = false;
      });
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
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
                ToolPageBar(
                  title: '漫画书城',
                  subtitle: _list.isEmpty ? '' : '共 ${_list.length} 部',
                  onSearch: (v) {
                    _kw = v;
                    _loadList();
                  },
                  searchHint: '搜索漫画名',
                ),
                // 分类标签
                if (_tags.isNotEmpty)
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.pagePadding),
                      children: [
                        _tagChip('全部', ''),
                        ..._tags.take(24).map((t) =>
                            _tagChip('${t['tagtitle']}', '${t['tagid']}')),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, String id) {
    final sel = _curTag == id;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: () {
          if (_curTag == id) return;
          setState(() => _curTag = id);
          _loadList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel
                ? C.brand
                : (context.isDark
                    ? Colors.white.withAlpha(12)
                    : Colors.black.withAlpha(6)),
            borderRadius: BorderRadius.circular(R.full),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? Colors.white : context.t2)),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState(text: '加载漫画…');
    if (_listLoading) return const LoadingState(text: '加载中…');
    if (_list.isEmpty) {
      return const EmptyState(text: '暂无漫画', hint: '换个分类试试', icon: Icons.menu_book_rounded);
    }
    return GridView.builder(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 6, context.pagePadding, context.tabSpace + 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.58,
      ),
      itemCount: _list.length,
      itemBuilder: (_, i) {
        final c = _list[i];
        return GestureDetector(
          onTap: () => Get.to(() => ComicDetailPage(
                comicId: '${c['id']}',
                title: '${c['title']}',
              )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(R.md),
                    border:
                        Border.all(color: C.stroke.withAlpha(50), width: 0.8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: '${c['cover']}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    memCacheWidth: 320,
                    placeholder: (_, __) =>
                        Container(color: C.brand.withAlpha(16)),
                    errorWidget: (_, __, ___) => Container(
                      color: C.brand.withAlpha(16),
                      child: Icon(Icons.menu_book_rounded,
                          color: context.t3, size: 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('${c['title']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.t1)),
              if ('${c['author'] ?? ''}'.isNotEmpty)
                Text('${c['author']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ty.tiny.copyWith(fontSize: 10, color: context.t3)),
            ],
          ),
        );
      },
    );
  }
}

/// 漫画详情（章节列表）
class ComicDetailPage extends StatefulWidget {
  final String comicId;
  final String title;
  const ComicDetailPage({
    super.key,
    required this.comicId,
    required this.title,
  });

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  List<Map<String, dynamic>> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await SoftService.instance.comicChapters(widget.comicId);
      if (mounted) setState(() {
        _chapters = l;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                ToolPageBar(
                  title: widget.title,
                  subtitle: _chapters.isEmpty ? '' : '共 ${_chapters.length} 章',
                ),
                Expanded(
                  child: _loading
                      ? const LoadingState(text: '加载章节…')
                      : (_chapters.isEmpty
                          ? const EmptyState(text: '暂无章节')
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                  context.pagePadding,
                                  4,
                                  context.pagePadding,
                                  context.tabSpace + 24),
                              itemCount: _chapters.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 7),
                              itemBuilder: (_, i) {
                                final ch = _chapters[i];
                                return GestureDetector(
                                  onTap: () => Get.to(() => ComicReaderPage(
                                        chapterId: '${ch['id']}',
                                        title: '${ch['title']}',
                                      )),
                                  child: KitCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text('${ch['title']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Ty.body.copyWith(
                                                  fontSize: 13.5,
                                                  color: context.t1)),
                                        ),
                                        Icon(Icons.chevron_right_rounded,
                                            size: 18, color: context.t3),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 漫画阅读器（竖向长图滚动）
class ComicReaderPage extends StatefulWidget {
  final String chapterId;
  final String title;
  const ComicReaderPage({
    super.key,
    required this.chapterId,
    required this.title,
  });

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage> {
  List<String> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await SoftService.instance.comicImages(widget.chapterId);
      if (mounted) setState(() {
        _images = l;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          if (_loading)
            const Center(
                child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white70)))
          else if (_images.isEmpty)
            const Center(
                child: Text('暂无图片', style: TextStyle(color: Colors.white54)))
          else
            ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              itemCount: _images.length,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: _images[i],
                fit: BoxFit.fitWidth,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: Colors.white10,
                  child: const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white38))),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.white38),
                ),
              ),
            ),
          // 顶栏
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  if (_images.isNotEmpty)
                    Text('${_images.length} 页',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white.withAlpha(180))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
