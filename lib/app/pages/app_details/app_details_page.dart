import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

import '../../api/user_service.dart';
import '../../models/app_item.dart';
import '../../routes/app_pages.dart';
import '../../utils/jump_util.dart';
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
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF2F3F7),
        elevation: 0,
        title: const Text('软件详情', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
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
                      size: 56, color: Colors.grey.withAlpha(110)),
                  const SizedBox(height: 12),
                  Text(logic.msgError ?? '获取软件信息失败',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: logic.getAppInfo, child: const Text('重试')),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              _heroCard(isDark),
              const SizedBox(height: 12),
              _statsCard(isDark),
              const SizedBox(height: 12),
              _tabsCard(isDark),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ===== 主卡：图标 + 标题 + 认证 + 价格标记 =====
  Widget _heroCard(bool isDark) {
    final it = item;
    final info = logic.appInfo;
    final isVipItem = (it?.catId ?? 0) == 5; // 会员专区
    final icon = info?.fileIcon ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标 + 阴影
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: kBrand.withAlpha(isDark ? 60 : 40),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: icon.isEmpty
                      ? _phIcon()
                      : CachedNetworkImage(
                          imageUrl: icon,
                          width: 76,
                          height: 76,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (isVipItem)
                          _pill('会员专享', kVip, const Color(0xFFFFF6DC),
                              icon: Icons.workspace_premium)
                        else
                          _pill('免费下载', const Color(0xFF16A34A),
                              const Color(0xFFE7F9EE),
                              icon: Icons.check_circle),
                        const SizedBox(width: 6),
                        _pill('人工亲测', const Color(0xFF2563EB),
                            const Color(0xFFE7EEFF),
                            icon: Icons.verified_user),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '版本 ${it?.version.isNotEmpty == true ? it!.version : '未知'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 认证条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text('本应用已通过安全检测 · 无病毒 · 无广告插件',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 数据卡：大小 / 上传日期 / 浏览量 / 年龄 =====
  Widget _statsCard(bool isDark) {
    final it = item;
    final info = logic.appInfo;
    final cells = [
      (Icons.sd_storage_outlined, info?.fileSize ?? it?.size ?? '-', '软件大小'),
      (Icons.calendar_today_outlined,
          it?.uploadDate.isNotEmpty == true ? it!.uploadDate : '-', '上传日期'),
      (Icons.visibility_outlined, '${it?.views ?? 0}', '浏览量'),
      (Icons.face_outlined, it?.ageRating ?? '16+', '适用年龄'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: cells
            .map((c) => Expanded(
                  child: Column(
                    children: [
                      Icon(c.$1, size: 19, color: kBrand.withAlpha(190)),
                      const SizedBox(height: 7),
                      Text(c.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(c.$3,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ===== 详情 / 评论 =====
  Widget _tabsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: TabBar(
              controller: _tab,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: kBrand,
              labelColor: kBrand,
              unselectedLabelColor: Colors.grey[500],
              labelStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '详情'), Tab(text: '评论')],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withAlpha(28)),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tab,
              children: [_detailTab(isDark), _commentTab(isDark)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTab(bool isDark) {
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
              height: 16,
              decoration: BoxDecoration(
                  color: kBrand, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            const Text('软件介绍',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('官方详情',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3B5BDB),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          desc.isEmpty ? '暂无详细介绍' : desc,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.85,
            color: isDark ? Colors.grey[300] : const Color(0xFF3C4043),
          ),
        ),
        if (shots.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('应用截图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
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
                    width: 136,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 136, color: Colors.black12),
                    errorWidget: (_, __, ___) => Container(
                      width: 136,
                      color: Colors.black12,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '提示：下载前请确认软件名称和更新时间，安装包以当前详情页展示为准。',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _commentTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 52, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 12),
          Text('评论区即将开放',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 6),
          Text('可以先下载软件体验哦',
              style: TextStyle(color: Colors.grey[400], fontSize: 12.5)),
        ],
      ),
    );
  }

  // ===== 底部：价格 + 下载按钮 =====
  Widget _bottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocal = item?.isLocal ?? false;
    final isVipItem = (item?.catId ?? 0) == 5;
    final loggedIn = UserService.instance.isLoggedIn;
    final isVipUser = UserService.instance.user?.isVip == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 12,
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
            if (task != null && task.status == DownloadTaskStatus.complete) {
              return Row(
                children: [
                  Expanded(
                    child: _vipMini(isVipItem),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: download.openDownloadFile,
                        child: const Text('安装',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              );
            }
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
                            minHeight: 8,
                            backgroundColor: Colors.grey.withAlpha(45),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${task.progress}%',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      _ctrlBtn(
                        task.status == DownloadTaskStatus.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                        task.status == DownloadTaskStatus.paused
                            ? download.resumeDownload
                            : download.pauseDownload,
                      ),
                      const SizedBox(width: 6),
                      _ctrlBtn(Icons.close, download.cancelDownload),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    task.status == DownloadTaskStatus.paused
                        ? '已暂停'
                        : (task.status == DownloadTaskStatus.failed
                            ? '下载失败，可重试'
                            : '正在下载…'),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _vipMini(isVipItem)),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kBrand,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () => _onDownload(isVipItem, loggedIn, isVipUser),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isVipItem ? Icons.workspace_premium : Icons.download,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isVipItem
                                ? (isVipUser ? '会员下载' : '开通会员下载')
                                : (isLocal ? '下载安装' : '解析并下载'),
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 左下角小卡：免费 / 会员价
  Widget _vipMini(bool isVipItem) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: isVipItem
            ? const LinearGradient(colors: [Color(0xFF3A3226), Color(0xFF241F18)])
            : null,
        color: isVipItem ? null : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isVipItem ? Icons.workspace_premium : Icons.download_for_offline,
                  size: 15,
                  color: isVipItem ? kVip : const Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                isVipItem ? '¥9.9' : '免费',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isVipItem ? const Color(0xFFF5D283) : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          Text(
            isVipItem ? '会员专享' : '立即下载',
            style: TextStyle(
                fontSize: 10,
                color: isVipItem ? Colors.white70 : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 下载前的权限判断
  void _onDownload(bool isVipItem, bool loggedIn, bool isVipUser) {
    if (isVipItem && !loggedIn) {
      _askLogin('该资源为会员专享，请先登录');
      return;
    }
    if (isVipItem && !isVipUser) {
      final go = Get.dialog(
        AlertDialog(
          title: const Text('会员专享资源'),
          content: const Text('该资源仅会员可下载，是否前往开通会员？'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('取消')),
            FilledButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routes.vip);
                },
                child: const Text('去开通')),
          ],
        ),
      );
      go.then((_) {});
      return;
    }
    logic.addDownload(logic.appInfo?.fileName ?? '未知文件名');
  }

  void _askLogin(String msg) {
    Get.dialog(AlertDialog(
      title: const Text('需要登录'),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        FilledButton(
            onPressed: () {
              Get.back();
              Get.toNamed(Routes.login);
            },
            child: const Text('去登录')),
      ],
    ));
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg, {required IconData icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
            Text(text,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
          ],
        ),
      );

  Widget _phIcon() {
    return Container(
      width: 76,
      height: 76,
      color: kBrand.withAlpha(38),
      child: const Icon(Icons.android, color: kBrand, size: 36),
    );
  }

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
