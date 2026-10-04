import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

import '../../config.dart';
import '../../database/database.dart' as db;
import '../../database/tables/download_task_table.dart';
import '../../models/app_item.dart';
import '../../models/http/results/lzy_file_info_model.dart';
import '../../api/api_host.dart';
import '../../api/soft_service.dart';
import '../../utils/apk_installer.dart';
import '../../utils/toast_util.dart';
import '../../widgets/posters/posters_widget.dart';

@pragma('vm:entry-point')
class AppDetailsLogic extends GetxController {
  /// 参数：appId(String) + item(AppItem) 【或旧格式 dowUrl】
  int appIdInt = 0;
  AppItem? item;

  String get appId => appIdInt.toString();

  /// 蓝奏云情况下需要的信息来源
  String dowUrl = '';

  SoftService service = SoftService.instance;
  GlobalKey posterKey = GlobalKey();

  /// 统一详情模型（复用蓝奏云文件信息模型展示）
  LzyFileInfoData? appInfo;
  String? msgError;
  bool isLoadingInfo = true;

  db.AppDatabase appDatabase = Get.find<db.AppDatabase>();
  ReceivePort port = ReceivePort();
  late DownloadTaskDao downloadTaskDao;
  DownloadTask? downloadTask;
  String? taskId;
  Timer? _progressTimer;

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'app_details_downloader_send_port',
    );
    send?.send([id, status, progress]);
  }

  @override
  void onInit() {
    super.onInit();
    downloadTaskDao = DownloadTaskDao(appDatabase);
    _parseArguments();
    // 浏览量 +1（真实数据采集）
    if (appIdInt > 0) service.addAppView(appIdInt);
    getAppInfo();
    getTaskInfo();
    IsolateNameServer.removePortNameMapping('app_details_downloader_send_port');
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'app_details_downloader_send_port',
    );
    port.listen((dynamic data) {
      if (data is List && data.length >= 3) {
        final status = data[1] is int ? data[1] as int : 0;
        getTaskInfo();
        // 下载完成 → 弹窗确认安装
        if (status == 3 /* complete */) {
          _onDownloadComplete();
        }
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  void _parseArguments() {
    final args = Get.arguments;
    if (args is Map) {
      final it = args['item'];
      if (it is AppItem) {
        item = it;
        appIdInt = it.id;
        dowUrl = it.url;
      }
      final rawId = args['appId'];
      if (rawId != null && appIdInt == 0) {
        appIdInt = int.tryParse(rawId.toString()) ?? 0;
      }
      final rawUrl = args['dowUrl'];
      if (rawUrl != null && dowUrl.isEmpty) dowUrl = rawUrl.toString();
    }
  }

  /// 获取软件信息（双数据源）
  Future<void> getAppInfo() async {
    isLoadingInfo = true;
    update(['appInfo', 'share', 'download']);
    try {
      // ★ 蓝奏云文件夹的软件：直接用传入的数据构造，不走后台查询
      if (item != null && item!.fromFolder) {
        appInfo = LzyFileInfoData(
          fileIcon: item!.icon,
          fileName: item!.title,
          fileSize: item!.size,
          fileTime: item!.uploadDate.isNotEmpty ? item!.uploadDate : '最近更新',
          fileType: '蓝奏云',
          fileDesc: item!.description.isNotEmpty
              ? item!.description
              : '本软件来自蓝奏云文件夹，请放心下载。',
          fileImage: item!.screenshots.isNotEmpty
              ? item!.screenshots.first
              : '',
        );
        isLoadingInfo = false;
        update(['appInfo', 'share', 'download']);
        return;
      }
      // 服务器直传：优先展示数据库信息
      if (item != null &&
          (item!.description.isNotEmpty ||
              item!.size.isNotEmpty ||
              item!.icon.isNotEmpty)) {
        appInfo = LzyFileInfoData(
          fileIcon: item!.icon,
          fileName: item!.title,
          fileSize: item!.size,
          fileTime: item!.version,
          fileType: item!.isLocal ? '服务器直传' : '蓝奏云',
          fileDesc: item!.description,
        );
      }
      // 蓝奏云：补充解析出的文件信息（图标优先用后台配置的）
      if (item != null && !item!.isLocal && item!.url.isNotEmpty) {
        final info = await service.lzyFileInfo(item!.url);
        if (info != null) {
          // 图标优先级：数据库 icon > 解析出的 icon > 空
          final dbIcon = item!.icon;
          final parsedIcon = (info['icon'] ?? '').toString();
          appInfo = LzyFileInfoData(
            fileIcon: dbIcon.isNotEmpty ? dbIcon : parsedIcon,
            fileName: item!.title.isNotEmpty
                ? item!.title
                : (info['name'] ?? '').toString(),
            fileSize: item!.size.isNotEmpty
                ? item!.size
                : (info['size'] ?? '').toString(),
            fileTime: (info['time'] ?? item!.version).toString(),
            fileType: (info['type'] ?? '蓝奏云').toString(),
            fileDesc: item!.description.isNotEmpty
                ? item!.description
                : (info['des'] ?? '').toString(),
          );
        }
      }
      if (appInfo == null && dowUrl.isNotEmpty) {
        // 兜底：只有蓝奏云链接（旧调用方式）
        final info = await service.lzyFileInfo(dowUrl);
        if (info != null) {
          appInfo = LzyFileInfoData(
            fileIcon: (info['icon'] ?? '').toString(),
            fileName: (info['name'] ?? '').toString(),
            fileSize: (info['size'] ?? '').toString(),
            fileTime: (info['time'] ?? '').toString(),
            fileType: (info['type'] ?? '').toString(),
            fileDesc: (info['des'] ?? '').toString(),
          );
        }
      }
      if (appInfo == null) {
        msgError = '获取软件信息失败';
      }
    } catch (e) {
      logger.e(e.toString());
      msgError ??= '网络异常，请稍后重试';
    } finally {
      isLoadingInfo = false;
      update(['appInfo', 'share', 'download']);
    }
  }

  /// 下载完成：弹窗确认是否安装
  bool _askedInstall = false;
  Future<void> _onDownloadComplete() async {
    if (_askedInstall) return;
    _askedInstall = true;
    await Future.delayed(const Duration(milliseconds: 400));
    final ctx = Get.context;
    if (ctx == null) return;
    final name = appInfo?.fileName ?? '安装包';
    final go = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 8),
            Text('下载完成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text('$name 已下载完成，是否立即安装？',
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('立即安装'),
          ),
        ],
      ),
    );
    _askedInstall = false;
    if (go == true) {
      await openDownloadFile();
    }
  }

  Future<void> getTaskInfo() async {
    String? taskIdTemp = await downloadTaskDao.queryDownloadTaskByAppId(appId);
    taskId = taskIdTemp;
    if (taskId != null && taskId!.isNotEmpty) {
      List<DownloadTask>? tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$taskId'",
      );
      if (tasks != null && tasks.isNotEmpty) {
        downloadTask = tasks.first;
      } else {
        downloadTask = null;
      }
    }
    update(['download']);
  }

  /// 添加下载（双来源统一入口）
  Future<void> addDownload(String fileName, [String? lzyUrl]) async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 解析真实下载地址
    String? parseUrl;
    String originalUrl = '';
    bool useFallback = false;
    if (item != null && item!.canDirectDownload) {
      parseUrl = item!.file; // 服务器直传：无需解析
    } else {
      final target = (lzyUrl != null && lzyUrl.isNotEmpty)
          ? lzyUrl
          : (item?.url ?? dowUrl);
      if (target.isEmpty) {
        ToastUtil.error('下载地址为空');
        return;
      }
      originalUrl = target;
      try {
        // 方案一/二：自建 API → 后端解析
        parseUrl = await service.resolveLzy(target);
      } catch (e) {
        logger.e(e.toString());
      }
      // 方案三：两种解析都失败 → 用原链接直接下载
      if (parseUrl == null || parseUrl.isEmpty) {
        parseUrl = target;
        useFallback = true;
      }
    }

    if (parseUrl.isEmpty) {
      ToastUtil.error('下载地址无效');
      return;
    }
    if (useFallback) {
      ToastUtil.error('直链解析失败，已改用原链接下载');
    }

    fileName = fileName.trim().replaceAll(' ', '_');
    if (!fileName.contains('.')) fileName = '$fileName.apk';
    if (fileName.endsWith('.apk')) {
      fileName = fileName.substring(0, fileName.length - 4);
      fileName += '_${DateTime.now().millisecondsSinceEpoch}.apk';
    }

    final newTaskId = await FlutterDownloader.enqueue(
      url: parseUrl,
      fileName: fileName,
      savedDir: '/storage/emulated/0/Download',
      showNotification: true,
      saveInPublicStorage: true,
      openFileFromNotification: true,
    );
    if (newTaskId == null) {
      ToastUtil.error('下载失败，请稍后重试');
      return;
    }
    downloadTaskDao.setDownloadTask(
      taskId: newTaskId,
      appId: appId,
      appIcon: appInfo?.fileIcon ?? '',
      appName: appInfo?.fileName ?? fileName,
      appSize: appInfo?.fileSize ?? '',
    );
    _askedInstall = false;
    await getTaskInfo();
    // 轮询进度（FlutterDownloader 回调在部分机型不稳定）
    _startProgressPolling();
  }

  /// 轮询下载进度（保证进度条实时更新）
  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 700), (t) async {
      if (taskId == null || taskId!.isEmpty) {
        t.cancel();
        return;
      }
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$taskId'",
      );
      if (tasks == null || tasks.isEmpty) {
        t.cancel();
        return;
      }
      final t0 = tasks.first;
      downloadTask = t0;
      update(['download']);
      if (t0.status == DownloadTaskStatus.complete) {
        t.cancel();
        _onDownloadComplete();
      }
      if (t0.status == DownloadTaskStatus.canceled ||
          t0.status == DownloadTaskStatus.failed) {
        t.cancel();
      }
    });
  }

  Future<void> pauseDownload() async {
    if (taskId == null || taskId!.isEmpty) {
      ToastUtil.error('下载任务ID无效');
      return;
    }
    await FlutterDownloader.pause(taskId: taskId!);
    update(['download']);
  }

  Future<void> resumeDownload() async {
    if (taskId == null || taskId!.isEmpty) {
      ToastUtil.error('下载任务ID无效');
      return;
    }
    String? taskIdTemp = await FlutterDownloader.resume(taskId: taskId!);
    if (taskIdTemp == null) {
      ToastUtil.error('恢复下载失败');
      return;
    }
    taskId = taskIdTemp;
    update(['download']);
  }

  Future<void> retryDownload() async {
    if (taskId == null || taskId!.isEmpty) {
      ToastUtil.error('下载任务ID无效');
      return;
    }
    String? taskIdTemp = await FlutterDownloader.retry(taskId: taskId!);
    if (taskIdTemp == null) {
      ToastUtil.error('重试下载失败');
      return;
    }
    taskId = taskIdTemp;
    update(['download']);
  }

  Future<void> cancelDownload() async {
    if (taskId == null || taskId!.isEmpty) {
      ToastUtil.error('下载任务ID无效');
      return;
    }
    await FlutterDownloader.remove(taskId: taskId!, shouldDeleteContent: true);
    downloadTaskDao.deleteDownloadTask(appId);
    taskId = null;
    downloadTask = null;
    update(['download']);
  }

  /// 安装已下载的软件（原生安装器 + 多级兜底）
  Future<void> openDownloadFile() async {
    if (taskId == null || taskId!.isEmpty) {
      ToastUtil.error('下载任务ID无效');
      return;
    }

    // 1) 检查「安装未知应用」权限
    if (Platform.isAndroid) {
      final ok = await ApkInstaller.canInstall();
      if (!ok) {
        final go = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('需要安装权限'),
            content: const Text('安装应用需要您允许「安装未知应用」权限，前往设置开启？'),
            actions: [
              TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('去设置')),
            ],
          ),
        );
        if (go == true) {
          await ApkInstaller.openInstallSettings();
          ToastUtil.info('开启权限后请重新点击安装');
        }
        return;
      }
    }

    // 2) 找安装包本地路径
    final path = await _findApkPath();
    if (path == null) {
      ToastUtil.error('未找到安装包，请在下载管理中查看');
      return;
    }

    // 3) 调用原生安装器
    final ok = await ApkInstaller.install(path);
    if (ok) return;

    // 4) 兜底：open_filex
    try {
      await OpenFilex.open(path,
          type: 'application/vnd.android.package-archive');
      return;
    } catch (_) {}

    ToastUtil.error('无法调起安装，请到文件管理器手动安装');
  }

  /// 查找已下载 APK 的本地路径
  Future<String?> _findApkPath() async {
    try {
      // 优先用 FlutterDownloader 的任务记录
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$taskId'",
      );
      if (tasks != null && tasks.isNotEmpty) {
        final dir = tasks.first.savedDir ?? '';
        final name = tasks.first.filename;
        if (dir.isNotEmpty) {
          if (name != null && name.isNotEmpty) {
            final f = '$dir/$name';
            if (File(f).existsSync()) return f;
          }
          final d = Directory(dir);
          if (d.existsSync()) {
            final apks = d
                .listSync()
                .whereType<File>()
                .where((f) => f.path.toLowerCase().endsWith('.apk'))
                .toList();
            if (apks.isNotEmpty) {
              apks.sort((a, b) =>
                  b.statSync().modified.compareTo(a.statSync().modified));
              return apks.first.path;
            }
          }
        }
      }
    } catch (e) {
      logger.e('find apk path failed: $e');
    }
    // 兜底：扫描公共下载目录
    for (final dir in [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Android/data/com.softlib.flutter_softlib/files',
    ]) {
      try {
        final d = Directory(dir);
        if (!d.existsSync()) continue;
        final apks = d
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.apk'))
            .toList();
        if (apks.isEmpty) continue;
        apks.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        return apks.first.path;
      } catch (_) {}
    }
    return null;
  }


  /// 分享：会员资源不允许分享下载链接（防止绕过会员校验）
  void showSharePopUps(BuildContext context) {
    if (item?.isVipItem == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('会员专享资源'),
          content: const Text('该资源为会员专享，不支持分享下载链接。\n如需分享，请在广场发帖推荐。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('我知道了')),
          ],
        ),
      );
      return;
    }
    // 分享出去的是「详情页地址」而不是下载直链，避免直链被直接拿走
    showDialog(
      context: context,
      builder: (_) => PostersWidget(
        appInfo: appInfo,
        dowUrl: shareUrl,
        qrData: _sharePageUrl(),
      ),
    );
  }

  /// 分享页地址（指向站点详情页，非下载直链）
  String _sharePageUrl() {
    if (item == null) return ApiHost.base;
    return ApiHost.appPage(item!.id);
  }

  /// 对外分享/下载的地址
  String get shareUrl => _shareUrl();

  /// 分享出去的地址：服务器直传用直链，蓝奏云用原分享页
  String _shareUrl() {
    if (item != null && item!.canDirectDownload) return item!.file;
    return item?.url.isNotEmpty == true ? item!.url : dowUrl;
  }

  void showPreviewImage(String imageUrl) {
    showDialog(
      context: Get.context!,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: Get.back,
          child: Center(
            child: PhotoView(
              backgroundDecoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
              ),
              imageProvider: NetworkImage(imageUrl),
            ),
          ),
        );
      },
    );
  }
}
