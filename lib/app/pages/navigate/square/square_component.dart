import 'package:dio/dio.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 广场 - 社区动态（对接原生 PHP 后端 /api/softlib/post/*）
class SquareComponent extends StatefulWidget {
  const SquareComponent({super.key});

  @override
  State<SquareComponent> createState() => _SquareComponentState();
}

class _SquareComponentState extends State<SquareComponent> {
  static const String _baseUrl = 'https://flrjk.52yfx.cn';
  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));
  final EasyRefreshController _refreshController =
      EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);

  final List<Map<String, dynamic>> _posts = [];
  int _page = 1;
  bool _loading = true;
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _fetchPosts(reset: true);
  }

  Future<void> _loadNickname() async {
    final sp = await SharedPreferences.getInstance();
    _nickname = sp.getString('square_nickname') ?? '';
  }

  /// 拉取动态列表
  Future<void> _fetchPosts({bool reset = false}) async {
    if (reset) _page = 1;
    try {
      final resp = await _dio.get('/api/softlib/post/index', queryParameters: {'pages': _page});
      final data = resp.data;
      if (data['code'] == 1 && data['data'] is List) {
        final list = List<Map<String, dynamic>>.from(
            (data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
        setState(() {
          if (reset) _posts.clear();
          _posts.addAll(list);
          _loading = false;
          if (reset) _refreshController.finishRefresh();
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _loading = false;
      _refreshController.finishRefresh();
      _refreshController.finishLoad();
    });
  }

  /// 点赞
  Future<void> _like(Map<String, dynamic> post) async {
    final id = post['id'];
    setState(() {
      post['like_count'] = (int.tryParse('${post['like_count']}') ?? 0) + 1;
    });
    try {
      await _dio.post('/api/softlib/post/like', data: {'id': id});
    } catch (_) {}
  }

  /// 发布动态
  Future<void> _showComposeSheet() async {
    final contentCtrl = TextEditingController();
    final nickCtrl = TextEditingController(text: _nickname);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('发动态',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: nickCtrl,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                maxLength: 2000,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '分享你的想法…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF465CFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final content = contentCtrl.text.trim();
                    if (content.isEmpty) {
                      Navigator.pop(ctx, 'empty');
                      return;
                    }
                    final nick = nickCtrl.text.trim().isEmpty
                        ? '匿名用户'
                        : nickCtrl.text.trim();
                    try {
                      final resp = await _dio.post('/api/softlib/post/create',
                          data: {'nickname': nick, 'content': content});
                      if (resp.data['code'] == 1) {
                        final sp = await SharedPreferences.getInstance();
                        await sp.setString('square_nickname', nick);
                        _nickname = nick;
                        if (ctx.mounted) Navigator.pop(ctx, 'ok');
                      } else {
                        if (ctx.mounted) {
                          Navigator.pop(ctx, '失败：${resp.data['msg'] ?? '未知错误'}');
                        }
                      }
                    } catch (e) {
                      if (ctx.mounted) Navigator.pop(ctx, '网络错误，请重试');
                    }
                  },
                  child: const Text('发布',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (ok == 'ok') {
      _toast('发布成功 🎉');
      _fetchPosts(reset: true);
    } else if (ok == 'empty') {
      _toast('请输入内容再发布');
    } else if (ok != null && ok != false) {
      _toast('$ok');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  /// 相对时间
  String _relTime(dynamic ts) {
    final t = int.tryParse('$ts') ?? 0;
    if (t <= 0) return '';
    final diff = DateTime.now().millisecondsSinceEpoch ~/ 1000 - t;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return '${diff ~/ 60} 分钟前';
    if (diff < 86400) return '${diff ~/ 3600} 小时前';
    if (diff < 86400 * 30) return '${diff ~/ 86400} 天前';
    final d = DateTime.fromMillisecondsSinceEpoch(t * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('广场', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: '发动态',
            onPressed: _showComposeSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : EasyRefresh(
              controller: _refreshController,
              onRefresh: () => _fetchPosts(reset: true),
              onLoad: () async {
                _page++;
                await _fetchPosts();
                _refreshController.finishLoad();
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildShortcuts();
                  return _buildPostCard(_posts[index - 1], isDark, scheme);
                },
              ),
            ),
    );
  }

  /// 快捷双卡片
  Widget _buildShortcuts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          _shortcutCard(Icons.edit_note_rounded, '写篇文章',
              '创作你的技术分享', const [Color(0xFF465CFF), Color(0xFF7B8CFF)]),
          const SizedBox(width: 12),
          _shortcutCard(Icons.forum_rounded, '发个动态',
              '分享你的精彩生活', const [Color(0xFFFE5F14), Color(0xFFFF9A66)]),
        ],
      ),
    );
  }

  Widget _shortcutCard(IconData icon, String title, String sub, List<Color> gradient) {
    return Expanded(
      child: InkWell(
        onTap: _showComposeSheet,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: gradient.first.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  /// 动态卡片
  Widget _buildPostCard(Map<String, dynamic> p, bool isDark, ColorScheme scheme) {
    final likes = int.tryParse('${p['like_count']}') ?? 0;
    final comments = int.tryParse('${p['comment_count']}') ?? 0;
    final nick = '${p['nickname'] ?? '匿名用户'}';
    return InkWell(
      onTap: () => _showComments(p),
      borderRadius: BorderRadius.circular(18),
      child: Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 40, height: 40,
                  color: scheme.primaryContainer,
                  alignment: Alignment.center,
                  child: Text(nick.isEmpty ? '?' : nick.substring(0, 1),
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nick,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: isDark ? Colors.white : Colors.black87)),
                    Text(_relTime(p['createtime']),
                        style: TextStyle(
                            fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${p['content'] ?? ''}',
              style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: isDark ? Colors.grey[200] : Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () => _like(p),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.favorite_border, size: 18, color: Color(0xFFFE5F14)),
                    const SizedBox(width: 4),
                    Text('$likes',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ]),
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _showComments(p),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('$comments',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// 评论列表弹窗
  Future<void> _showComments(Map<String, dynamic> post) async {
    List<Map<String, dynamic>> comments = [];
    try {
      final resp = await _dio.get('/api/softlib/post/comment_list',
          queryParameters: {'post_id': post['id']});
      if (resp.data['code'] == 1 && resp.data['data'] is List) {
        comments = List<Map<String, dynamic>>.from(
            (resp.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final ctrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== 帖子详情头部 =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                Theme.of(ctx).colorScheme.primaryContainer,
                            child: Text(
                              '${post['nickname'] ?? '?'}'.substring(0, 1),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(ctx).colorScheme.onPrimaryContainer),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${post['nickname'] ?? '匿名用户'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const Spacer(),
                          Text(_relTime(post['createtime']),
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('${post['content'] ?? ''}',
                          style: const TextStyle(fontSize: 15, height: 1.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('评论 ${comments.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Expanded(
                  child: comments.isEmpty
                      ? const Center(
                          child: Text('还没有评论，快来抢沙发~',
                              style: TextStyle(color: Colors.grey)))
                      : ListView(
                          children: comments
                              .map((c) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${c['nickname']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text('${c['content']}',
                                            style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ))
                              .toList()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: '写评论…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF465CFF),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 13)),
                      onPressed: () async {
                        final text = ctrl.text.trim();
                        if (text.isEmpty) return;
                        try {
                          final resp = await _dio.post('/api/softlib/post/comment',
                              data: {'post_id': post['id'], 'content': text});
                          if (resp.data['code'] == 1) {
                            comments.add({
                              'nickname': _nickname.isEmpty ? '我' : _nickname,
                              'content': text,
                            });
                            post['comment_count'] =
                                (int.tryParse('${post['comment_count']}') ?? 0) + 1;
                            ctrl.clear();
                            setState(() {});
                          }
                        } catch (_) {}
                      },
                      child: const Text('发送', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
