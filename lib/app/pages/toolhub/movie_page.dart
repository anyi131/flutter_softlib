import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../api/soft_service.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';

/// 影视大全（v47 —— 对接样本真实采集源，可搜索 + 可播放）
///
/// 数据源：后端 /api/softlib/media/movie_search（聚合量子/极速/红牛等苹果CMS源）
class MoviePage extends StatefulWidget {
  const MoviePage({super.key});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  final TextEditingController _c = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _blocks = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    final b = await SoftService.instance.mediaMovieHome();
    if (!mounted || b.isEmpty) return;
    setState(() => _blocks = b);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final kw = q.trim();
    if (kw.isEmpty) {
      ToastUtil.info('请输入影片名');
      return;
    }
    setState(() {
      _loading = true;
      _searched = true;
    });
    final r = await SoftService.instance.mediaMovieSearch(kw);
    if (!mounted) return;
    setState(() {
      _list = r;
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
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: C.stroke.withAlpha(60)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: context.t1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: C.stroke.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 19, color: context.t3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _c,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                      style: const TextStyle(fontSize: 14.5),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '搜索电影 / 电视剧 / 动漫',
                        hintStyle:
                            TextStyle(fontSize: 14.5, color: context.t3),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _search(_c.text),
                    child: Text('搜索',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: C.brand)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: SizedBox(
              width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4)));
    }
    if (!_searched) {
      if (_blocks.isEmpty) {
        return Center(
          child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4)),
        );
      }
      return ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 40),
        children: [
          for (final b in _blocks) _block(b),
        ],
      );
    }
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: context.t3),
            const SizedBox(height: 12),
            Text('没有找到相关影视', style: TextStyle(color: context.t3)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemCount: _list.length,
      itemBuilder: (c, i) => _item(_list[i]),
    );
  }

  Widget _block(Map<String, dynamic> b) {
    final items = ((b['list'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('${b['title'] ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (c, i) {
              final m = items[i];
              return GestureDetector(
                onTap: () => Get.to(() => MovieDetailPage(
                      src: '${m['src'] ?? ''}',
                      id: '${m['id'] ?? ''}',
                      title: '${m['name'] ?? ''}',
                      cover: '${m['pic'] ?? ''}',
                    )),
                child: SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 134,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: '${m['pic'] ?? ''}'.isEmpty
                                    ? Container(color: C.brand.withAlpha(20))
                                    : CachedNetworkImage(
                                        imageUrl: '${m['pic']}',
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
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(170),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text('${m['remarks']}',
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('${m['name'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _item(Map<String, dynamic> m) {
    final pic = '${m['pic'] ?? ''}';
    return GestureDetector(
      onTap: () => Get.to(() => MovieDetailPage(
            src: '${m['src'] ?? ''}',
            id: '${m['id'] ?? ''}',
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
                        ? Container(
                            color: C.brand.withAlpha(20),
                            child: Icon(Icons.movie_rounded,
                                color: C.brand.withAlpha(120), size: 30),
                          )
                        : CachedNetworkImage(
                            imageUrl: pic,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: C.brand.withAlpha(14)),
                            errorWidget: (_, __, ___) => Container(
                                color: C.brand.withAlpha(14),
                                child: Icon(Icons.broken_image_rounded,
                                    color: context.t3)),
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
                        color: Colors.black.withAlpha(170),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${m['remarks']}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${m['name'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          if ('${m['year'] ?? ''}'.isNotEmpty)
            Text('${m['year']}  ${m['type'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.t3)),
        ],
      ),
    );
  }
}

/// 影视详情 + 播放
class MovieDetailPage extends StatefulWidget {
  final String src;
  final String id;
  final String title;
  final String cover;
  const MovieDetailPage({
    super.key,
    required this.src,
    required this.id,
    this.title = '',
    this.cover = '',
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  Map<String, dynamic>? _d;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SoftService.instance.mediaMovieDetail(widget.src, widget.id);
    if (!mounted) return;
    setState(() {
      _d = d;
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
            child: _loading
                ? const Center(
                    child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.4)))
                : (_d == null
                    ? _err()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        children: [
                          _topBar(),
                          _head(),
                          const SizedBox(height: 16),
                          ..._groups(),
                        ],
                      )),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: C.stroke.withAlpha(60)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: context.t1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${_d!['name'] ?? widget.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _head() {
    final pic = '${_d!['pic'] ?? widget.cover}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 108,
            height: 154,
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_d!['name'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if ('${_d!['year'] ?? ''}'.isNotEmpty) _tag('${_d!['year']}'),
                  if ('${_d!['type'] ?? ''}'.isNotEmpty) _tag('${_d!['type']}'),
                  if ('${_d!['area'] ?? ''}'.isNotEmpty) _tag('${_d!['area']}'),
                  if ('${_d!['remarks'] ?? ''}'.isNotEmpty)
                    _tag('${_d!['remarks']}', highlight: true),
                ],
              ),
              const SizedBox(height: 8),
              if ('${_d!['score'] ?? ''}'.isNotEmpty &&
                  '${_d!['score']}' != '0.0')
                Text('评分 ${_d!['score']}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B))),
              if ('${_d!['actor'] ?? ''}'.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('主演：${_d!['actor']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.t3)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tag(String t, {bool highlight = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: highlight ? C.brand.withAlpha(30) : C.brand.withAlpha(14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 11.5,
                color: highlight ? C.brand : context.t2,
                fontWeight: FontWeight.w600)),
      );

  List<Widget> _groups() {
    final groups = (_d!['play_groups'] as List?) ?? [];
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
        padding: const EdgeInsets.only(top: 14, bottom: 10),
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
            Text('播放源 · ${gm['from']}',
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text('${eps.length} 集',
                style: TextStyle(fontSize: 11.5, color: context.t3)),
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
                  title: '${_d!['name'] ?? ''} - ${em['name'] ?? ''}',
                )),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
      out.add(const SizedBox(height: 6));
    }
    final content = '${_d!['content'] ?? ''}';
    if (content.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text('简介',
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: context.t1)),
      ));
      out.add(Text(content,
          style: TextStyle(fontSize: 13.5, height: 1.8, color: context.t2)));
    }
    return out;
  }

  Widget _err() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: context.t3),
            const SizedBox(height: 12),
            Text('加载失败', style: TextStyle(color: context.t3)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
}

/// 视频播放页（真实播放 m3u8 / mp4）
class MoviePlayerPage extends StatefulWidget {
  final String url;
  final String title;
  const MoviePlayerPage({super.key, required this.url, this.title = ''});

  @override
  State<MoviePlayerPage> createState() => _MoviePlayerPageState();
}

class _MoviePlayerPageState extends State<MoviePlayerPage> {
  VideoPlayerController? _c;
  String? _err;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      setState(() => _err = '播放地址为空');
      return;
    }
    try {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
        },
      );
      _c = c;
      await c.initialize();
      await c.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = '播放失败：$e');
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15)),
      ),
      body: Center(
        child: _err != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white54, size: 46),
                    const SizedBox(height: 12),
                    const Text('无法播放该视频',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(_err!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              )
            : (!_ready || _c == null
                ? const CircularProgressIndicator(color: Colors.white)
                : AspectRatio(
                    aspectRatio: _c!.value.aspectRatio == 0
                        ? 16 / 9
                        : _c!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_c!),
                        _controls(),
                      ],
                    ),
                  )),
      ),
    );
  }

  Widget _controls() {
    final v = _c!.value;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: Colors.black54,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  v.isPlaying ? _c!.pause() : _c!.play();
                });
              },
              icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white),
            ),
            Text(_fmt(v.position),
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Expanded(
              child: VideoProgressIndicator(
                _c!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                    playedColor: Color(0xFF6E7DFF)),
              ),
            ),
            Text(_fmt(v.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
