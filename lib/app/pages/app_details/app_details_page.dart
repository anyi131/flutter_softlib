import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

import '../../api/user_service.dart';
import '../../models/app_item.dart';
import '../../routes/app_pages.dart';
import 'app_details_logic.dart';

/// 软件详情页
class AppDetailsPage extends StatefulWidget {
  const AppDetailsPage({super.key});

  @override
  State<AppDetailsPage> createState() => _AppDetailsPageState();
}

class _AppDetailsPageState extends State<AppDetailsPage>
    with SingleTickerProviderStateMixin {
  final AppDetailsLogic logic = Get.find<AppDetailsLogic>();
  late final TabController _tab = TabController(length: 2, vsync: this);

  static const Color kBrand = Color(0xFF465CFF);
  static const Color kVip = Color(0xFFC9A227);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  AppItem? get item => logic.item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF1F2F6);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(item?.title ?? '软件详情',
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 21),
            onPressed: () => logic.showSharePopUps(context),
          ),
        ],
      ),
      body: GetBuilder<AppDetailsLogic>(
        id: 'appInfo',
        builder: (logic) {
          if (logic.isLoadingInfo) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          }
          if (logic.appInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off,
                      size: 54, color: Colors.grey.withAlpha(110)),
                  const SizedBox(height: 12),
                  Text(logic.msgError ?? '获取软件信息失败',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 18),
                  FilledButton.tonal(
                      onPressed: logic.getAppInfo, child: const Text('重新加载')),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            children: [
              _hero(isDark),
              const SizedBox(height: 10),
              _info(isDark),
              const SizedBox(height: 10),
              _tabs(isDark),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottom(),
    );
  }

  // ============ 主卡 ============
  Widget _hero(bool isDark) {
    final it = item;
    final info = logic.appInfo;
    final isVipItem = it?.isVipItem ?? false;
    final icon = info?.fileIcon ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kBrand.withAlpha(isDark ? 70 : 45),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: icon.isEmpty
                      ? _phIcon()
                      : CachedNetworkImage(
                          imageUrl: icon,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _phIcon(),
                          errorWidget: (_, __, ___) => _phIcon(),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info?.fileName?.isNotEmpty == true
                          ? info!.fileName!
                          : (it?.title ?? '未知软件'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isVipItem)
                          _chip('会员专享', kVip, const Color(0xFFFFF4D6),
                              Icons.workspace_premium_rounded)
                        else
                          _chip('免费下载', const Color(0xFF0E9F6E),
                              const Color(0xFFE3F9F0),
                              Icons.download_done_rounded),
                        const SizedBox(width: 6),
                        _chip('安全无毒', const Color(0xFF2563EB),
                            const Color(0xFFE8EEFF), Icons.verified_rounded),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '版本 ${it?.version.isNotEmpty == true ? it!.version : '未知'}'
                      '${it?.uploadDate.isNotEmpty == true ? '  ·  ${it!.uploadDate}' : ''}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF5FF), Color(0xFFE8F0FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: Color(0xFF2563EB)),
                SizedBox(width: 7),
                Expanded(
                  child: Text('已通过安全检测 · 无病毒 · 无恶意插件',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ 数据卡 ============
  Widget _info(bool isDark) {
    final it = item;
    final info = logic.appInfo;
    final cells = [
      (Icons.sd_storage_rounded, info?.fileSize ?? it?.size ?? '-', '大小'),
      (Icons.visibility_rounded, '${it?.views ?? 0}', '浏览'),
      (Icons.schedule_rounded,
          it?.uploadDate.isNotEmpty == true ? it!.uploadDate : '-', '上传'),
      (Icons.face_rounded, it?.ageRating ?? '16+', '年龄'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.withAlpha(isDark ? 40 : 30),
              ),
            Expanded(
              child: Column(
                children: [
                  Icon(cells[i].$1, size: 17, color: kBrand.withAlpha(200)),
                  const SizedBox(height: 6),
                  Text(cells[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(cells[i].$3,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ Tab ============
  Widget _tabs(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TabBar(
              controller: _tab,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              indicatorColor: kBrand,
              labelColor: kBrand,
              unselectedLabelColor: Colors.grey[500],
              labelStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '详情'), Tab(text: '评论')],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: Colors.grey.withAlpha(30)),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tab,
              children: [_detail(isDark), _comments(isDark)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(bool isDark) {
    final info = logic.appInfo;
    final desc = info?.fileDesc ?? '';
    final shots = item?.screenshots ?? const <String>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 15,
              decoration: BoxDecoration(
                  color: kBrand, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            const Text('软件介绍',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kBrand.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('官方详情',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: kBrand,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          desc.isEmpty ? '暂无详细介绍' : desc,
          style: TextStyle(
            fontSize: 14,
            height: 1.9,
            letterSpacing: 0.1,
            color: isDark ? Colors.grey[300] : const Color(0xFF41454B),
          ),
        ),
        if (shots.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('应用截图',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _preview(shots[i]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: shots[i],
                    width: 130,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 130, color: Colors.black12),
                    errorWidget: (_, __, ___) => Container(
                      width: 130,
                      color: Colors.black12,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 14, color: Colors.grey[500]),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '下载前请确认软件名称与更新时间，安装包以当前详情页为准。',
                  style: TextStyle(
                      fontSize: 11.5, color: Colors.grey[600], height: 1.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comments(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 48, color: Colors.grey.withAlpha(95)),
          const SizedBox(height: 10),
          Text('暂无评论',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 4),
          Text('可以去广场发帖讨论哦',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  // ============ 底部：单个下载按钮（无左右双栏） ============
  Widget _bottom() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVipItem = item?.isVipItem ?? false;
    final loggedIn = UserService.instance.isLoggedIn;
    final isVipUser = UserService.instance.user?.isVip == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 12),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GetBuilder<AppDetailsLogic>(
          id: 'download',
          builder: (download) {
            final task = download.downloadTask;
            // 下载完成 → 安装
            if (task != null && task.status == DownloadTaskStatus.complete) {
              return _btn(
                label: '安装',
                color: const Color(0xFF0E9F6E),
                icon: Icons.install_mobile_rounded,
                onTap: download.openDownloadFile,
              );
            }
            // 下载中
            if (task != null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task.progress / 100,
                            minHeight: 7,
                            backgroundColor: Colors.grey.withAlpha(45),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 38,
                        child: Text('${task.progress}%',
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                      _iconBtn(
                        task.status == DownloadTaskStatus.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        task.status == DownloadTaskStatus.paused
                            ? download.resumeDownload
                            : download.pauseDownload,
                      ),
                      const SizedBox(width: 5),
                      _iconBtn(Icons.close_rounded, download.cancelDownload),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.status == DownloadTaskStatus.paused
                        ? '已暂停'
                        : (task.status == DownloadTaskStatus.failed
                            ? '下载失败'
                            : '正在下载…'),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              );
            }
            // 未下载
            final String label;
            final IconData icon;
            final Color color;
            if (isVipItem) {
              label = isVipUser ? '会员下载' : '开通会员下载';
              icon = Icons.workspace_premium_rounded;
              color = kVip;
            } else if (item?.isLocal == true) {
              label = '下载安装';
              icon = Icons.download_rounded;
              color = kBrand;
            } else {
              label = '解析并下载';
              icon = Icons.cloud_download_rounded;
              color = kBrand;
            }
            return _btn(
              label: label,
              color: color,
              icon: icon,
              onTap: () => _onDownload(isVipItem, loggedIn, isVipUser),
            );
          },
        ),
      ),
    );
  }

  Widget _btn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  void _onDownload(bool isVipItem, bool loggedIn, bool isVipUser) {
    if (isVipItem && !loggedIn) {
      _dialog('需要登录', '该资源为会员专享，请先登录账号', '去登录', Routes.login);
      return;
    }
    if (isVipItem && !isVipUser) {
      _dialog('会员专享资源', '该资源仅会员可下载，是否前往开通会员？', '去开通', Routes.vip);
      return;
    }
    logic.addDownload(logic.appInfo?.fileName ?? '未知文件名');
  }

  void _dialog(String title, String msg, String okText, String route) {
    Get.dialog(AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        FilledButton(
            onPressed: () {
              Get.back();
              Get.toNamed(route);
            },
            child: Text(okText)),
      ],
    ));
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(28),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _chip(String text, Color fg, Color bg, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11.5, color: fg),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
          ],
        ),
      );

  Widget _phIcon() => Container(
        width: 80,
        height: 80,
        color: kBrand.withAlpha(35),
        child: const Icon(Icons.android, color: kBrand, size: 38),
      );

  void _preview(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: Get.back,
        child: Container(
          color: Colors.black.withAlpha(215),
          child: Center(child: PhotoView(imageProvider: NetworkImage(url))),
        ),
      ),
    );
  }
}
