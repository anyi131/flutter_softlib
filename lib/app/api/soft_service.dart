import 'package:dio/dio.dart';

import '../models/app_cat.dart';
import '../models/app_config.dart';
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

  /// 拉取全局配置（开屏/公告/远程控制）
  Future<AppConfig?> fetchConfig() async {
    try {
      final resp = await _dio.get('/api/softlib/config/index');
      final data = resp.data;
      if (data is Map && data['code'] == 1 && data['data'] is Map) {
        return AppConfig.fromJson(Map<String, dynamic>.from(data['data']));
      }
    } catch (_) {}
    return null;
  }

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

  /// 软件分类（含数量）
  Future<List<AppCat>> fetchCats() async {
    try {
      final resp = await _dio.get('/api/softlib/app/cats');
      final data = resp.data;
      if (data is Map && data['code'] == 1) return AppCat.listFrom(data['data']);
    } catch (_) {}
    return [];
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

  /// 自建蓝奏云解析服务
  static const String kLzyProxy = 'https://www.52yfx.cn/lzy.php';

  /// 方案一：自建 API 解析直链（速度快、成功率高）
  Future<String?> resolveLzyByApi(String lzyUrl) async {
    try {
      final resp = await _dio.get(
        kLzyProxy,
        queryParameters: {'url': lzyUrl},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      final d = resp.data;
      if (d is Map) {
        // 兼容多种返回结构
        if (d['code'] == 200 || d['code'] == 1 || d['code'] == '200') {
          for (final k in ['url', 'downurl', 'download', 'link', 'data']) {
            final v = d[k];
            if (v is String && v.startsWith('http')) return v;
            if (v is Map) {
              for (final k2 in ['url', 'downurl', 'download', 'link']) {
                final v2 = v[k2];
                if (v2 is String && v2.startsWith('http')) return v2;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// 方案二：后端解析（原逻辑兜底）
  Future<String?> resolveLzyByServer(String lzyUrl) async {
    try {
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
    } catch (_) {}
    return null;
  }

  /// 蓝奏云解析：先自建 API，失败再用后端解析，都失败返回 null（调用方用原链接）
  Future<String?> resolveLzy(String lzyUrl) async {
    final a = await resolveLzyByApi(lzyUrl);
    if (a != null && a.isNotEmpty) return a;
    return resolveLzyByServer(lzyUrl);
  }

  /// 软件浏览量 +1
  Future<void> addAppView(int id) async {
    if (id <= 0) return;
    try {
      await _dio.get('/api/softlib/app/view', queryParameters: {'id': id});
    } catch (_) {}
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
