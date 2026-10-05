import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import 'movie_page.dart';

/// 短剧（v47 —— 对接红牛短剧源，可播放）
class DramaPage extends StatefulWidget {
  final String title;
  const DramaPage({super.key, this.title = '短剧'});

  @override
  State<DramaPage> createState() => _DramaPageState();
}

class _DramaPageState extends State<DramaPage> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more) _page++;
    if (!more) setState(() => _loading = true);
    final r = await SoftService.instance.mediaDramaList(page: _page);
    if (!mounted) return;
    setState(() {
      if (more) {
        _list.addAll(r);
      } else {
        _list = r;
      }
      _loading = false;
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
                _bar(),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, 10, context.pagePadding, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white.withAlpha(14) : Colors.white,
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
          Text(widget.title, style: Ty.h2.copyWith(fontSize: 19, color: context.t1)),
          const Spacer(),
          GestureDetector(
            onTap: () => _load(),
            child: Icon(Icons.refresh_rounded, size: 21, color: context.t2),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState(text: '加载中…');
    if (_list.isEmpty) {
      return const EmptyState(
          text: '暂无短剧', hint: '下拉刷新试试', icon: Icons.video_library_rounded);
    }
    return RefreshIndicator(
      onRefresh: () => _load(),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(context.pagePadding, 4,
            context.pagePadding, context.tabSpace + 30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.50,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
        ),
        itemCount: _list.length,
        itemBuilder: (c, i) => _item(_list[i]),
      ),
    );
  }

  Widget _item(Map<String, dynamic> m) {
    final pic = '${m['pic'] ?? ''}';
    return GestureDetector(
      onTap: () => Get.to(() => DramaDetailPage(
            id: '${m['id'] ?? ''}',
            src: '${m['src'] ?? 'hn'}',
            title: '${m['name'] ?? ''}',
            cover: pic,
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: pic.isEmpty
                        ? Container(color: C.brand.withAlpha(20))
                        : CachedNetworkImage(
                            imageUrl: pic,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: C.brand.withAlpha(14)),
                            errorWidget: (_, __, ___) =>
                                Container(color: C.brand.withAlpha(14)),
                          ),
                  ),
                ),
                if ('${m['remarks'] ?? ''}'.isNotEmpty)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: Deco.brandGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${m['remarks']}',
                          style: const TextStyle(
                              fontSize: 9.5, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${m['name'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Ty.h3.copyWith(fontSize: 12.5, color: context.t1)),
        ],
      ),
    );
  }
}

/// 短剧详情 + 选集
class DramaDetailPage extends StatefulWidget {
  final String id;
  final String src;
  final String title;
  final String cover;
  const DramaDetailPage({
    super.key,
    required this.id,
    this.src = 'hn',
    this.title = '',
    this.cover = '',
  });

  @override
  State<DramaDetailPage> createState() => _DramaDetailPageState();
}

class _DramaDetailPageState extends State<DramaDetailPage> {
  Map<String, dynamic>? _d;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d =
        await SoftService.instance.mediaDramaChannels(widget.id, src: widget.src);
    if (!mounted) return;
    setState(() {
      _d = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = '${_d?['name'] ?? widget.title}';
    final pic = '${_d?['pic'] ?? widget.cover}';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.4)))
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                        context.pagePadding, 0, context.pagePadding, 40),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                        child: Row(
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
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Ty.h2
                                      .copyWith(fontSize: 18, color: context.t1)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 104,
                              height: 148,
                              child: pic.isEmpty
                                  ? Container(color: C.brand.withAlpha(20))
                                  : CachedNetworkImage(
                                      imageUrl: pic,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                          color: C.brand.withAlpha(14)),
                                      errorWidget: (_, __, ___) => Container(
                                          color: C.brand.withAlpha(14)),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: Ty.h3.copyWith(
                                        fontSize: 16, color: context.t1)),
                                const SizedBox(height: 8),
                                if ('${_d?['content'] ?? ''}'.isNotEmpty)
                                  Text('${_d!['content']}',
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                      style: Ty.tiny.copyWith(
                                          fontSize: 12,
                                          height: 1.7,
                                          color: context.t2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ..._groups(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _groups() {
    final groups = (_d?['play_groups'] as List?) ?? [];
    if (groups.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text('暂无播放地址', style: TextStyle(color: context.t3)),
        )
      ];
    }
    final out = <Widget>[];
    for (final g in groups) {
      final gm = Map<String, dynamic>.from(g as Map);
      final eps = (gm['episodes'] as List?) ?? [];
      out.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                gradient: Deco.brandGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('${gm['from']}',
                style: Ty.h3.copyWith(fontSize: 14, color: context.t1)),
            const SizedBox(width: 8),
            Text('${eps.length} 集',
                style: Ty.tiny.copyWith(fontSize: 11.5, color: context.t3)),
          ],
        ),
      ));
      out.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: eps.map<Widget>((e) {
          final em = Map<String, dynamic>.from(e as Map);
          return GestureDetector(
            onTap: () => Get.to(() => MoviePlayerPage(
                  url: '${em['url'] ?? ''}',
                  title: '$_nameText - ${em['name'] ?? ''}',
                )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: C.brand.withAlpha(16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: C.brand.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 15, color: C.brand),
                  const SizedBox(width: 4),
                  Text('${em['name'] ?? ''}',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: C.brand)),
                ],
              ),
            ),
          );
        }).toList(),
      ));
      out.add(const SizedBox(height: 8));
    }
    return out;
  }

  String get _nameText => '${_d?['name'] ?? widget.title}';
}
