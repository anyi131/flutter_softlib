import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/admin_service.dart';
import '../../../utils/toast_util.dart';

/// 内容管理：动态 / 评价 / 协议配置
class AdminContentTab extends StatefulWidget {
  const AdminContentTab({super.key});

  @override
  State<AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends State<AdminContentTab>
    with SingleTickerProviderStateMixin {
  final _svc = AdminService.instance;
  late final TabController _tab = TabController(length: 6, vsync: this);

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _carousels = [];
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _svc.posts();
      final r = await _svc.reviews();
      final ct = await _svc.appCats();
      final ca = await _svc.carousels();
      final rp = await _svc.reports();
      if (mounted) setState(() {
        _posts = p;
        _reviews = r;
        _cats = ct;
        _carousels = ca;
        _reports = rp;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFF465CFF),
          labelColor: const Color(0xFF465CFF),
          unselectedLabelColor: Colors.grey[500],
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: '动态 ${_posts.length}'),
            Tab(text: '评价 ${_reviews.length}'),
            Tab(text: '分类 ${_cats.length}'),
            Tab(text: '轮播 ${_carousels.length}'),
            Tab(text: '线报 ${_reports.length}'),
            const Tab(text: '配置'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : TabBarView(
                  controller: _tab,
                  children: [
                    _postList(),
                    _reviewList(),
                    _catList(),
                    _carouselList(),
                    _reportList(),
                    _configList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _postList() {
    if (_posts.isEmpty) return const Center(child: Text('暂无动态'));
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _posts.length,
      itemBuilder: (context, i) {
        final p = _posts[i];
        final imgs = (p['images'] is List) ? (p['images'] as List) : [];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${p['nickname']}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('${p['createtime_text']}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFDC2626)),
                    onPressed: () async {
                      await _svc.deletePost(
                          int.tryParse('${p['id']}') ?? 0);
                      ToastUtil.success('已删除');
                      _load();
                    },
                  ),
                ],
              ),
              if ('${p['content']}'.isNotEmpty)
                Text('${p['content']}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, height: 1.5)),
              if (imgs.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imgs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, j) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                          imageUrl: '${imgs[j]}',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text('赞 ${p['like_count']} · 评论 ${p['comment_count']} · 浏览 ${p['views']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        );
      },
    );
  }

  Widget _reviewList() {
    if (_reviews.isEmpty) return const Center(child: Text('暂无评价'));
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _reviews.length,
      itemBuilder: (context, i) {
        final r = _reviews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${r['nickname']}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(
                      5,
                      (j) => Icon(
                        j < (int.tryParse('${r['score']}') ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 13,
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFDC2626)),
                    onPressed: () async {
                      await _svc.deleteReview(
                          int.tryParse('${r['id']}') ?? 0);
                      ToastUtil.success('已删除');
                      _load();
                    },
                  ),
                ],
              ),
              Text('${r['content']}',
                  style: const TextStyle(fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 4),
              Text('软件ID ${r['app_id']} · ${r['createtime_text']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        );
      },
    );
  }

  // ───── 分类管理 ─────
  Widget _catList() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: () => _editCat(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增分类'),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in _cats)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c['title']}',
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${c['count'] ?? 0} 个软件 · 权重 ${c['weigh'] ?? 0}',
                          style:
                              TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    onPressed: () => _editCat(c)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: Color(0xFFDC2626)),
                  onPressed: () async {
                    await _svc.deleteCat(int.tryParse('${c['id']}') ?? 0);
                    ToastUtil.success('已删除');
                    _load();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _editCat(Map? c) async {
    final nameCtrl = TextEditingController(text: '${c?['title'] ?? ''}');
    final weighCtrl = TextEditingController(text: '${c?['weigh'] ?? 0}');
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(c == null ? '新增分类' : '编辑分类'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '分类名称'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weighCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '权重（越大越靠前）'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.saveCat({
        'id': c?['id'] ?? 0,
        'title': nameCtrl.text.trim(),
        'weigh': int.tryParse(weighCtrl.text) ?? 0,
      });
      ToastUtil.success('保存成功');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ───── 轮播图 ─────
  Widget _carouselList() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (final c in _carousels)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: '${c['image']}',
                    width: 60,
                    height: 42,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 60, height: 42, color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${c['title']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: Color(0xFFDC2626)),
                  onPressed: () async {
                    await _svc
                        .deleteCarousel(int.tryParse('${c['id']}') ?? 0);
                    ToastUtil.success('已删除');
                    _load();
                  },
                ),
              ],
            ),
          ),
        if (_carousels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('暂无轮播图，可在网页后台添加',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          ),
      ],
    );
  }

  // ───── 线报 ─────
  Widget _reportList() {
    if (_reports.isEmpty) {
      return Center(
          child: Text('暂无线报文章',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _reports.length,
      itemBuilder: (context, i) {
        final r = _reports[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['title']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('浏览 ${r['views']}',
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 19, color: Color(0xFFDC2626)),
                onPressed: () async {
                  await _svc.deleteReport(int.tryParse('${r['id']}') ?? 0);
                  ToastUtil.success('已删除');
                  _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _configList() {
    final placard = TextEditingController();
    final agreement = TextEditingController();
    final privacy = TextEditingController();
    return FutureBuilder<Map<String, dynamic>>(
      future: _svc.config(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 3));
        }
        if (placard.text.isEmpty) {
          placard.text = '${snap.data!['placard'] ?? ''}';
          agreement.text = '${snap.data!['agreement'] ?? ''}';
          privacy.text = '${snap.data!['privacy'] ?? ''}';
        }
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _f('首页公告', placard, 2),
            _f('用户协议', agreement, 6),
            _f('隐私政策', privacy, 6),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF465CFF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23)),
                ),
                onPressed: () async {
                  try {
                    await _svc.saveConfig({
                      'placard': placard.text,
                      'agreement': agreement.text,
                      'privacy': privacy.text,
                    });
                    ToastUtil.success('保存成功');
                  } catch (e) {
                    ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                child: const Text('保存配置',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _f(String label, TextEditingController c, int lines) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: lines,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}
