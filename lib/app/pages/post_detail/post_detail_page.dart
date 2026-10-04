import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../api/post_service.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import '../../utils/toast_util.dart';
import '../../api/user_service.dart';
import '../../models/post_item.dart';
import '../navigate/square/emoji_panel.dart';

/// 动态详情页（正文 + 图片 + 评论区）
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _svc = PostService.instance;

  PostItem? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  final _ctrl = TextEditingController();
  bool _sending = false;
  String _err = '';
  final List<String> _images = [];
  final List<File> _imageFiles = [];
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = int.tryParse('${Get.arguments?['id']}') ?? 0;
    if (id <= 0) {
      setState(() => _loading = false);
      return;
    }
    final d = await _svc.fetchDetail(id);
    final cs = await _svc.comments(id);
    if (!mounted) return;
    setState(() {
      _post = d;
      _comments = cs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('动态详情', style: Ty.h3),
        actions: [
          if (_canDelete())
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 21),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: _loading
          ? const LoadingState(text: '正在加载动态…')
          : (_post == null
              ? const EmptyState(
                  text: '动态不存在或已删除',
                  hint: '内容可能已被作者删除',
                  icon: Icons.article_outlined,
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                        children: [
                          _postCard(),
                          const SizedBox(height: 12),
                          _commentHeader(),
                          const SizedBox(height: 8),
                          if (_comments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: EmptyState(
                                text: '还没有评论，快来抢沙发~',
                                hint: '说说你的看法吧',
                                icon: Icons.chat_bubble_outline_rounded,
                              ),
                            )
                          else
                            ..._comments.map((c) => _commentTile(c)),
                        ],
                      ),
                    ),
                    _inputBar(),
                  ],
                )),
    );
  }

  Widget _postCard() {
    final p = _post!;
    return KitCard(
      padding: const EdgeInsets.all(15),
      radius: R.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: p.avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.avatar, width: 40, height: 40, fit: BoxFit.cover)
                    : Container(
                        width: 40,
                        height: 40,
                        color: C.brand.withAlpha(26),
                        child: const Icon(Icons.person,
                            size: 21, color: C.brand),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                              p.nickname.isEmpty ? '匿名用户' : p.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Ty.body.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: context.t1)),
                        ),
                        if (p.isAdmin) ...[
                          const SizedBox(width: 5),
                          const Pill('管理',
                              color: C.danger, solid: true, small: true),
                        ],
                        if (p.isVip) ...[
                          const SizedBox(width: 4),
                          const Pill('VIP',
                              color: C.gold, solid: true, small: true),
                        ],
                        if (p.title.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Pill(p.title, color: C.brand, small: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.catTitle.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: C.brand.withAlpha(22),
                              borderRadius: BorderRadius.circular(R.xs),
                            ),
                            child: Text(p.catTitle,
                                style: Ty.tiny.copyWith(
                                    fontSize: 10,
                                    color: C.brand,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(p.relTime, style: Ty.tiny.copyWith(color: context.t3)),
                        const SizedBox(width: 8),
                        Icon(Icons.visibility_outlined, size: 12, color: context.t3),
                        const SizedBox(width: 3),
                        Text('${p.views}',
                            style: Ty.tiny.copyWith(color: context.t3)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.content,
                style: Ty.body.copyWith(
                    fontSize: 15, height: 1.65, color: context.t1)),
          ],
          if (p.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final img in p.images)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _preview(img),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(R.sm),
                    child: CachedNetworkImage(
                      imageUrl: img,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(height: 180, color: Colors.black12),
                      errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.black12,
                          child: const Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          Divider(
              height: 1,
              color: context.isDark
                  ? Colors.white.withAlpha(25)
                  : Colors.black.withAlpha(20)),
          const SizedBox(height: 8),
          Row(
            children: [
              _action(Icons.favorite_border_rounded, '${p.likeCount}', () async {
                final n = await _svc.like(p.id);
                if (n != null && mounted) {
                  setState(() => _post = PostItem(
                        id: p.id,
                        nickname: p.nickname,
                        avatar: p.avatar,
                        content: p.content,
                        images: p.images,
                        catId: p.catId,
                        catTitle: p.catTitle,
                        likeCount: n,
                        commentCount: p.commentCount,
                        views: p.views,
                        createtime: p.createtime,
                      ));
                }
              }),
              const SizedBox(width: 20),
              _action(Icons.chat_bubble_outline_rounded, '${p.commentCount}', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Row(children: [
            Icon(icon, size: 17, color: context.t3),
            const SizedBox(width: 4),
            Text(label, style: Ty.small.copyWith(fontSize: 12.5, color: context.t2)),
          ]),
        ),
      );

  Widget _commentHeader() =>
      const SectionHeader(title: '评论', accent: C.brand);

  Widget _commentTile(Map<String, dynamic> c) {
    final avatar = (c['avatar'] ?? '').toString();
    return KitCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      radius: R.sm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: avatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatar, width: 32, height: 32, fit: BoxFit.cover)
                : Container(
                    width: 32,
                    height: 32,
                    color: C.brand.withAlpha(26),
                    child: const Icon(Icons.person, size: 17, color: C.brand)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['nickname'] ?? '匿名用户'}',
                    style: Ty.small.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.t1)),
                const SizedBox(height: 4),
                Text('${c['content'] ?? ''}',
                    style: Ty.body.copyWith(fontSize: 14, height: 1.5)),
                if (c['images'] is List && (c['images'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (c['images'] as List)
                          .map((u) => ClipRRect(
                                borderRadius: BorderRadius.circular(R.xs),
                                child: CachedNetworkImage(
                                  imageUrl: '$u',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.black12),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDark ? 60 : 12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_err,
                    style: Ty.tiny.copyWith(fontSize: 12, color: C.danger)),
              ),
            // 已选图片预览
            if (_images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(R.xs),
                          child: Image.file(File(_images[i]),
                              width: 62, height: 62, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _images.removeAt(i);
                              _imageFiles.removeAt(i);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // 表情面板
            if (_showEmoji)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EmojiPanel(
                  onPick: (e) {
                    _ctrl.text += e;
                    _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _ctrl.text.length));
                    setState(() {});
                  },
                ),
              ),
            Row(
              children: [
                // 图片按钮
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.image_outlined,
                        size: 22, color: context.t3),
                  ),
                ),
                // 表情按钮
                GestureDetector(
                  onTap: () => setState(() => _showEmoji = !_showEmoji),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.emoji_emotions_outlined,
                        size: 22,
                        color: _showEmoji ? C.brand : context.t3),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: '写评论…',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.full)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: PrimaryButton(
                    label: '发送',
                    height: 42,
                    loading: _sending,
                    enabled: !_sending,
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 是否可删除（作者本人或管理员）
  bool _canDelete() {
    final p = _post;
    if (p == null) return false;
    final u = UserService.instance.user;
    return u != null && (p.userId == u.id || u.isAdmin);
  }

  Future<void> _deletePost() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('删除动态'),
      content: const Text('确定删除这条动态吗？评论也会一并删除。'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false), child: const Text('取消')),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.danger),
            onPressed: () => Get.back(result: true),
            child: const Text('删除')),
      ],
    ));
    if (ok != true) return;
    final done = await _svc.deletePost(_post!.id);
    if (done) {
      ToastUtil.success('已删除');
      Get.back();
    } else {
      ToastUtil.error('删除失败');
    }
  }

  Future<void> _pickImages() async {
    try {
      final picked =
          await ImagePicker().pickMultiImage(imageQuality: 82);
      if (picked.isEmpty) return;
      for (final f in picked) {
        if (_images.length >= 6) break;
        _images.add(f.path);
        _imageFiles.add(File(f.path));
      }
      setState(() {});
    } catch (_) {
      setState(() => _err = '选择图片失败，请允许相册权限');
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _err = '请输入评论内容');
      return;
    }
    final user = UserService.instance.user;
    setState(() {
      _sending = true;
      _err = '';
    });
    // 上传图片
    final urls = <String>[];
    try {
      for (final f in List<File>.from(_imageFiles)) {
        urls.add(await PostService.instance.uploadImage(f));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _err = '图片上传失败'; 
        });
      }
      return;
    }
    final ok = await _svc.comment(
      postId: _post!.id,
      nickname: user?.nickname ?? '匿名用户',
      content: text,
      avatar: user?.avatar ?? '',
      images: urls,
    );
    if (!mounted) return;
    if (ok) {
      _ctrl.clear();
      setState(() {
        _sending = false;
        _showEmoji = false;
        _comments.add({
          'nickname': user?.nickname ?? '匿名用户',
          'avatar': user?.avatar ?? '',
          'content': text,
          'images': urls,
        });
        _images.clear();
        _imageFiles.clear();
      });
    } else {
      setState(() {
        _sending = false;
        _err = '评论失败，请重试';
      });
    }
  }

  void _preview(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: Get.back,
        child: Container(
          color: Colors.black.withAlpha(220),
          child: Center(child: PhotoView(imageProvider: NetworkImage(url))),
        ),
      ),
    );
  }
}
