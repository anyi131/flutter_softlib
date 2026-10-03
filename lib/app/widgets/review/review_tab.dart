import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../api/review_service.dart';
import '../../api/user_service.dart';
import '../../models/review_item.dart';
import '../../routes/app_pages.dart';
import 'star_rating.dart';

/// 评价 Tab（评分卡 + 筛选 + 评论列表）
class ReviewTab extends StatefulWidget {
  final int appId;
  const ReviewTab({super.key, required this.appId});

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  static const Color kBrand = Color(0xFF465CFF);
  final ReviewService _svc = ReviewService.instance;

  ReviewSummary _summary = ReviewSummary.empty();
  List<ReviewItem> _list = [];
  String _filter = 'all';
  String _sort = 'latest';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _svc.summary(widget.appId);
    final l = await _svc.list(widget.appId, filter: _filter, sort: _sort);
    if (!mounted) return;
    setState(() {
      _summary = s;
      _list = l;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    // 注意：本组件嵌在外层 ListView 中，必须用 Column（不能用 ListView 嵌套）
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _summaryCard(isDark),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('用户评价',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: _toggleSort,
              child: Row(
                children: [
                  Text(_sort == 'latest' ? '最新' : '最热',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                  Icon(Icons.swap_vert, size: 15, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _filterRow(),
        const SizedBox(height: 12),
        if (_list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 46, color: Colors.grey.withAlpha(90)),
                const SizedBox(height: 10),
                Text('还没有评价，来写第一条吧',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13.5)),
              ],
            ),
          )
        else
          ..._list.map((r) => _reviewTile(r, isDark)),
        ],
      ),
    );
  }

  void _toggleSort() {
    setState(() => _sort = _sort == 'latest' ? 'hot' : 'latest');
    _load();
  }

  // ===== 评分卡 =====
  Widget _summaryCard(bool isDark) {
    final total = _summary.count;
    final good = _summary.good;
    final mid = _summary.mid;
    final bad = _summary.bad;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧大分数
              Column(
                children: [
                  Text(
                    total > 0 ? _summary.avg.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 6),
                  StarRating(score: _summary.avg, size: 13),
                ],
              ),
              const SizedBox(width: 18),
              // 右侧进度条
              Expanded(
                child: Column(
                  children: [
                    _bar(good, total, const Color(0xFF465CFF)),
                    const SizedBox(height: 5),
                    _bar(mid, total, const Color(0xFFFFB300)),
                    const SizedBox(height: 5),
                    _bar(bad, total, const Color(0xFFEF4444)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // 写评论按钮
              GestureDetector(
                onTap: _openCompose,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBrand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('写评论',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 3),
                      Icon(Icons.add_circle, size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.withAlpha(30)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$total 人参与了评分',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(width: 14),
              Text('${_summary.goodRate}% 好评率',
                  style: TextStyle(
                      fontSize: 12,
                      color: kBrand,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(int value, int total, Color color) {
    final ratio = total > 0 ? value / total : 0.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ),
      ],
    );
  }

  // ===== 筛选 =====
  Widget _filterRow() {
    final items = [
      ('all', '全部', _summary.count),
      ('good', '好评', _summary.good),
      ('mid', '中评', _summary.mid),
      ('bad', '差评', _summary.bad),
    ];
    return Row(
      children: items.map((e) {
        final sel = _filter == e.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (_filter == e.$1) return;
              setState(() => _filter = e.$1);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? kBrand : Colors.grey.withAlpha(28),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${e.$2}${e.$3 > 0 ? ' ${e.$3}' : ''}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===== 单条评价 =====
  Widget _reviewTile(ReviewItem r, bool isDark) {
    final myId = UserService.instance.user?.id ?? 0;
    final isAdmin = UserService.instance.user?.isAdmin == true;
    final canDelete = r.userId == myId || isAdmin;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: r.avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: r.avatar,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover)
                    : Container(
                        width: 36,
                        height: 36,
                        color: kBrand.withAlpha(26),
                        child:
                            const Icon(Icons.person, size: 19, color: kBrand)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nickname.isEmpty ? '匿名用户' : r.nickname,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        StarRating(score: r.score.toDouble(), size: 12.5),
                        const SizedBox(width: 6),
                        Text('${r.score}.0',
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF8F00))),
                        const SizedBox(width: 5),
                        Text(r.levelText,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: r.level == 'good'
                                    ? const Color(0xFF0E9F6E)
                                    : (r.level == 'mid'
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFFDC2626)))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.content,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.grey[200] : const Color(0xFF2C2C2C))),
          ],
          if (r.images.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: r.images
                  .map((u) => GestureDetector(
                        onTap: () => _preview(u),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: CachedNetworkImage(
                            imageUrl: u,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(width: 76, color: Colors.black12),
                            errorWidget: (_, __, ___) => Container(
                                width: 76,
                                height: 76,
                                color: Colors.black12,
                                child: const Icon(Icons.broken_image, size: 18)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          // ===== 回复列表 =====
          if (r.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF6F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: r.replies
                    .map((rp) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.55,
                                color: isDark
                                    ? Colors.grey[300]
                                    : const Color(0xFF3C4043),
                              ),
                              children: [
                                TextSpan(
                                  text: rp.nickname,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: kBrand),
                                ),
                                if (rp.replyTo.isNotEmpty)
                                  TextSpan(
                                    text: ' 回复 ${rp.replyTo}',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12),
                                  ),
                                TextSpan(text: '：${rp.content}'),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Text(r.timeText,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
              const SizedBox(width: 16),
              _miniBtn('回复', () => _openReply(r)),
              if (canDelete) ...[
                const SizedBox(width: 12),
                _miniBtn('删除', () async {
                  final ok = await _svc.remove(r.id);
                  if (ok) {
                    _load();
                    _toast('已删除');
                  } else {
                    _toast('删除失败');
                  }
                }, color: const Color(0xFFDC2626)),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final n = await _svc.like(r.id);
                  if (n != null) setState(() => _load());
                },
                child: Row(
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text('${r.likeCount}',
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(String label, VoidCallback onTap, {Color? color}) =>
      GestureDetector(
        onTap: onTap,
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                color: color ?? const Color(0xFF6B7280),
                fontWeight: FontWeight.w600)),
      );

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  // ===== 回复弹窗 =====
  Future<void> _openReply(ReviewItem r) async {
    if (!UserService.instance.isLoggedIn) {
      final go = await Get.dialog<bool>(AlertDialog(
        title: const Text('需要登录'),
        content: const Text('回复需要先登录账号'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('去登录')),
        ],
      ));
      if (go == true) await Get.toNamed(Routes.login);
      if (!UserService.instance.isLoggedIn) return;
    }
    final ctrl = TextEditingController();
    bool sending = false;
    String err = '';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('回复 ${r.nickname}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 3,
                maxLength: 500,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '写下你的回复…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (err.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(err,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDC2626))),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kBrand),
              onPressed: sending
                  ? null
                  : () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) {
                        setD(() => err = '请输入回复内容');
                        return;
                      }
                      setD(() {
                        sending = true;
                        err = '';
                      });
                      try {
                        await _svc.reply(
                            reviewId: r.id,
                            content: text,
                            replyTo: '');
                        if (ctx.mounted) Navigator.pop(ctx);
                        _toast('回复成功');
                        _load();
                      } catch (e) {
                        setD(() {
                          sending = false;
                          err = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('发送'),
            ),
          ],
        );
      }),
    );
  }

  // ===== 写评论弹窗 =====
  Future<void> _openCompose() async {
    if (!UserService.instance.isLoggedIn) {
      final go = await Get.dialog<bool>(AlertDialog(
        title: const Text('需要登录'),
        content: const Text('评价软件需要先登录账号'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Get.back(result: true), child: const Text('去登录')),
        ],
      ));
      if (go == true) await Get.toNamed(Routes.login);
      if (!UserService.instance.isLoggedIn) return;
    }

    int score = 5;
    final ctrl = TextEditingController();
    final images = <String>[];
    final files = <File>[];
    bool sending = false;
    String err = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        const emojis = ['😀', '😄', '😊', '😍', '🤩', '😎', '👍', '🔥', '💯', '🎉', '❤️', '🙏', '😅', '🤔', '😭', '😡'];

        Future<void> pick() async {
          try {
            final picked = await ImagePicker().pickMultiImage(imageQuality: 82);
            if (picked.isEmpty) return;
            for (final f in picked) {
              if (images.length >= 6) break;
              files.add(File(f.path));
              images.add(f.path);
            }
            setD(() {});
          } catch (e) {
            setD(() => err = '选择图片失败，请允许相册权限');
          }
        }

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('写评论',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 评分
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('给这个软件打分',
                          style: TextStyle(fontSize: 13.5)),
                      const Spacer(),
                      StarInput(
                          value: score,
                          size: 24,
                          onChanged: (v) => setD(() => score = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '请输入评论内容',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                // 已选图片
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < images.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(images[i]),
                                  width: 58, height: 58, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setD(() {
                                  images.removeAt(i);
                                  files.removeAt(i);
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
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const Text('选择表情',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 2,
                  children: emojis
                      .map((e) => InkWell(
                            onTap: () {
                              ctrl.text += e;
                              setD(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(e,
                                  style: const TextStyle(fontSize: 21)),
                            ),
                          ))
                      .toList(),
                ),
                if (err.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(err,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDC2626))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : pick,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 17),
                  SizedBox(width: 4),
                  Text('图片'),
                ],
              ),
            ),
            TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kBrand),
              onPressed: sending
                  ? null
                  : () async {
                      final content = ctrl.text.trim();
                      if (content.isEmpty && images.isEmpty) {
                        setD(() => err = '请输入评论内容或添加图片');
                        return;
                      }
                      setD(() {
                        sending = true;
                        err = '';
                      });
                      try {
                        final urls = <String>[];
                        for (final f in List<File>.from(files)) {
                          urls.add(await _svc.uploadImage(f));
                        }
                        await _svc.create(
                          appId: widget.appId,
                          score: score,
                          content: content,
                          images: urls,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _toast('评论成功 ✅');
                        _load();
                      } catch (e) {
                        setD(() {
                          sending = false;
                          err = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('发布'),
            ),
          ],
        );
      }),
    );
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
