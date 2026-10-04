import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

import '../../config.dart';
import '../../design/adaptive.dart';
import '../../design/kit.dart';
import '../../design/ui.dart';
import 'app_download_logic.dart';

/// 软件下载列表（v40 重做）
///
/// 设计要点：
///   · 沿用全项目「沉浸式玻璃拟态」语言，与其它页面统一
///   · 分两组：进行中 / 已完成，一眼看清
///   · 每条卡片：图标 + 名称 + 状态胶囊 + 进度环/条 + 大小 + 操作按钮
///   · 空状态有插画级提示，不再是干巴巴的一行字
class AppDownloadPage extends StatefulWidget {
  const AppDownloadPage({super.key});

  @override
  State<AppDownloadPage> createState() => _AppDownloadPageState();
}

class _AppDownloadPageState extends State<AppDownloadPage> {
  final AppDownloadLogic logic = Get.find<AppDownloadLogic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Deco.pageBackground(context),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: GetBuilder<AppDownloadLogic>(
                    id: 'downInfos',
                    builder: (logic) {
                      final list = logic.downInfos;
                      if (list == null) {
                        return const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        );
                      }
                      if (list.isEmpty) return _empty();

                      final running = list
                          .where((d) => d.status != DownloadTaskStatus.complete)
                          .toList();
                      final done = list
                          .where((d) => d.status == DownloadTaskStatus.complete)
                          .toList();

                      return RefreshIndicator(
                        onRefresh: () async {
                          await logic.getAllDownInfos();
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          padding: EdgeInsets.fromLTRB(
                              context.pagePadding, 4, context.pagePadding,
                              context.tabSpace + 30),
                          children: [
                            if (running.isNotEmpty) ...[
                              _groupTitle('进行中', running.length, C.brand),
                              const SizedBox(height: 10),
                              ...running.map((d) => _card(d)),
                              const SizedBox(height: 18),
                            ],
                            if (done.isNotEmpty) ...[
                              _groupTitle('已完成', done.length, C.success),
                              const SizedBox(height: 10),
                              ...done.map((d) => _card(d)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───── 顶栏 ─────
  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, 10, context.pagePadding, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withAlpha(14)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(8),
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: context.t1),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (r) => Deco.aurora().createShader(r),
            child: Text('下载管理',
                style: Ty.h2.copyWith(color: Colors.white, fontSize: 21)),
          ),
          const Spacer(),
          GetBuilder<AppDownloadLogic>(
            id: 'downInfos',
            builder: (logic) {
              final n = logic.downInfos?.length ?? 0;
              if (n == 0) return const SizedBox.shrink();
              return Pill('$n 个任务', color: C.brand, small: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _groupTitle(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 15,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: Ty.h3.copyWith(fontSize: 15, color: context.t1)),
        const SizedBox(width: 6),
        Text('$count', style: Ty.tiny.copyWith(color: context.t3)),
      ],
    );
  }

  // ───── 空状态 ─────
  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  C.brand.withAlpha(40),
                  C.cyan.withAlpha(24),
                ],
              ),
            ),
            child: Icon(Icons.download_done_rounded,
                size: 44, color: C.brand.withAlpha(200)),
          ),
          const SizedBox(height: 18),
          Text('暂无下载任务',
              style: Ty.h3.copyWith(fontSize: 15.5, color: context.t1)),
          const SizedBox(height: 8),
          Text('去软件库里挑一个喜欢的吧',
              style: Ty.small.copyWith(color: context.t3)),
          const SizedBox(height: 20),
          SoftButton(
            label: '去逛逛',
            icon: Icons.explore_rounded,
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  // ───── 单条卡片 ─────
  Widget _card(DownInfo d) {
    final status = d.status;
    final color = _statusColor(status);
    final isDone = status == DownloadTaskStatus.complete;
    final progress = (d.progress ?? 0) / 100.0;

    return GetBuilder<AppDownloadLogic>(
      id: '${d.appId}',
      builder: (logic) {
        return KitCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  // 图标（带状态角标）
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(R.md),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: (d.appIcon ?? '').isEmpty
                              ? _iconFallback()
                              : CachedNetworkImage(
                                  imageUrl: d.appIcon!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 120,
                                  placeholder: (_, __) => _iconFallback(),
                                  errorWidget: (_, __, ___) => _iconFallback(),
                                ),
                        ),
                      ),
                      if (isDone)
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                size: 16, color: C.success),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(d),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Ty.h3
                              .copyWith(fontSize: 14.5, color: context.t1),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Pill(_statusText(status), color: color, small: true),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                _sizeText(d),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Ty.tiny.copyWith(color: context.t3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(d, logic),
                ],
              ),
              // 已完成：显示「分享 / 删除」操作条
              if (isDone) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _miniBtn(
                        icon: Icons.ios_share_rounded,
                        label: '分享',
                        color: C.cyan,
                        onTap: () => logic.shareDownload(d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniBtn(
                        icon: Icons.delete_outline_rounded,
                        label: '删除',
                        color: C.danger,
                        onTap: () async {
                          final ok = await Get.dialog<bool>(AlertDialog(
                            title: const Text('删除下载'),
                            content: Text(
                                '将删除「${_displayName(d)}」的记录和已下载的文件，确定吗？'),
                            actions: [
                              TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('取消')),
                              FilledButton(
                                  onPressed: () => Get.back(result: true),
                                  child: const Text('删除')),
                            ],
                          ));
                          if (ok == true) logic.deleteDownload(d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              // 进度（已完成不显示进度条）
              if (!isDone) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(R.full),
                  child: LinearProgressIndicator(
                    value: progress.isNaN ? 0 : progress.clamp(0.0, 1.0),
                    backgroundColor: context.isDark
                        ? Colors.white.withAlpha(16)
                        : Colors.black.withAlpha(10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text('${d.progress ?? 0}%',
                        style: Ty.tiny.copyWith(
                            color: color, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(
                      (d.appSize ?? '').trim().isEmpty
                          ? ''
                          : '${calculateDownloadedSize(d.appSize!, d.progress ?? 0)} / ${d.appSize}',
                      style: Ty.tiny.copyWith(color: context.t3),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _iconFallback() => Container(
        color: C.brand.withAlpha(context.isDark ? 34 : 22),
        child: Icon(Icons.android, color: C.brand, size: 26),
      );

  /// 小操作按钮（分享 / 删除）
  Widget _miniBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withAlpha(context.isDark ? 34 : 22),
      borderRadius: BorderRadius.circular(R.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.full),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  /// 右侧主操作按钮
  Widget _actionBtn(DownInfo d, AppDownloadLogic logic) {
    IconData icon;
    Color color;
    VoidCallback onTap;
    String tip;
    switch (d.status) {
      case DownloadTaskStatus.enqueued:
        icon = Icons.hourglass_top_rounded;
        color = C.warning;
        tip = '等待中';
        onTap = () {};
        break;
      case DownloadTaskStatus.running:
        icon = Icons.pause_rounded;
        color = C.brand;
        tip = '暂停';
        onTap = () => logic.pauseDownload(d);
        break;
      case DownloadTaskStatus.paused:
        icon = Icons.play_arrow_rounded;
        color = C.warning;
        tip = '继续';
        onTap = () => logic.resumeDownload(d);
        break;
      case DownloadTaskStatus.failed:
        icon = Icons.refresh_rounded;
        color = C.danger;
        tip = '重试';
        onTap = () => logic.retryDownload(d);
        break;
      case DownloadTaskStatus.complete:
        icon = Icons.install_mobile_rounded;
        color = C.success;
        tip = '安装';
        onTap = () => logic.openDownloadFile(d);
        break;
      default:
        icon = Icons.more_horiz_rounded;
        color = context.t3;
        tip = '';
        onTap = () {};
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(context.isDark ? 40 : 26),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(90), width: 0.8),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
        if (tip.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(tip,
              style: Ty.tiny.copyWith(fontSize: 9.5, color: color)),
        ],
      ],
    );
  }

  /// 列表显示名：优先数据库里的应用名；
  /// 没有则退回任务真实文件名（去掉 .apk 后缀和自动追加的时间戳），
  /// 绝不显示「未知文件」这种无信息量的占位。
  String _displayName(DownInfo d) {
    final name = (d.appName ?? '').trim();
    if (name.isNotEmpty && name != '未知文件') return name;
    var fn = (d.fileName ?? '').trim();
    if (fn.isEmpty) return '下载文件';
    fn = fn.replaceAll('_', ' ');
    final apk = fn.toLowerCase().lastIndexOf('.apk');
    if (apk > 0) fn = fn.substring(0, apk);
    fn = fn.replaceFirst(RegExp(r'\s*\d{13}$'), '');
    return fn.trim().isEmpty ? '下载文件' : fn.trim();
  }

  String _sizeText(DownInfo d) {
    final s = (d.appSize ?? '').trim();
    return s.isEmpty ? '大小未知' : s;
  }

  String _statusText(DownloadTaskStatus? status) {
    switch (status) {
      case DownloadTaskStatus.enqueued:
        return '等待中';
      case DownloadTaskStatus.running:
        return '下载中';
      case DownloadTaskStatus.paused:
        return '已暂停';
      case DownloadTaskStatus.failed:
        return '下载失败';
      case DownloadTaskStatus.complete:
        return '已完成';
      default:
        return '未知';
    }
  }

  Color _statusColor(DownloadTaskStatus? status) {
    switch (status) {
      case DownloadTaskStatus.enqueued:
        return C.warning;
      case DownloadTaskStatus.running:
        return C.brand;
      case DownloadTaskStatus.paused:
        return C.warning;
      case DownloadTaskStatus.failed:
        return C.danger;
      case DownloadTaskStatus.complete:
        return C.success;
      default:
        return context.t3;
    }
  }
}
