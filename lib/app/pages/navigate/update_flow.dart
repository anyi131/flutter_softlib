import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

import '../../api/soft_service.dart';
import '../../design/app_anim.dart';
import '../../design/ui.dart';
import '../../utils/apk_installer.dart';
import '../../utils/jump_util.dart';
import '../../utils/toast_util.dart';

import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ═══════════════════════════════════════════════════════════════
/// 更新体验 v52 —— 精美更新弹窗 + 应用内下载进度（需求 #4）
///
///  · 渐变头图 + 版本徽章 + 更新日志
///  · 点「立即更新」弹窗内直接显示下载进度（环形 + 百分比 + 已下载/总大小）
///  · 100% 自动拉起安装器；失败降级浏览器
/// ═══════════════════════════════════════════════════════════════
class UpdateFlow {
  UpdateFlow._();

  /// 检查更新（公开：首页四宫格 / 启动时调用）
  static Future<void> check({bool showLatestTip = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final data = await SoftService.instance.checkVersion(version);
      if (data != null) {
        show(data);
      } else if (showLatestTip) {
        ToastUtil.success('已是最新版本（v$version）');
      }
    } catch (e) {
      if (showLatestTip) ToastUtil.error('检查更新失败，请稍后重试');
    }
  }

  /// 显示更新弹窗（直接用 Map，避开 Retrofit 模型的类型限制）
  static void show(Map<String, dynamic> d) {
    final title = (d['title'] ?? '发现新版本').toString();
    final ver = (d['version'] ?? '').toString();
    final content = (d['content'] ?? '请及时更新以获取最佳体验').toString();
    final url = (d['dow_url'] ?? '').toString();
    final forced = '${d['forced_switch']}' == '1' || d['forced_switch'] == true;
    if (url.isEmpty) return;
    showDialog(
      context: Get.context!,
      barrierDismissible: !forced,
      barrierColor: Colors.black.withAlpha(120),
      builder: (context) => PopScope(
        canPop: !forced,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 34,
            vertical: 40,
          ),
          child: _UpdateCard(
            title: title,
            version: ver,
            content: content,
            url: url,
            forced: forced,
          ),
        ),
      ),
    );
  }
}

class _UpdateCard extends StatefulWidget {
  final String title;
  final String version;
  final String content;
  final String url;
  final bool forced;
  const _UpdateCard({
    required this.title,
    required this.version,
    required this.content,
    required this.url,
    required this.forced,
  });

  @override
  State<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<_UpdateCard> {
  // idle / downloading / done / failed
  String _phase = 'idle';
  int _progress = 0; // 0-100
  int _total = 0;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_phase == 'downloading') return;
    // 权限
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // 解析直链
    String? direct = widget.url;
    if (widget.url.contains('lanzou') || widget.url.contains('lzy')) {
      try {
        direct = await SoftService.instance.resolveLzy(widget.url);
      } catch (_) {
        direct = null;
      }
    }
    if (direct == null || direct.isEmpty) {
      _fallbackBrowser();
      return;
    }
    setState(() => _phase = 'downloading');
    final taskId = await FlutterDownloader.enqueue(
      url: direct,
      fileName: 'softlib_update_${DateTime.now().millisecondsSinceEpoch}.apk',
      savedDir: '/storage/emulated/0/Download',
      showNotification: true,
      saveInPublicStorage: true,
      openFileFromNotification: true,
    );
    if (taskId == null) {
      _fallbackBrowser();
      return;
    }
    _poll = Timer.periodic(const Duration(milliseconds: 500), (t) async {
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$taskId'",
      );
      if (tasks == null || tasks.isEmpty) return;
      final tk = tasks.first;
      if (!mounted) return;
      setState(() {
        _progress = tk.progress;
      });
      if (tk.status == DownloadTaskStatus.complete) {
        t.cancel();
        setState(() => _phase = 'done');
        await Future.delayed(const Duration(milliseconds: 500));
        final path = '${tk.savedDir}/${tk.filename}';
        try {
          await ApkInstaller.install(path);
        } catch (_) {}
        if (mounted && !widget.forced) Navigator.of(context).pop();
      } else if (tk.status == DownloadTaskStatus.failed ||
          tk.status == DownloadTaskStatus.canceled) {
        t.cancel();
        setState(() => _phase = 'failed');
      }
    });
  }

  void _fallbackBrowser() {
    ToastUtil.info('应用内下载失败，尝试浏览器打开…');
    JumpUtil.openUrl(widget.url);
    if (!widget.forced && mounted) Navigator.of(context).pop();
  }

  String _sizeText(int bytes) {
    if (bytes <= 0) return '';
    final mb = bytes / 1048576;
    return '${mb.toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AppScaleIn(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? C.bg2 : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 渐变头图 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              decoration: BoxDecoration(gradient: C.brandGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(46),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'v${widget.version} · 全新体验',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── 内容 ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: _phase == 'idle'
                    ? HtmlWidget(
                        widget.content,
                        textStyle: TextStyle(
                          fontSize: 13.8,
                          height: 1.65,
                          color: isDark ? C.t2 : C.lt2,
                        ).copyWith(),
                        onTapUrl: (u) {
                          JumpUtil.openUrl(u);
                          return true;
                        },
                      )
                    : _progressBody(isDark),
              ),
            ),
            // ── 按钮 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: _actionRow(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBody(bool isDark) {
    if (_phase == 'done') {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: C.success, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '下载完成，正在安装…',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? C.t1 : C.lt1,
              ),
            ),
          ),
        ],
      );
    }
    if (_phase == 'failed') {
      return Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: C.danger, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '下载失败，请重试或用浏览器下载',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? C.t1 : C.lt1,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress / 100,
                    strokeWidth: 3,
                    backgroundColor: C.brand.withAlpha(isDark ? 46 : 28),
                    valueColor: AlwaysStoppedAnimation(C.brand),
                  ),
                  Text(
                    '$_progress%',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: C.brand,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '正在下载更新包…',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? C.t1 : C.lt1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _total > 0
                        ? '${_sizeText((_progress * _total / 100).round())} / ${_sizeText(_total)}'
                        : '已下载 $_progress%',
                    style: TextStyle(fontSize: 11.5, color: context.t3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress / 100),
            duration: AppAnim.base,
            curve: AppAnim.emphasized,
            builder: (c, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: C.brand.withAlpha(isDark ? 36 : 22),
              valueColor: AlwaysStoppedAnimation(C.brand),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionRow(bool isDark) {
    if (_phase == 'downloading') {
      return const SizedBox(height: 6);
    }
    return Row(
      children: [
        if (!widget.forced) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _phase == 'failed'
                  ? () => Navigator.of(context).pop()
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark ? C.t3.withAlpha(80) : C.lt3.withAlpha(70),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                _phase == 'failed' ? '关闭' : '稍后再说',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? C.t2 : C.lt2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: AppPressable(
            onTap: _phase == 'failed'
                ? () => setState(() => _phase = 'idle')
                : _start,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: C.brandGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: C.brand.withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                _phase == 'failed' ? '重试' : '立即更新',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
