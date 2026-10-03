import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../design/app_theme.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../api/post_service.dart';
import '../../design/ui.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.bgDark : AppColor.bgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('动态详情',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : (_post == null
              ? const Center(child: Text('动态不存在或已删除'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                        children: [
                          _postCard(isDark),
                          const SizedBox(height: 12),
                          _commentHeader(),
                          const SizedBox(height: 8),
                          if (_comments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 34),
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 44, color: Colors.grey.withAlpha(90)),
                                  const SizedBox(height: 10),
                                  Text('还没有评论，快来抢沙发~',
                                      style: TextStyle(
                                          color: Colors.grey[500], fontSize: 13.5)),
                                ],
                              ),
                            )
                          else
                            ..._comments.map((c) => _commentTile(c, isDark)),
                        ],
                      ),
                    ),
                    _inputBar(isDark),
                  ],
                )),
    );
  }

  Widget _postCard(bool isDark) {
    final p = _post!;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColor.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
                        color: AppColor.primary.withAlpha(26),
                        child: Icon(Icons.person, size: 21, color: AppColor.primary),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nickname.isEmpty ? '匿名用户' : p.nickname,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.catTitle.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withAlpha(22),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(p.catTitle,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(p.relTime,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                        Icon(Icons.visibility_outlined,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text('${p.views}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
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
                style: TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: isDark ? Colors.grey[200] : const Color(0xFF2C2C2C))),
          ],
          if (p.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final img in p.images)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _preview(img),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
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
          Divider(height: 1, color: Colors.grey.withAlpha(25)),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Row(children: [
            Icon(icon, size: 17, color: const Color(0xFF8A8F98)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
          ]),
        ),
      );

  Widget _commentHeader() => Row(
        children: [
          Container(
            width: 3.5,
            height: 15,
            decoration: BoxDecoration(
                color: AppColor.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text('评论 ${_comments.length}',
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _commentTile(Map<String, dynamic> c, bool isDark) {
    final avatar = (c['avatar'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColor.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
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
                    color: AppColor.primary.withAlpha(26),
                    child: Icon(Icons.person, size: 17, color: AppColor.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['nickname'] ?? '匿名用户'}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${c['content'] ?? ''}',
                    style: const TextStyle(fontSize: 14, height: 1.5)),
                if (c['images'] is List && (c['images'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (c['images'] as List)
                          .map((u) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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

  Widget _inputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColor.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 12),
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
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFDC2626))),
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
                          borderRadius: BorderRadius.circular(9),
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
                          borderRadius: BorderRadius.circular(22)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('发送',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
