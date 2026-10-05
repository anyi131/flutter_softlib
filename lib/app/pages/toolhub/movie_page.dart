import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import 'hero_gallery_page.dart';

/// 影视库（真实体内置工具）
///
/// 数据源：api.wmdb.tv（经后端中转 + 缓存）
class MoviePage extends StatefulWidget {
  const MoviePage({super.key});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  final _kwCtrl = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  bool _loading = false;
  bool _searched = false;

  static const _hot = ['火线', '爱情', '动作', '喜剧', '2024', '日本', '漫威', '悬疑'];

  @override
  void dispose() {
    _kwCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    _kwCtrl.text = q;
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      final l = await SoftService.instance.movieSearch(q);
      if (mounted) setState(() {
        _list = l;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.pagePadding, 10, context.pagePadding, 6),
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
                      Text('影视库',
                          style:
                              Ty.h2.copyWith(fontSize: 19, color: context.t1)),
                    ],
                  ),
                ),
                // 搜索框
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _kwCtrl,
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '搜索电影 / 电视剧',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 19),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                          onPressed: () => _search(_kwCtrl.text),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.full)),
                      ),
                    ),
                  ),
                ),
                if (!_searched) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: context.pagePadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('热门搜索',
                          style: Ty.h3.copyWith(fontSize: 13.5, color: context.t1)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: context.pagePadding),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hot
                          .map((k) => GestureDetector(
                                onTap: () => _search(k),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: C.brand.withAlpha(
                                        context.isDark ? 30 : 18),
                                    borderRadius:
                                        BorderRadius.circular(R.full),
                                  ),
                                  child: Text(k,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: C.brand,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState(text: '搜索中…');
    if (!_searched) {
      return const EmptyState(
        text: '搜索影视资源',
        hint: '输入片名或点上面的热门关键词',
        icon: Icons.movie_filter_rounded,
      );
    }
    if (_list.isEmpty) {
      return const EmptyState(text: '没有找到相关影视', icon: Icons.search_off_rounded);
    }
    return GridView.builder(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 0, context.pagePadding, context.tabSpace + 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.56,
      ),
      itemCount: _list.length,
      itemBuilder: (_, i) {
        final m = _list[i];
        final title = '${m['name']}'.isNotEmpty ? '${m['name']}' : '${m['original']}';
        return GestureDetector(
          onTap: () => Get.to(() => MovieDetailPage(movie: m)),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      '${m['cover']}'.isEmpty
                          ? Container(
                              color: C.brand.withAlpha(16),
                              child: Icon(Icons.movie_outlined,
                                  color: context.t3, size: 26),
                            )
                          : CachedNetworkImage(
                              imageUrl: '${m['cover']}',
                              fit: BoxFit.cover,
                              memCacheWidth: 320,
                              placeholder: (_, __) =>
                                  Container(color: C.brand.withAlpha(16)),
                              errorWidget: (_, __, ___) => Container(
                                color: C.brand.withAlpha(16),
                                child: Icon(Icons.movie_outlined,
                                    color: context.t3, size: 26),
                              ),
                            ),
                      if ('${m['rating']}'.isNotEmpty &&
                          double.tryParse('${m['rating']}') != null &&
                          (double.tryParse('${m['rating']}') ?? 0) > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('★ ${m['rating']}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFFD54F),
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.t1)),
              if ('${m['year']}'.isNotEmpty)
                Text('${m['year']}',
                    style: Ty.tiny.copyWith(fontSize: 10, color: context.t3)),
            ],
          ),
        );
      },
    );
  }
}

/// 影视详情
class MovieDetailPage extends StatelessWidget {
  final Map<String, dynamic> movie;
  const MovieDetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final title = '${movie['name']}'.isNotEmpty
        ? '${movie['name']}'
        : '${movie['original']}';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(context.pagePadding, 10,
                  context.pagePadding, context.tabSpace + 24),
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 海报
                    Container(
                      width: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(
                            color: C.stroke.withAlpha(50), width: 0.8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: '${movie['cover']}'.isEmpty
                            ? Container(
                                color: C.brand.withAlpha(16),
                                child: Icon(Icons.movie_outlined,
                                    color: context.t3, size: 30))
                            : CachedNetworkImage(
                                imageUrl: '${movie['cover']}',
                                fit: BoxFit.cover,
                                memCacheWidth: 320,
                                errorWidget: (_, __, ___) => Container(
                                  color: C.brand.withAlpha(16),
                                  child: Icon(Icons.movie_outlined,
                                      color: context.t3, size: 30),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: Ty.h1
                                  .copyWith(fontSize: 19, color: context.t1)),
                          if ('${movie['original']}'.isNotEmpty &&
                              '${movie['original']}' != title) ...[
                            const SizedBox(height: 4),
                            Text('${movie['original']}',
                                style: Ty.small.copyWith(color: context.t3)),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            children: [
                              if ('${movie['year']}'.isNotEmpty)
                                Pill('${movie['year']}',
                                    color: C.brand, small: true),
                              if ('${movie['rating']}'.isNotEmpty &&
                                  '${movie['rating']}' != '0')
                                Pill('★ ${movie['rating']}',
                                    color: C.amber, small: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if ('${movie['intro']}'.isNotEmpty) ...[
                  Text('剧情简介',
                      style: Ty.h3.copyWith(fontSize: 15, color: context.t1)),
                  const SizedBox(height: 8),
                  Text('${movie['intro']}',
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.8,
                          color: context.isDark
                              ? Colors.grey[300]
                              : const Color(0xFF41454B))),
                ] else
                  Text('暂无简介',
                      style: Ty.small.copyWith(color: context.t3)),
                const SizedBox(height: 22),
                // 提示：本工具只做资料查询，播放请用「影视解析」工具
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: C.brand.withAlpha(context.isDark ? 26 : 16),
                    borderRadius: BorderRadius.circular(R.md),
                    border: Border.all(color: C.brand.withAlpha(70), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: C.brand),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '本工具提供影视资料查询。想看视频可到「资源解析 → 影视解析」粘贴播放链接。',
                          style: TextStyle(
                              fontSize: 12, height: 1.6, color: C.brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
