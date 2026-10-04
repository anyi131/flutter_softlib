import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api/post_service.dart';
import '../../../api/user_service.dart';
import '../../../models/post_item.dart';
import '../../../routes/app_pages.dart';
import '../../../design/adaptive.dart';
import '../../../design/kit.dart';
import '../../../design/ui.dart';
import '../../../widgets/tab_bottom_pad.dart';
import 'emoji_panel.dart';

/// 广场 - 社区动态
class SquareComponent extends StatefulWidget {
  const SquareComponent({super.key});

  @override
  State<SquareComponent> createState() => _SquareComponentState();
}

class _SquareComponentState extends State<SquareComponent> {
  final PostService _svc = PostService.instance;
  final EasyRefreshController _refresh =
      EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);

  List<PostCat> _cats = [];
  List<PostItem> _posts = [];
  int _currentCat = 0;
  int _page = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCats();
    _load(reset: true);
  }

  Future<void> _loadCats() async {
    final cats = await _svc.fetchCats();
    if (!mounted) return;
    setState(() => _cats = cats);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    try {
      final list = await _svc.fetchPosts(page: _page, catId: _currentCat);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _posts = list;
        } else {
          _posts.addAll(list);
        }
        _loading = false;
      });
      reset ? _refresh.finishRefresh() : _refresh.finishLoad(
          list.length < 20 ? IndicatorResult.noMore : IndicatorResult.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      reset ? _refresh.finishRefresh() : _refresh.finishLoad();
    }
  }

  void _switchCat(int id) {
    if (_currentCat == id) return;
    setState(() {
      _currentCat = id;
      _posts = [];
      _loading = true;
    });
    _load(reset: true);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _topBar(),
                _catBar(isDark),
                Expanded(child: _body(isDark)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: context.tabSpace - 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: Deco.brandGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: C.brand.withAlpha(110),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: _compose,
            child: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, 14, context.pagePadding, 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('广场', style: Ty.display.copyWith(color: context.t1)),
                const SizedBox(height: 4),
                Text('交流分享 · 发现好软',
                    style: Ty.small.copyWith(color: context.t3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catBar(bool isDark) {
    if (_cats.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _cats[i];
          final sel = _currentCat == c.id;
          return GestureDetector(
            onTap: () => _switchCat(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: sel ? Deco.brandGradient : null,
                color: sel
                    ? null
                    : (isDark ? C.bg3 : Colors.white),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Text(
                c.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color:
                      sel ? Colors.white : (isDark ? C.t2 : const Color(0xFF4B5563)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(bool isDark) {
    if (_loading) {
      return const LoadingState(text: '正在加载动态…');
    }
    if (_posts.isEmpty) {
      return const EmptyState(
        text: '还没有动态，快来发第一条',
        hint: '分享你的想法，让大家看到',
        icon: Icons.forum_outlined,
      );
    }
    return EasyRefresh(
      controller: _refresh,
      onRefresh: () => _load(reset: true),
      onLoad: () async {
        _page++;
        await _load();
      },
      child: ListView.builder(
        padding: EdgeInsets.only(top: 4, bottom: tabBottomPadding(context) + 60),
        itemCount: _posts.length,
        // ★ RepaintBoundary：每张卡片独立图层，滚动时不会整列重绘
        //   （信息流掉帧最常见的成因）
        itemBuilder: (context, i) => RepaintBoundary(
          child: _postCard(_posts[i], isDark),
        ),
      ),
    );
  }

  Widget _postCard(PostItem p, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, 6, context.pagePadding, 6),
      child: Deco.glass(
        context,
        radius: R.lg,
        alpha: 0.06,
        child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(R.lg),
        child: InkWell(
        borderRadius: BorderRadius.circular(R.lg),
        onTap: () async {
          await Get.toNamed(Routes.postDetail, arguments: {'id': p.id, 'item': p});
          _load(reset: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：头像 + 昵称 + 分类/时间
              Row(
                children: [
                  ClipOval(
                    child: p.avatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.avatar, width: 38, height: 38, fit: BoxFit.cover)
                        : _avatar(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // ★ 昵称弹性收缩，徽章固定宽度不参与挤压，
                            //   避免长昵称 + 多个头衔导致 Row 溢出
                            Flexible(
                              child: Text(
                                  p.nickname.isEmpty ? '匿名用户' : p.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Ty.h3.copyWith(color: context.t1)),
                            ),
                            if (p.isAdmin) ...[
                              const SizedBox(width: 5),
                              const Pill('管理',
                                  color: C.danger, small: true),
                            ],
                            if (p.isVip) ...[
                              const SizedBox(width: 4),
                              const Pill('VIP',
                                  color: C.amber, small: true, solid: true),
                            ],
                            if (p.title.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Pill(p.title, color: C.brand, small: true),
                              ),
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
                                  borderRadius: BorderRadius.circular(R.xs / 2),
                                ),
                                child: Text(p.catTitle,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: C.brand,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(p.relTime,
                                style: Ty.tiny.copyWith(color: context.t3)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (p.content.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(p.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.5,
                        height: 1.55,
                        color: context.t1)),
              ],
              // 图片九宫格
              if (p.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                _imageGrid(p.images),
              ],
              const SizedBox(height: 10),
              Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withAlpha(14)
                      : Colors.black.withAlpha(8)),
              const SizedBox(height: 8),
              // 底部：点赞 + 评论 + 浏览
              Row(
                children: [
                  _action(
                    icon: Icons.favorite_border_rounded,
                    label: '${p.likeCount}',
                    onTap: () async {
                      final n = await _svc.like(p.id);
                      if (n != null && mounted) {
                        setState(() => _posts[_posts.indexOf(p)] =
                            PostItem(
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
                    },
                  ),
                  const SizedBox(width: 20),
                  _action(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${p.commentCount}',
                    onTap: () async {
                      await Get.toNamed(Routes.postDetail,
                          arguments: {'id': p.id, 'item': p});
                      _load(reset: true);
                    },
                  ),
                  const Spacer(),
                  Icon(Icons.visibility_outlined,
                      size: 13, color: context.t3),
                  const SizedBox(width: 3),
                  Text('${p.views}',
                      style: Ty.tiny.copyWith(color: context.t3)),
                ],
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageGrid(List<String> images) {
    final n = images.length;
    if (n == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(R.sm),
        child: CachedNetworkImage(
            imageUrl: images[0], height: 180, fit: BoxFit.cover),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: n > 9 ? 9 : n,
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(R.xs),
        child: CachedNetworkImage(
          imageUrl: images[i],
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.black12),
          errorWidget: (_, __, ___) => Container(
              color: Colors.black12,
              child: const Icon(Icons.broken_image, size: 18)),
        ),
      ),
    );
  }

  Widget _action(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(R.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 17, color: context.t3),
            const SizedBox(width: 4),
            Text(label, style: Ty.small.copyWith(color: context.t2)),
          ],
        ),
      ),
    );
  }

  Widget _avatar() => Container(
        width: 38,
        height: 38,
        color: C.brand.withAlpha(26),
        child: const Icon(Icons.person, size: 20, color: C.brand),
      );

  // ================= 发布 =================
  Future<void> _compose() async {
    if (!UserService.instance.isLoggedIn) {
      final go = await Get.dialog<bool>(AlertDialog(
        title: const Text('需要登录'),
        content: const Text('发布动态需要先登录账号'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('去登录')),
        ],
      ));
      if (go == true) await Get.toNamed(Routes.login);
      if (!UserService.instance.isLoggedIn) return;
    }
    final user = UserService.instance.user;
    final contentCtrl = TextEditingController();
    final List<String> images = [];
    final List<File> localImages = [];
    int catId = _currentCat == 0 ? 2 : _currentCat;
    bool sending = false;
    String err = '';
    bool showEmoji = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> pickImage() async {
          try {
            final picker = ImagePicker();
            final files = await picker.pickMultiImage(imageQuality: 82);
            if (files.isEmpty) return;
            for (final f in files) {
              if (images.length >= 9) break;
              localImages.add(File(f.path));
              images.add(f.path);
            }
            setSheet(() {});
          } catch (e) {
            setSheet(() => err = '选择图片失败：请在设置中允许相册权限');
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: ctx.isDark ? C.bg2 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(R.lg)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('发布动态', style: Ty.h3.copyWith(color: ctx.t1)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: ctx.t2),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                // 分类
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cats.where((c) => c.id != 0).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (_, i) {
                      final c = _cats.where((e) => e.id != 0).toList()[i];
                      final sel = catId == c.id;
                      return GestureDetector(
                        onTap: () => setSheet(() => catId = c.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel
                                ? C.brand
                                : (ctx.isDark ? C.bg3 : C.lbg2),
                            borderRadius: BorderRadius.circular(R.md),
                          ),
                          child: Text(c.title,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight:
                                      sel ? FontWeight.w800 : FontWeight.w500,
                                  color: sel ? Colors.white : ctx.t2)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  maxLength: 2000,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '分享你的想法…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.sm)),
                  ),
                ),
                // 已选图片
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (int i = 0; i < images.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(File(images[i]),
                                  width: 74, height: 74, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => setSheet(() {
                                  images.removeAt(i);
                                  localImages.removeAt(i);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 13, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                // 表情面板
                if (showEmoji)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: EmojiPanel(
                      onPick: (e) {
                        contentCtrl.text += e;
                        contentCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: contentCtrl.text.length));
                        setSheet(() {});
                      },
                    ),
                  ),
                if (err.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: C.danger.withAlpha(22),
                      borderRadius: BorderRadius.circular(R.sm),
                    ),
                    child: Text(err,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: C.danger,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: pickImage,
                      icon: Icon(Icons.image_outlined, color: ctx.t2),
                      tooltip: '添加图片',
                    ),
                    IconButton(
                      onPressed: () => setSheet(() => showEmoji = !showEmoji),
                      icon: Icon(Icons.emoji_emotions_outlined,
                          color: showEmoji ? C.brand : ctx.t2),
                      tooltip: '表情',
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 116,
                      child: PrimaryButton(
                        label: '发布',
                        icon: Icons.send_rounded,
                        loading: sending,
                        height: 44,
                        onPressed: () async {
                          final text = contentCtrl.text.trim();
                          if (text.isEmpty && images.isEmpty) {
                            setSheet(() => err = '请输入内容或添加图片');
                            return;
                          }
                          setSheet(() {
                            sending = true;
                            err = '';
                          });
                          try {
                            // 先上传本地图片
                            final urls = <String>[];
                            for (int i = 0; i < images.length; i++) {
                              if (images[i].startsWith('http')) {
                                urls.add(images[i]);
                              } else {
                                urls.add(await PostService.instance
                                    .uploadImage(localImages.removeAt(0)));
                              }
                            }
                            await _svc.create(
                              nickname: user?.nickname ?? '匿名用户',
                              content: text,
                              images: urls,
                              catId: catId,
                              avatar: user?.avatar ?? '',
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              _toast('发布成功 🎉');
                              _load(reset: true);
                            }
                          } catch (e) {
                            setSheet(() {
                              sending = false;
                              err = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
