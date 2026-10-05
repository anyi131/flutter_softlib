import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import 'hero_gallery_page.dart';

/// 每日一言 / 心灵鸡汤（真实体内置工具）
class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final List<Map<String, dynamic>> _quotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final q = await SoftService.instance.hitokoto();
      if (mounted && (q['text'] ?? '') != '') {
        setState(() {
          _quotes.insert(0, q);
          if (_quotes.length > 30) _quotes.removeLast();
          _loading = false;
        });
        return;
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
                  title: '每日一言',
                  subtitle: _quotes.isEmpty ? '' : '已浏览 ${_quotes.length} 条',
                ),
                Expanded(
                  child: _loading && _quotes.isEmpty
                      ? const LoadingState(text: '加载中…')
                      : (_quotes.isEmpty
                          ? const EmptyState(text: '暂无内容')
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding: EdgeInsets.fromLTRB(
                                    context.pagePadding,
                                    4,
                                    context.pagePadding,
                                    context.tabSpace + 24),
                                itemCount: _quotes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) => _quoteCard(_quotes[i], i),
                              ),
                            )),
                ),
                // 底部「换一条」
                Padding(
                  padding: EdgeInsets.fromLTRB(context.pagePadding, 4,
                      context.pagePadding, context.tabSpace + 10),
                  child: SoftButton(
                    label: '换一条',
                    icon: Icons.autorenew_rounded,
                    expand: true,
                    height: 46,
                    onPressed: _refresh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard(Map<String, dynamic> q, int i) {
    final text = '${q['text'] ?? ''}';
    final from = '${q['from'] ?? ''}';
    final who = '${q['who'] ?? ''}';
    final source = [who, from].where((e) => e.isNotEmpty).join(' · ');
    return KitCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: Deco.brandGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.format_quote_rounded,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 9),
              Text('第 ${_quotes.length - i} 条',
                  style: Ty.tiny.copyWith(color: context.t3)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '$text  ——$source'));
                  ToastUtil.success('已复制');
                },
                child: Icon(Icons.copy_rounded, size: 16, color: context.t3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 15,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                  color: context.t1)),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child:
                  Text('—— $source', style: Ty.tiny.copyWith(color: context.t3)),
            ),
          ],
        ],
      ),
    );
  }
}

/// 音乐搜索（真实体内置工具）
class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final _kwCtrl = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  bool _loading = false;
  bool _searched = false;

  static const _hot = ['周杰伦', '林俊杰', '陈奕迅', '薛之谦', '邓紫棋', '五月天'];

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
      final l = await SoftService.instance.musicSearch(q);
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
                      Text('音乐搜索',
                          style:
                              Ty.h2.copyWith(fontSize: 19, color: context.t1)),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: context.pagePadding),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _kwCtrl,
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '搜索歌名 / 歌手',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 19),
                        suffixIcon: IconButton(
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 19),
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
                      child: Text('热门歌手',
                          style: Ty.h3
                              .copyWith(fontSize: 13.5, color: context.t1)),
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
                                    color: C.brand
                                        .withAlpha(context.isDark ? 30 : 18),
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
        text: '搜索歌曲',
        hint: '输入歌名或歌手，或点上面的热门',
        icon: Icons.music_note_rounded,
      );
    }
    if (_list.isEmpty) {
      return const EmptyState(text: '没有找到相关歌曲', icon: Icons.search_off_rounded);
    }
    return ListView.separated(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 0, context.pagePadding, context.tabSpace + 24),
      itemCount: _list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = _list[i];
        final dur = (int.tryParse('${s['duration']}') ?? 0) ~/ 1000;
        final durTxt = dur > 0
            ? '${(dur ~/ 60)}:${(dur % 60).toString().padLeft(2, '0')}'
            : '';
        return KitCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(R.sm),
                  color: C.brand.withAlpha(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: '${s['cover']}'.isEmpty
                    ? Icon(Icons.music_note_rounded,
                        color: context.t3, size: 22)
                    : CachedNetworkImage(
                        imageUrl: '${s['cover']}',
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        errorWidget: (_, __, ___) => Icon(
                            Icons.music_note_rounded,
                            color: context.t3,
                            size: 22),
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ty.h3
                            .copyWith(fontSize: 14, color: context.t1)),
                    const SizedBox(height: 3),
                    Text(
                      '${s['artist']}${'${s['album']}'.isNotEmpty ? ' · ${s['album']}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Ty.tiny.copyWith(color: context.t3),
                    ),
                  ],
                ),
              ),
              if (durTxt.isNotEmpty)
                Text(durTxt,
                    style: Ty.tiny.copyWith(fontSize: 10.5, color: context.t3)),
            ],
          ),
        );
      },
    );
  }
}
