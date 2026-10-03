import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

import '../../config.dart';
import '../../models/app_item.dart';
import '../../utils/jump_util.dart';
import 'app_details_logic.dart';

/// 软件详情页（图标 + 认证标签 + 数据四宫格 + 详情/评论 Tab + 介绍/截图 + 底部下载）
class AppDetailsPage extends StatefulWidget {
  const AppDetailsPage({super.key});

  @override
  State<AppDetailsPage> createState() => _AppDetailsPageState();
}

class _AppDetailsPageState extends State<AppDetailsPage>
    with SingleTickerProviderStateMixin {
  final AppDetailsLogic logic = Get.find<AppDetailsLogic>();
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  AppItem? get item => logic.item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F6F7);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => JumpUtil.openUrl(logic.shareUrl),
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
                  Icon(Icons.error_outline,
                      size: 56, color: Colors.grey.withAlpha(120)),
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
            padding: EdgeInsets.zero,
            children: [
              _header(isDark),
              const SizedBox(height: 10),
              _tabCard(isDark),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  /// 头部：图标 + 标题 + 认证标签 + 数据四宫格
  Widget _header(bool isDark) {
    final it = item;
    final info = logic.appInfo;
    final cardBg = isDark ? const Color(0xFF262626) : Colors.white;
    final icon = info?.fileIcon ?? '';
    return Container(
      color: cardBg,
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: icon.isEmpty
                    ? _phIcon()
                    : CachedNetworkImage(
                        imageUrl: icon,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _phIcon(),
                        errorWidget: (_, __, ___) => _phIcon(),
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
                          fontSize: 19, fontWeight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text('人工亲测 · 无病毒',
                            style: TextStyle(
                                fontSize: 12.5, color: Color(0xFF16A34A))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _certTag('签名认证', const Color(0xFF2563EB),
                            const Color(0xFFDBEAFE)),
                        _certTag('金标认证', const Color(0xFFB45309),
                            const Color(0xFFFEF3C7)),
                        _certTag('人工亲测', const Color(0xFF16A34A),
                            const Color(0xFFDCFCE7)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 数据四宫格
          Row(
            children: [
              _statCell('${info?.fileSize ?? it?.size ?? '-'}', '软件大小'),
              _statCell(it?.uploadDate.isNotEmpty == true
                  ? it!.uploadDate
                  : '-', '上传日期'),
              _statCell('${it?.views ?? 0}', '浏览量'),
              _statCell(it?.ageRating ?? '16+', '适用年龄'),
            ],
          ),
        ],
      ),
    );
  }

  /// 详情 / 评论 Tab 区
  Widget _tabCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF262626) : Colors.white;
    return Container(
      color: cardBg,
      child: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: '详情'),
              Tab(text: '评论'),
            ],
          ),
          SizedBox(
            height: 460,
            child: TabBarView(
              controller: _tab,
              children: [
                _detailTab(isDark),
                _commentTab(isDark),
              ],
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('软件介绍',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('官方详情',
                  style: TextStyle(fontSize: 11, color: Color(0xFF3B5BDB))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          desc.isEmpty ? '暂无详细介绍' : desc,
          style: TextStyle(
            fontSize: 14,
            height: 1.75,
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '提示：下载前请确认软件名称和更新时间，安装包以当前详情页展示为准。',
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.6),
          ),
        ),
        if (shots.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('应用截图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _preview(shots[i]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: shots[i],
                    width: 130,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 130,
                      color: Colors.black12,
                    ),
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
      ],
    );
  }

  Widget _commentTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 52, color: Colors.grey.withAlpha(110)),
          const SizedBox(height: 12),
          Text('评论区即将开放',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  /// 底部按钮：未下载→下载；下载中→进度；完成→安装
  Widget _bottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocal = item?.isLocal ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: GetBuilder<AppDetailsLogic>(
          id: 'download',
          builder: (download) {
            final task = download.downloadTask;
            if (task == null) {
              return SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => download.addDownload(
                      logic.appInfo?.fileName ?? '未知文件名'),
                  child: Text(isLocal ? '下载安装' : '解析并下载',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              );
            }
            if (task.status == DownloadTaskStatus.complete) {
              return SizedBox(
                height: 48,
                width: double.infinity,
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
              );
            }
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
                          backgroundColor: Colors.grey.withAlpha(50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${task.progress}%',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
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
                const SizedBox(height: 4),
                Text(
                  task.status == DownloadTaskStatus.paused
                      ? '已暂停'
                      : (task.status == DownloadTaskStatus.failed ? '下载失败' : '正在下载'),
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _certTag(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _phIcon() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      color: scheme.primaryContainer.withAlpha(110),
      child: Icon(Icons.android, color: scheme.primary, size: 34),
    );
  }

  void _preview(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: Get.back,
        child: Container(
          color: Colors.black.withAlpha(210),
          child: Center(
            child: PhotoView(imageProvider: NetworkImage(url)),
          ),
        ),
      ),
    );
  }
}
