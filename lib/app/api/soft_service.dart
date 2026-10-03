import 'package:dio/dio.dart';

import '../models/app_item.dart';

/// 软件数据服务（Dio 直连，不依赖 retrofit 生成代码）
class SoftService {
  SoftService._();
  static final SoftService instance = SoftService._();

  static const String baseUrl = 'https://flrjk.52yfx.cn';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// 软件列表（catId=0 / keyword 为空表示全部）
  Future<List<AppItem>> fetchApps({int catId = 0, String keyword = ''}) async {
    final resp = await _dio.get('/api/softlib/app/index', queryParameters: {
      if (catId > 0) 'cat_id': catId,
      if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
    });
    final data = resp.data;
    if (data is Map && data['code'] == 1) return AppItem.listFrom(data['data']);
    throw Exception((data is Map ? data['msg'] : '获取软件列表失败') ?? '获取失败');
  }

  /// 软件详情
  Future<AppItem?> fetchAppDetail({int id = 0, String url = ''}) async {
    final resp = await _dio.get('/api/softlib/app/detail', queryParameters: {
      if (id > 0) 'id': id,
      if (url.isNotEmpty) 'url': url,
    });
    final data = resp.data;
    if (data is Map && data['code'] == 1 && data['data'] is Map) {
      return AppItem.fromJson(Map<String, dynamic>.from(data['data']));
    }
    return null;
  }

  /// 蓝奏云链接解析 → 得到真实下载直链
  Future<String?> resolveLzy(String lzyUrl) async {
    final resp = await _dio.get(
      '/api/softlib/lzy_file_parse',
      queryParameters: {'url': lzyUrl},
      options: Options(receiveTimeout: const Duration(seconds: 40)),
    );
    final data = resp.data;
    if (data is Map && data['code'] == 1) {
      final u = (data['data'] is Map) ? (data['data']['url'] ?? '') : '';
      if (u.toString().isNotEmpty) return u.toString();
    }
    return null;
  }

  /// 蓝奏云文件信息（文件名/大小/图标/描述）
  Future<Map<String, dynamic>?> lzyFileInfo(String lzyUrl) async {
    final resp = await _dio.get(
      '/api/softlib/lzy_file_info',
      queryParameters: {'url': lzyUrl},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = resp.data;
    if (data is Map && data['code'] == 1 && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    return null;
  }

  /// 统一解析：返回可直接下载的 URL
  /// - 服务器直传：直接返回 file
  /// - 蓝奏云：走解析接口
  Future<String?> resolveDownloadUrl(AppItem item) async {
    if (item.canDirectDownload) return item.file;
    if (item.url.isNotEmpty) return resolveLzy(item.url);
    return null;
  }
}
