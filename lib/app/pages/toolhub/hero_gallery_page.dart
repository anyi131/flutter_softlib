import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';

/// 王者荣耀图集（真实体内置工具）
///
/// ★ 需求：工具不能只跳浏览器，要有实体界面。
///   数据来自官方 herolist.json（经后端中转）。
class HeroGalleryPage extends StatefulWidget {
  const HeroGalleryPage({super.key});

  @override
  State<HeroGalleryPage> createState() => _HeroGalleryPageState();
}

class _HeroGalleryPageState extends State<HeroGalleryPage> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _shown = [];
  bool _loading = true;
  String _kw = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await SoftService.instance.toolsHeroes();
      if (!mounted) return;
      setState(() {
        _all = list;
        _shown = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _filter(String kw) {
    _kw = kw.trim();
    if (_kw.isEmpty) {
      setState(() => _shown = _all);
      return;
    }
    final k = _kw.toLowerCase();
    setState(() {
      _shown = _all.where((h) {
        if ('${h['name']}'.toLowerCase().contains(k)) return true;
        if ('${h['title']}'.toLowerCase().contains(k)) return true;
        for (final s in (h['skins'] as List? ?? [])) {
          if ('${(s as Map)['name']}'.toLowerCase().contains(k)) return true;
        }
        return false;
      }).toList();
    });
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
                  title: '王者荣耀图集',
                  subtitle: '共 ${_all.length} 位英雄',
                  onSearch: _filter,
                  searchHint: '搜英雄 / 称号 / 皮肤',
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState(text: '加载英雄数据…');
    if (_shown.isEmpty) {
      return const EmptyState(text: '没有找到相关英雄', icon: Icons.search_off_rounded);
    }
    return GridView.builder(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 6, context.pagePadding, context.tabSpace + 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.76,
      ),
      itemCount: _shown.length,
      itemBuilder: (_, i) {
        final h = _shown[i];
        return GestureDetector(
          onTap: () => Get.to(() => HeroSkinsPage(
                ename: '${h['ename']}',
                name: '${h['name']}',
                title: '${h['title']}',
              )),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: C.stroke.withAlpha(60), width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: '${h['icon']}',
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  memCacheWidth: 160,
                  placeholder: (_, __) => Container(
                      width: 62, height: 62, color: C.brand.withAlpha(20)),
                  errorWidget: (_, __, ___) => Container(
                    width: 62,
                    height: 62,
                    color: C.brand.withAlpha(20),
                    child: Icon(Icons.person, color: context.t3, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('${h['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: context.t1)),
            ],
          ),
        );
      },
    );
  }
}

/// 单个英雄的皮肤图集
class HeroSkinsPage extends StatefulWidget {
  final String ename;
  final String name;
  final String title;
  const HeroSkinsPage({
    super.key,
    required this.ename,
    required this.name,
    this.title = '',
  });

  @override
  State<HeroSkinsPage> createState() => _HeroSkinsPageState();
}

class _HeroSkinsPageState extends State<HeroSkinsPage> {
  List<Map<String, dynamic>> _skins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await SoftService.instance.toolsHeroes();
      for (final h in all) {
        if ('${h['ename']}' == widget.ename) {
          _skins = (h['skins'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          break;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
                  title: widget.name,
                  subtitle: widget.title.isEmpty
                      ? '${_skins.length} 款皮肤'
                      : '${widget.title} · ${_skins.length} 款皮肤',
                ),
                Expanded(
                  child: _loading
                      ? const LoadingState(text: '加载皮肤…')
                      : (_skins.isEmpty
                          ? const EmptyState(text: '暂无皮肤数据')
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                  context.pagePadding,
                                  6,
                                  context.pagePadding,
                                  context.tabSpace + 24),
                              itemCount: _skins.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final s = _skins[i];
                                return GestureDetector(
                                  onTap: () => Get.to(() => ImageGalleryPage(
                                        title: '${s['name']}',
                                        images: _skins
                                            .map((e) => '${e['url']}')
                                            .toList(),
                                        initialIndex: i,
                                      )),
                                  child: KitCard(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(R.md),
                                          child: AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: CachedNetworkImage(
                                              imageUrl: '${s['url']}',
                                              fit: BoxFit.cover,
                                              memCacheWidth: 800,
                                              placeholder: (_, __) => Container(
                                                color: C.brand.withAlpha(16),
                                                child: const Center(
                                                    child: SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2))),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: C.brand.withAlpha(16),
                                                child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: context.t3),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, bottom: 2),
                                          child: Text('${s['name']}',
                                              style: Ty.h3.copyWith(
                                                  fontSize: 13.5,
                                                  color: context.t1)),
                                        ),
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

/// 通用图片浏览器（左右滑动 + 缩放）
class ImageGalleryPage extends StatefulWidget {
  final String title;
  final List<String> images;
  final int initialIndex;
  const ImageGalleryPage({
    super.key,
    required this.title,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final PageController _pc =
      PageController(initialPage: widget.initialIndex);
  late int _idx = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _idx = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white70))),
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 40),
                ),
              ),
            ),
          ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  Text('${_idx + 1}/${widget.images.length}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withAlpha(200))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 工具页通用顶栏（标题 + 可选搜索）
class ToolPageBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final ValueChanged<String>? onSearch;
  final String searchHint;
  const ToolPageBar({
    super.key,
    required this.title,
    this.subtitle = '',
    this.onSearch,
    this.searchHint = '搜索',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(context.pagePadding, 10, context.pagePadding, 6),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? Colors.white.withAlpha(14)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.black.withAlpha(8),
                    ),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: context.t1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Ty.h2.copyWith(fontSize: 19, color: context.t1)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: Ty.tiny.copyWith(color: context.t3)),
                  ],
                ),
              ),
            ],
          ),
          if (onSearch != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: TextField(
                onSubmitted: onSearch,
                onChanged: (v) {
                  if (v.isEmpty) onSearch!('');
                },
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: searchHint,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.full)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
