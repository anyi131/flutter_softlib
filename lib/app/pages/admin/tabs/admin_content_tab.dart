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
  late final TabController _tab = TabController(length: 3, vsync: this);

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _reviews = [];
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
      if (mounted) setState(() {
        _posts = p;
        _reviews = r;
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
          tabs: [
            Tab(text: '动态 ${_posts.length}'),
            Tab(text: '评价 ${_reviews.length}'),
            const Tab(text: '协议配置'),
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
