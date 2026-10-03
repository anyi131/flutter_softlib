import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
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
  late final TabController _tab = TabController(length: 9, vsync: this);

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _carousels = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _referrals = [];
  List<Map<String, dynamic>> _versions = [];
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
      final cd = await _svc.cards();
      final rf = await _svc.referrals();
      final vs = await _svc.versions();
      if (mounted) setState(() {
        _posts = p;
        _reviews = r;
        _cats = ct;
        _carousels = ca;
        _reports = rp;
        _cards = cd;
        _referrals = rf;
        _versions = vs;
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
            Tab(text: '推荐 ${_referrals.length}'),
            Tab(text: '版本 ${_versions.length}'),
            Tab(text: '卡密 ${_cards.length}'),
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
                    _referralList(),
                    _versionList(),
                    _cardList(),
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
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: () => _editCarousel(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增轮播图'),
          ),
        ),
        const SizedBox(height: 12),
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
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    onPressed: () => _editCarousel(c)),
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

  Future<void> _editCarousel(Map? c) async {
    final titleCtrl = TextEditingController(text: '${c?['title'] ?? ''}');
    final imgCtrl = TextEditingController(text: '${c?['image'] ?? ''}');
    final urlCtrl = TextEditingController(text: '${c?['url'] ?? ''}');
    final weighCtrl = TextEditingController(text: '${c?['weigh'] ?? 0}');
    String type = '${c?['type'] ?? 'no'}';
    bool uploading = false;
    String err = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(c == null ? '新增轮播图' : '编辑轮播图'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '标题')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: imgCtrl,
                          decoration:
                              const InputDecoration(labelText: '图片 URL')),
                    ),
                    IconButton(
                      tooltip: '上传图片',
                      icon: uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.image_outlined, size: 21),
                      onPressed: uploading
                          ? null
                          : () async {
                              try {
                                final p = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85);
                                if (p == null) return;
                                setD(() => uploading = true);
                                final url = await _svc.uploadImage(File(p.path));
                                setD(() {
                                  imgCtrl.text = url;
                                  uploading = false;
                                });
                              } catch (e) {
                                setD(() {
                                  uploading = false;
                                  err = '上传失败';
                                });
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: '点击行为'),
                  items: const [
                    DropdownMenuItem(value: 'no', child: Text('不跳转')),
                    DropdownMenuItem(value: 'url', child: Text('跳转网址')),
                  ],
                  onChanged: (v) => setD(() => type = v ?? 'no'),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(labelText: '跳转网址')),
                const SizedBox(height: 10),
                TextField(
                    controller: weighCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '权重')),
                if (err.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFDC2626))),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Get.back(result: true),
                child: const Text('保存')),
          ],
        );
      }),
    );
    if (ok != true) return;
    try {
      await _svc.saveCarousel({
        'id': c?['id'] ?? 0,
        'title': titleCtrl.text.trim(),
        'image': imgCtrl.text.trim(),
        'type': type,
        'url': urlCtrl.text.trim(),
        'weigh': int.tryParse(weighCtrl.text) ?? 0,
        'enable_switch': 1,
      });
      ToastUtil.success('保存成功');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ───── 线报 ─────
  Widget _reportList() {
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
            onPressed: () => _editReport(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增线报文章'),
          ),
        ),
        const SizedBox(height: 12),
        if (_reports.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('暂无线报文章',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          )
        else
          ..._reports.map((r) => _reportTile(r)),
      ],
    );
  }

  Widget _reportTile(Map r) {
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
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  onPressed: () => _editReport(r)),
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
  }

  Future<void> _editReport(Map? r) async {
    // 编辑时先拉取完整正文
    Map<String, dynamic> full = {};
    if (r != null) {
      try {
        full = await _svc.reportDetail(int.tryParse('${r['id']}') ?? 0);
      } catch (_) {}
    }
    final titleCtrl = TextEditingController(text: '${full['title'] ?? r?['title'] ?? ''}');
    final contentCtrl = TextEditingController(text: '${full['content'] ?? ''}');
    final imgCtrl = TextEditingController(text: '${full['image'] ?? ''}');
    bool uploading = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(r == null ? '新增线报' : '编辑线报'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: '文章标题')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: imgCtrl,
                            decoration:
                                const InputDecoration(labelText: '封面图 URL')),
                      ),
                      IconButton(
                        icon: uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.image_outlined, size: 21),
                        onPressed: uploading
                            ? null
                            : () async {
                                try {
                                  final p = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85);
                                  if (p == null) return;
                                  setD(() => uploading = true);
                                  final url =
                                      await _svc.uploadImage(File(p.path));
                                  setD(() {
                                    imgCtrl.text = url;
                                    uploading = false;
                                  });
                                } catch (_) {
                                  setD(() => uploading = false);
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: contentCtrl,
                      maxLines: 8,
                      decoration: const InputDecoration(
                          labelText: '正文内容(支持 HTML)',
                          alignLabelWithHint: true)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text(r == null ? '发布' : '保存')),
          ],
        );
      }),
    );
    if (ok != true) return;
    try {
      await _svc.saveReport({
        'id': r?['id'] ?? 0,
        'title': titleCtrl.text.trim(),
        'content': contentCtrl.text,
        'image': imgCtrl.text.trim(),
      });
      ToastUtil.success('已保存');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ───── 首页推荐位 ─────
  Widget _referralList() {
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
            onPressed: () => _editReferral(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增推荐位'),
          ),
        ),
        const SizedBox(height: 12),
        for (final r in _referrals)
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
                    imageUrl: '${r['image']}',
                    width: 60,
                    height: 42,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 60, height: 42, color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${r['title']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    onPressed: () => _editReferral(r)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: Color(0xFFDC2626)),
                  onPressed: () async {
                    await _svc
                        .deleteReferral(int.tryParse('${r['id']}') ?? 0);
                    ToastUtil.success('已删除');
                    _load();
                  },
                ),
              ],
            ),
          ),
        if (_referrals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('暂无推荐位',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          ),
      ],
    );
  }

  Future<void> _editReferral(Map? r) async {
    final titleCtrl = TextEditingController(text: '${r?['title'] ?? ''}');
    final contentCtrl = TextEditingController(text: '${r?['content'] ?? ''}');
    final imgCtrl = TextEditingController(text: '${r?['image'] ?? ''}');
    final urlCtrl = TextEditingController(text: '${r?['url'] ?? ''}');
    String type = '${r?['type'] ?? 'no'}';
    bool uploading = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(r == null ? '新增推荐位' : '编辑推荐位'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '标题')),
                const SizedBox(height: 10),
                TextField(
                    controller: contentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '简介')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: imgCtrl,
                          decoration:
                              const InputDecoration(labelText: '封面图 URL')),
                    ),
                    IconButton(
                      icon: uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.image_outlined, size: 21),
                      onPressed: uploading
                          ? null
                          : () async {
                              try {
                                final p = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85);
                                if (p == null) return;
                                setD(() => uploading = true);
                                final url = await _svc.uploadImage(File(p.path));
                                setD(() {
                                  imgCtrl.text = url;
                                  uploading = false;
                                });
                              } catch (_) {
                                setD(() => uploading = false);
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: '点击行为'),
                  items: const [
                    DropdownMenuItem(value: 'no', child: Text('不跳转')),
                    DropdownMenuItem(value: 'url', child: Text('跳转网址')),
                  ],
                  onChanged: (v) => setD(() => type = v ?? 'no'),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(labelText: '跳转网址')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Get.back(result: true),
                child: const Text('保存')),
          ],
        );
      }),
    );
    if (ok != true) return;
    try {
      await _svc.saveReferral({
        'id': r?['id'] ?? 0,
        'title': titleCtrl.text.trim(),
        'content': contentCtrl.text.trim(),
        'image': imgCtrl.text.trim(),
        'type': type,
        'url': urlCtrl.text.trim(),
        'switch': 1,
      });
      ToastUtil.success('保存成功');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ───── 版本更新管理 ─────
  Widget _versionList() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '提示：版本号需大于 App 当前版本才会提示更新。如当前是 1.0.0，填 v1.1.0 即可触发。',
            style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), height: 1.5),
          ),
        ),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: () => _editVersion(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('发布新版本'),
          ),
        ),
        const SizedBox(height: 12),
        for (final v in _versions)
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
                      Row(
                        children: [
                          Text('${v['version']}',
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          if ('${v['forced_switch']}' == '1')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('强制更新',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFDC2626))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${v['title'] ?? ''} · ${v['createtime_text'] ?? ''}',
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey[500])),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    onPressed: () => _editVersion(v)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: Color(0xFFDC2626)),
                  onPressed: () async {
                    await _svc.deleteVersion(int.tryParse('${v['id']}') ?? 0);
                    ToastUtil.success('已删除');
                    _load();
                  },
                ),
              ],
            ),
          ),
        if (_versions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('暂无版本记录',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          ),
      ],
    );
  }

  Future<void> _editVersion(Map? v) async {
    final verCtrl = TextEditingController(text: '${v?['version'] ?? ''}');
    final titleCtrl = TextEditingController(text: '${v?['title'] ?? ''}');
    final contentCtrl = TextEditingController(text: '${v?['content'] ?? ''}');
    final urlCtrl = TextEditingController(text: '${v?['dow_url'] ?? ''}');
    bool forced = '${v?['forced_switch'] ?? 0}' == '1';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(v == null ? '发布新版本' : '编辑版本'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: verCtrl,
                    decoration: const InputDecoration(
                        labelText: '版本号', hintText: '如 v1.1.0')),
                const SizedBox(height: 10),
                TextField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: '版本标题')),
                const SizedBox(height: 10),
                TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: '更新说明(支持 HTML)')),
                const SizedBox(height: 10),
                TextField(
                    controller: urlCtrl,
                    decoration:
                        const InputDecoration(labelText: '下载地址')),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(
                        child: Text('强制更新',
                            style: TextStyle(fontSize: 13.5))),
                    Switch(
                      value: forced,
                      activeThumbColor: const Color(0xFF5B6CFF),
                      onChanged: (x) => setD(() => forced = x),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Get.back(result: true),
                child: const Text('发布')),
          ],
        );
      }),
    );
    if (ok != true) return;
    try {
      await _svc.saveVersion({
        'id': v?['id'] ?? 0,
        'version': verCtrl.text.trim(),
        'title': titleCtrl.text.trim(),
        'content': contentCtrl.text.trim(),
        'dow_url': urlCtrl.text.trim(),
        'forced_switch': forced ? 1 : 0,
        'enable_switch': 1,
      });
      ToastUtil.success('保存成功');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ───── 卡密管理 ─────
  Widget _cardList() {
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
            onPressed: _genCards,
            icon: const Icon(Icons.add_card, size: 18),
            label: const Text('批量生成卡密'),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in _cards)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                      Text('${c['code']}',
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 2),
                      Text(
                        '${c['type'] == 'vip' ? '会员 ${c['value']} 天' : '积分 ${c['value']}'}'
                        ' · ${c['used'] == 1 ? '已使用' : '未使用'}',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: const Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: Color(0xFFDC2626)),
                  onPressed: () async {
                    await _svc.deleteCard(int.tryParse('${c['id']}') ?? 0);
                    ToastUtil.success('已删除');
                    _load();
                  },
                ),
              ],
            ),
          ),
        if (_cards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text('暂无卡密，点上方按钮生成',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          ),
      ],
    );
  }

  Future<void> _genCards() async {
    final countCtrl = TextEditingController(text: '10');
    final valueCtrl = TextEditingController(text: '30');
    String type = 'vip';
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('批量生成卡密'),
        content: StatefulBuilder(builder: (ctx, setD) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '生成数量')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: '卡密类型'),
                items: const [
                  DropdownMenuItem(value: 'vip', child: Text('会员时长(天)')),
                  DropdownMenuItem(value: 'score', child: Text('积分')),
                ],
                onChanged: (v) => setD(() => type = v ?? 'vip'),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: type == 'vip' ? '会员天数' : '积分数量')),
            ],
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('生成')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.generateCards(
        int.tryParse(countCtrl.text) ?? 10,
        type,
        int.tryParse(valueCtrl.text) ?? 30,
      );
      ToastUtil.success('卡密已生成');
      _load();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    }
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
