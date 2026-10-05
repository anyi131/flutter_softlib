import 'package:flutter/material.dart';
import '../../utils/apk_installer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:async';
import 'package:flutter_softlib/app/http/http_api.dart';
import 'package:flutter_softlib/app/pages/navigate/app/app_component.dart';
import 'package:flutter_softlib/app/pages/navigate/home/home_component.dart';
import 'package:flutter_softlib/app/pages/navigate/tips/tips_component.dart';
import 'package:flutter_softlib/app/pages/navigate/toolbox/tools_component.dart';
import 'package:flutter_softlib/app/pages/toolhub/tools_hub_page.dart';
import 'package:flutter_softlib/app/pages/navigate/square/square_component.dart';
import 'package:flutter_softlib/app/pages/navigate/mine/mine_component.dart';
import 'package:flutter_softlib/app/utils/jump_util.dart';
import 'package:flutter_softlib/app/utils/toast_util.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../api/soft_service.dart';
import '../../utils/permission_utils.dart';
import '../../widgets/icon_font.dart';

class NavigateLogic extends GetxController {
  List<NavigationDestination> labels = [
    NavigationDestination(
      icon: Icon(IconFont.home),
      label: '首页',
      selectedIcon: Icon(IconFont.homeFill),
    ),
    NavigationDestination(
      icon: Icon(IconFont.appB),
      label: '应用',
      selectedIcon: Icon(IconFont.appBFill),
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      label: '广场',
      selectedIcon: Icon(Icons.explore),
    ),
    NavigationDestination(
      icon: Icon(Icons.tips_and_updates_outlined),
      label: '线报',
      selectedIcon: Icon(Icons.tips_and_updates),
    ),
    NavigationDestination(
      icon: Icon(Icons.widgets_outlined),
      label: '工具',
      selectedIcon: Icon(Icons.widgets_rounded),
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border_rounded),
      label: '收藏',
      selectedIcon: Icon(Icons.favorite_rounded),
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      label: '我的',
      selectedIcon: Icon(Icons.person),
    ),
  ];
  List<Widget> pages = [
    HomeComponent(),
    AppComponent(),
    SquareComponent(),
    TipsComponent(),
    ToolsComponent(),
    ToolFavPage(),
    MineComponent(),
  ];
  PageController pageController = PageController();
  int currentIndex = 0;
  HttpApi httpApi = Get.find<HttpApi>();

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    //请求权限
    _requestPermissionsOnStartup();
    //检查更新
    checkUpdate();
  }

  /// 切换页面
  void changePage(int index) {
    currentIndex = index;
    pageController.jumpToPage(index);
    update(['navigate']);
  }

  /// 权限请求
  Future<void> _requestPermissionsOnStartup() async {
    await PermissionUtils.requestAppPermissions(Get.context!);
  }

  ///检测更新（公开：首页四宫格"版本更新"入口）
  Future<void> checkUpdate({bool showLatestTip = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final data = await SoftService.instance.checkVersion(version);
      if (data != null) {
        _showUpdateDialogRaw(data);
      } else if (showLatestTip) {
        ToastUtil.success('已是最新版本（v$version）');
      }
    } catch (e) {
      if (showLatestTip) ToastUtil.error('检查更新失败，请稍后重试');
    }
  }

  /// 显示更新弹窗（直接用 Map，避开 Retrofit 模型的类型限制）
  void _showUpdateDialogRaw(Map<String, dynamic> d) {
    final title = (d['title'] ?? '发现新版本').toString();
    final ver = (d['version'] ?? '').toString();
    final content = (d['content'] ?? '请及时更新以获取最佳体验').toString();
    final url = (d['dow_url'] ?? '').toString();
    final forced = '${d['forced_switch']}' == '1' || d['forced_switch'] == true;
    if (url.isEmpty) return;
    showDialog(
      context: Get.context!,
      barrierDismissible: !forced,
      builder: (context) =>
          _buildUpdateDialog(context, title, ver, content, url, forced),
    );
  }

  /// 构建更新弹窗
  Widget _buildUpdateDialog(
    BuildContext context,
    String title,
    String versionName,
    String content,
    String downloadUrl,
    bool forcedUpdate,
  ) {
    return PopScope(
      canPop: !forcedUpdate,
      // onPopInvokedWithResult: (bool didPop, dynamic result) {
      //   if (forcedUpdate && didPop) {
      //     // 如果是强制更新，可以在这里阻止弹窗被关闭
      //     // 但其实 canPop: false 就已经禁止了
      //   }
      // },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: _buildDialogDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(title, versionName),
              _buildDialogContent(context, content),
              _buildDialogActions(context, downloadUrl, forcedUpdate),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建弹窗装饰
  BoxDecoration _buildDialogDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.shade50, Colors.white],
      ),
    );
  }

  /// 构建弹窗头部
  Widget _buildDialogHeader(String title, String versionName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).primaryColor.withAlpha(160),
            Theme.of(Get.context!).primaryColor.withAlpha(230),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          _buildHeaderTitle(title),
          const SizedBox(height: 8),
          _buildVersionBadge(versionName),
        ],
      ),
    );
  }

  /// 构建头部标题
  Widget _buildHeaderTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 构建版本徽章
  Widget _buildVersionBadge(String versionName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'v$versionName',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建弹窗内容
  Widget _buildDialogContent(BuildContext context, String content) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: HtmlWidget(
            content,
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.grey.shade700,
            ),
            customStylesBuilder: _buildCustomStyles,
            onTapUrl: _handleUrlTap,
            renderMode: RenderMode.column,
          ),
        ),
      ),
    );
  }

  /// 构建自定义样式
  Map<String, String>? _buildCustomStyles(element) {
    switch (element.localName) {
      case 'p':
        return {'margin-bottom': '12px', 'line-height': '1.6'};
      case 'ul':
        return {
          'margin-left': '20px',
          'margin-bottom': '12px',
          'padding-left': '0px',
        };
      case 'li':
        return {'margin-bottom': '6px', 'line-height': '1.5'};
      case 'h1':
      case 'h2':
      case 'h3':
        return {
          'color': '#333333',
          'font-weight': 'bold',
          'margin-bottom': '10px',
          'margin-top': '16px',
        };
      case 'img':
        return {
          'max-width': '100%',
          'height': 'auto',
          'border-radius': '8px',
          'margin': '8px 0',
        };
      default:
        return null;
    }
  }

  /// 处理链接点击
  Future<bool> _handleUrlTap(String url) async {
    try {
      JumpUtil.openUrl(url);
    } catch (e) {
      ToastUtil.error('无法打开链接: $url');
    }
    return false;
  }

  /// 构建弹窗按钮区域
  Widget _buildDialogActions(
    BuildContext context,
    String downloadUrl,
    bool forcedUpdate,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (!forcedUpdate) ...[
            _buildCancelButton(context),
            const SizedBox(width: 12),
          ],
          _buildUpdateButton(context, downloadUrl, forcedUpdate),
        ],
      ),
    );
  }

  /// 构建取消按钮
  Widget _buildCancelButton(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          '以后再说',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建更新按钮
  Widget _buildUpdateButton(
    BuildContext context,
    String downloadUrl,
    bool forcedUpdate,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () =>
            _handleUpdateButtonTap(context, downloadUrl, forcedUpdate),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(Get.context!).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, size: 18),
            const SizedBox(width: 6),
            const Text(
              '立即更新',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理更新按钮点击：App 内解析直连下载，失败则询问跳浏览器
  Future<void> _handleUpdateButtonTap(
    BuildContext context,
    String downloadUrl,
    bool forcedUpdate,
  ) async {
    // 关闭更新弹窗
    if (!forcedUpdate && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // 1) 解析真实直链（蓝奏云链接 → 直链；普通 URL 直接用）
    String? direct = downloadUrl;
    if (downloadUrl.contains('lanzou') || downloadUrl.contains('lzy')) {
      ToastUtil.info('正在解析下载地址…');
      try {
        direct = await SoftService.instance.resolveLzy(downloadUrl);
      } catch (_) {
        direct = null;
      }
    }

    // 2) 解析成功 → App 内直接下载
    if (direct != null && direct.isNotEmpty) {
      try {
        final ok = await _downloadInApp(direct);
        if (ok) return;
      } catch (_) {}
    }

    // 3) 失败 → 询问是否跳浏览器
    final ctx = Get.context;
    if (ctx == null) return;
    final go = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('下载地址解析失败'),
        content: const Text('无法在应用内直接下载，是否跳转到浏览器打开原链接？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('浏览器打开')),
        ],
      ),
    );
    if (go == true) {
      JumpUtil.openUrl(downloadUrl);
    }
  }

  /// App 内下载 APK（用 FlutterDownloader，完成后提示安装）
  Future<bool> _downloadInApp(String url) async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      final fileName =
          'softlib_update_${DateTime.now().millisecondsSinceEpoch}.apk';
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        fileName: fileName,
        savedDir: '/storage/emulated/0/Download',
        showNotification: true,
        saveInPublicStorage: true,
        openFileFromNotification: true,
      );
      if (taskId == null) return false;

      // 轮询进度，完成后调用安装
      Timer.periodic(const Duration(milliseconds: 800), (t) async {
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query: "SELECT * FROM task WHERE task_id='$taskId'",
        );
        if (tasks == null || tasks.isEmpty) {
          t.cancel();
          return;
        }
        final st = tasks.first.status;
        if (st == DownloadTaskStatus.complete) {
          t.cancel();
          final path = '${tasks.first.savedDir}/${tasks.first.filename}';
          _promptInstall(path);
        } else if (st == DownloadTaskStatus.failed ||
            st == DownloadTaskStatus.canceled) {
          t.cancel();
          ToastUtil.error('下载失败，请重试');
        }
      });
      ToastUtil.success('开始下载新版本…');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 下载完成 → 询问安装
  void _promptInstall(String path) {
    final ctx = Get.context;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 8),
            Text('下载完成',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text('新版本已下载完成，是否立即安装？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('稍后')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(c);
              await ApkInstaller.install(path);
            },
            child: const Text('立即安装'),
          ),
        ],
      ),
    );
  }

}
