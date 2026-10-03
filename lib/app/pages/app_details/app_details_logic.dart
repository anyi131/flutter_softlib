import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

import '../../config.dart';
import '../../database/database.dart' as db;
import '../../database/tables/download_task_table.dart';
import '../../models/app_item.dart';
import '../../models/http/results/lzy_file_info_model.dart';
import '../../api/soft_service.dart';
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
    getAppInfo();
    getTaskInfo();
    IsolateNameServer.removePortNameMapping('app_details_downloader_send_port');
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'app_details_downloader_send_port',
    );
    port.listen((dynamic data) {
      if (data is List && data.length >= 3) {
        getTaskInfo();
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
      // 蓝奏云：补充解析出的文件信息
      if (item != null && !item!.isLocal && item!.url.isNotEmpty) {
        final info = await service.lzyFileInfo(item!.url);
        if (info != null) {
          appInfo = LzyFileInfoData(
            fileIcon: (info['icon'] ?? item!.icon).toString(),
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
      try {
        parseUrl = await service.resolveLzy(target);
      } catch (e) {
        logger.e(e.toString());
      }
    }

    if (parseUrl == null || parseUrl.isEmpty) {
      ToastUtil.error('下载链接解析失败，请稍后重试');
      return;
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
    getTaskInfo();
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

  Future<void> openDownloadFile() async {
    if (taskId == null || taskId!.isEmpty) {
      ToastUtil.error('下载任务ID无效');
      return;
    }
    bool results = await FlutterDownloader.open(taskId: taskId!);
    if (!results) ToastUtil.error('打开安装包失败');
  }

  void showSharePopUps(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PostersWidget(appInfo: appInfo, dowUrl: _shareUrl()),
    );
  }

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
