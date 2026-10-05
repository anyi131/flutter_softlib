import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_host.dart';

import '../models/app_cat.dart';
import '../models/app_config.dart';
import '../models/app_item.dart';
import 'user_service.dart';

/// 软件数据服务（Dio 直连，不依赖 retrofit 生成代码）
class SoftService {
  SoftService._();
  static final SoftService instance = SoftService._();

  static const String baseUrl = ApiHost.base;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      // 连接复用（加快连续请求）
      persistentConnection: true,
    ),
  )..interceptors.add(_RetryInterceptor());

  /// 工具 Tab 数据（分类 + 条目）—— 需求 v43 #5
  Future<List<Map<String, dynamic>>> fetchTools() async {
    try {
      final r = await _dio.get('/api/softlib/tool/index');
      if (r.data is Map && r.data['code'] == 1) {
        final d = r.data['data'];
        if (d is List) {
          return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('[Softlib] tools: $e');
    }
    return [];
  }

  /// 拉取全局配置（开屏/公告/远程控制）
  /// ★ 带内存缓存 + 并发去重：同一次会话内多个页面同时调用只发一次网络请求
  AppConfig? _configCache;
  DateTime? _configAt;
  Future<AppConfig?>? _configInflight;
  static const _configTtl = Duration(minutes: 10);

  Future<AppConfig?> fetchConfig({bool force = false}) async {
    if (!force &&
        _configCache != null &&
        _configAt != null &&
        DateTime.now().difference(_configAt!) < _configTtl) {
      return _configCache;
    }
    // 并发去重：已有请求在飞就复用
    if (_configInflight != null) return _configInflight;
    final fut = _fetchConfigInner();
    _configInflight = fut;
    try {
      return await fut;
    } finally {
      _configInflight = null;
    }
  }

  Future<AppConfig?> _fetchConfigInner() async {
    try {
      final resp = await _dio.get('/api/softlib/config/index');
      final data = resp.data;
      if (data is Map && data['code'] == 1 && data['data'] is Map) {
        final cfg = AppConfig.fromJson(Map<String, dynamic>.from(data['data']));
        _configCache = cfg;
        _configAt = DateTime.now();
        return cfg;
      }
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
    return _configCache; // 失败时退回旧缓存（若有）
  }

  /// 本地缓存（避免重复请求，加快页面切换）
  static final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 3);

  /// 软件列表（catId=0 / keyword 为空表示全部）
  /// force=true 时跳过缓存
  Future<List<AppItem>> fetchApps({
    int catId = 0,
    String keyword = '',
    String provider = '',
    bool force = false,
  }) async {
    final key = 'apps_${catId}_${keyword}_$provider';
    if (!force) {
      final hit = _cache[key];
      if (hit != null && !hit.expired) return hit.data as List<AppItem>;
    }
    final t0 = DateTime.now();
    final resp = await _dio.get('/api/softlib/app/index', queryParameters: {
      if (catId > 0) 'cat_id': catId,
      if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (provider.isNotEmpty) 'provider': provider,
    });
    final data = resp.data;
    if (data is Map && data['code'] == 1) {
      final list = AppItem.listFrom(data['data']);
      _cache[key] = _CacheEntry(list);
      debugPrint('[Softlib] fetchApps ${DateTime.now().difference(t0).inMilliseconds}ms (${list.length}条)');
      return list;
    }
    throw Exception((data is Map ? data['msg'] : '获取软件列表失败') ?? '获取失败');
  }

  /// 清空缓存（下拉刷新时用）
  static void clearCache() => _cache.clear();

  /// 检查更新（兼容后端返回 List 或 Map）
  /// 返回：null=已是最新；Map=有新版本
  Future<Map<String, dynamic>?> checkVersion(String currentVersion) async {
    try {
      final resp = await _dio.get('/api/softlib/version/index',
          queryParameters: {'oldversion': currentVersion});
      final d = resp.data;
      if (d is! Map || d['code'] != 1) return null;
      final data = d['data'];
      Map<String, dynamic>? latest;
      if (data is List) {
        for (final it in data) {
          if (it is Map) latest = Map<String, dynamic>.from(it);
        }
      } else if (data is Map) {
        latest = Map<String, dynamic>.from(data);
      }
      if (latest == null) return null;
      final url = (latest['dow_url'] ?? '').toString();
      if (url.isEmpty) return null;
      return latest;
    } catch (_) {
      return null;
    }
  }

  /// 软件分类（含数量）
  Future<List<AppCat>> fetchCats() async {
    try {
      final resp = await _dio.get('/api/softlib/app/cats');
      final data = resp.data;
      if (data is Map && data['code'] == 1) return AppCat.listFrom(data['data']);
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
    return [];
  }

  /// 拉取蓝奏云文件夹里的软件列表
  Future<List<AppItem>> fetchFolder(String url,
      {String pwd = '', int pgs = 1}) async {
    final resp = await _dio.get('/api/softlib/app/folder',
        queryParameters: {
          'url': url,
          'pgs': pgs,
          if (pwd.isNotEmpty) 'pwd': pwd,
        },
        options: Options(receiveTimeout: const Duration(seconds: 50)));
    final data = resp.data;
    if (data is Map && data['code'] == 1) return AppItem.listFrom(data['data']);
    throw Exception((data is Map ? data['msg'] : '获取文件夹失败') ?? '获取失败');
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
  static const String kLzyProxy = ApiHost.lzyProxy;

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
        // 兼容多种返回结构 + 字段大小写（自建服务返回 downUrl）
        final okCode = d['code'] == 200 || d['code'] == 1 || d['code'] == '200';
        if (okCode) {
          for (final k in [
            'downUrl', 'downurl', 'downURL', 'url', 'Url', 'URL',
            'download', 'link', 'data',
          ]) {
            final v = d[k];
            if (v is String && v.startsWith('http')) return v;
            if (v is Map) {
              for (final k2 in [
                'downUrl', 'downurl', 'url', 'download', 'link',
              ]) {
                final v2 = v[k2];
                if (v2 is String && v2.startsWith('http')) return v2;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
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
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
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
    } catch (e) {
      debugPrint('[Softlib] $e');
    }
  }

  /// 蓝奏云文件信息（文件名/大小/图标/描述）
  /// ★ 带内存缓存，同一链接 10 分钟内不重复请求
  Future<Map<String, dynamic>?> lzyFileInfo(String lzyUrl) async {
    final ck = 'lzyinfo_$lzyUrl';
    final hit = _cache[ck];
    if (hit != null && !hit.expired) return hit.data as Map<String, dynamic>?;
    final resp = await _dio.get(
      '/api/softlib/lzy_file_info',
      queryParameters: {'url': lzyUrl},
      options: Options(receiveTimeout: const Duration(seconds: 12)),
    );
    final data = resp.data;
    if (data is Map && data['code'] == 1 && data['data'] is Map) {
      final map = Map<String, dynamic>.from(data['data']);
      _cache[ck] = _CacheEntry(map);
      return map;
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
  // ═══════════ 工具体系 v45（复刻样本「简助手」）═══════════

  /// 整个工具配置（分组 + 工具 + 横幅 + 广告位）
  Map<String, dynamic>? _jzsCache;
  DateTime? _jzsAt;
  static const _jzsTtl = Duration(minutes: 10);

  Future<Map<String, dynamic>?> fetchJzsConfig({bool force = false}) async {
    if (!force &&
        _jzsCache != null &&
        _jzsAt != null &&
        DateTime.now().difference(_jzsAt!) < _jzsTtl) {
      return _jzsCache;
    }
    try {
      final r = await _dio.get('/api/softlib/jzs/config',
          options: Options(receiveTimeout: const Duration(seconds: 15)));
      if (r.data is Map && r.data['code'] == 1 && r.data['data'] is Map) {
        _jzsCache = Map<String, dynamic>.from(r.data['data'] as Map);
        _jzsAt = DateTime.now();
        return _jzsCache;
      }
    } catch (e) {
      debugPrint('[Softlib] jzs config: $e');
    }
    return _jzsCache;
  }

  /// 工具搜索
  Future<List<Map<String, dynamic>>> jzsSearch(String kw) async {
    try {
      final r = await _dio.get('/api/softlib/jzs/search',
          queryParameters: {'kw': kw});
      if (r.data is Map && r.data['code'] == 1) {
        final list = (r.data['data']?['list'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[Softlib] jzs search: $e');
    }
    return [];
  }

  /// 收藏 / 取消收藏（需登录）
  Future<bool> jzsToggleFav(int toolId) async {
    final r = await _dio.post('/api/softlib/jzs/fav',
        data: {'tool_id': toolId, 'token': UserService.instance.token});
    if (r.data is Map && r.data['code'] == 1) {
      return r.data['data']?['fav'] == true;
    }
    throw Exception(r.data is Map ? (r.data['msg'] ?? '操作失败') : '操作失败');
  }

  /// 我的收藏
  Future<List<Map<String, dynamic>>> jzsFavList() async {
    try {
      final r = await _dio.get('/api/softlib/jzs/fav_list',
          queryParameters: {'token': UserService.instance.token});
      if (r.data is Map && r.data['code'] == 1) {
        final list = (r.data['data']?['list'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[Softlib] jzs fav: $e');
    }
    return [];
  }

  /// 记录使用历史
  Future<void> jzsAddHistory(int toolId) async {
    try {
      await _dio.post('/api/softlib/jzs/history',
          data: {'tool_id': toolId, 'token': UserService.instance.token});
    } catch (_) {}
  }

  /// 使用历史
  Future<List<Map<String, dynamic>>> jzsHistory() async {
    try {
      final r = await _dio.get('/api/softlib/jzs/history_list',
          queryParameters: {'token': UserService.instance.token});
      if (r.data is Map && r.data['code'] == 1) {
        final list = (r.data['data']?['list'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[Softlib] jzs history: $e');
    }
    return [];
  }

  // ═══════════ 影视 / 音乐 / 短剧（v47 样本真实接口）═══════════

  /// 影视搜索（多源聚合）
  Future<List<Map<String, dynamic>>> mediaMovieSearch(String q, {String src = ''}) async {
    try {
      final r = await _dio.get('/api/softlib/media/movie_search',
          queryParameters: {'q': q, if (src.isNotEmpty) 'src': src},
          options: Options(receiveTimeout: const Duration(seconds: 40)));
      if (r.data is Map && r.data['code'] == 1) {
        final d = r.data['data'];
        final list = (d is Map ? (d['list'] as List?) : null) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[Softlib] movie search: $e');
    }
    return [];
  }

  /// 影视详情（含播放地址）
  Future<Map<String, dynamic>?> mediaMovieDetail(String src, String id) async {
    try {
      final r = await _dio.get('/api/softlib/media/movie_detail',
          queryParameters: {'src': src, 'id': id},
          options: Options(receiveTimeout: const Duration(seconds: 40)));
      if (r.data is Map && r.data['code'] == 1 && r.data['data'] is Map) {
        return Map<String, dynamic>.from(r.data['data'] as Map);
      }
    } catch (e) {
      debugPrint('[Softlib] movie detail: $e');
    }
    return null;
  }

  /// 音乐搜索（网易云）
  Future<List<Map<String, dynamic>>> mediaMusicSearch(String q) async {
    try {
      final r = await _dio.get('/api/softlib/media/music_search',
          queryParameters: {'q': q, 'src': 'netease'},
          options: Options(receiveTimeout: const Duration(seconds: 30)));
      if (r.data is Map && r.data['code'] == 1) {
        final d = r.data['data'];
        final list = (d is Map ? (d['list'] as List?) : null) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[Softlib] music search: $e');
    }
    return [];
  }

  /// 取音乐播放直链
  Future<Map<String, dynamic>?> mediaMusicUrl(String id, {String src = 'netease'}) async {
    try {
      final r = await _dio.get('/api/softlib/media/music_url',
          queryParameters: {'id': id, 'src': src},
          options: Options(receiveTimeout: const Duration(seconds: 30)));
      if (r.data is Map && r.data['code'] == 1 && r.data['data'] is Map) {
        return Map<String, dynamic>.from(r.data['data'] as Map);
      }
    } catch (e) {
      debugPrint('[Softlib] music url: $e');
    }
    return null;
  }

  /// 短剧列表
  Future<List<Map<String, dynamic>>> mediaDramaList({int page = 1}) async {
    try {
      final r = await _dio.get('/api/softlib/media/drama_list',
          queryParameters: {'page': page},
          options: Options(receiveTimeout: const Duration(seconds: 30)));
      if (r.data is Map && r.data['code'] == 1) {
        final d = r.data['data'];
        final list = (d is Map ? (d['list'] as List?) : null) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[Softlib] drama list: $e');
    }
    return [];
  }

  /// 短剧剧集
  Future<Map<String, dynamic>?> mediaDramaChannels(String id,
      {String src = 'hn'}) async {
    try {
      final r = await _dio.get('/api/softlib/media/drama_channels',
          queryParameters: {'id': id, 'src': src},
          options: Options(receiveTimeout: const Duration(seconds: 30)));
      if (r.data is Map && r.data['code'] == 1 && r.data['data'] is Map) {
        return Map<String, dynamic>.from(r.data['data'] as Map);
      }
    } catch (e) {
      debugPrint('[Softlib] drama channels: $e');
    }
    return null;
  }

  // ═══════════ 内置工具数据（真实界面工具，需求：工具要有实体界面）═══════════

  /// 通用工具接口请求
  Future<dynamic> tbGet(String action, [Map<String, dynamic> query = const {}]) async {
    final r = await _dio.get('/api/softlib/toolbox/$action',
        queryParameters: query.isEmpty ? null : query,
        options: Options(receiveTimeout: const Duration(seconds: 25)));
    if (r.data is Map && r.data['code'] == 1) return r.data['data'];
    throw Exception(r.data is Map ? (r.data['msg'] ?? '加载失败') : '加载失败');
  }

  /// 王者荣耀英雄列表
  Future<List<Map<String, dynamic>>> toolsHeroes() async {
    final d = await tbGet('heroes');
    return (d as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 漫画分类
  Future<List<Map<String, dynamic>>> comicTags() async {
    final d = await tbGet('comic_tags');
    return (d as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 漫画列表
  Future<List<Map<String, dynamic>>> comicList({String tag = '', int page = 1}) async {
    final d = await tbGet('comic_list', {'tag': tag, 'page': page});
    return (d as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 漫画章节
  Future<List<Map<String, dynamic>>> comicChapters(String comicId) async {
    final d = await tbGet('comic_chapters', {'comicid': comicId});
    return (d as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 漫画图片
  Future<List<String>> comicImages(String chapterId) async {
    final d = await tbGet('comic_images', {'chapterid': chapterId});
    return (d as List? ?? []).map((e) => '$e').toList();
  }

  /// 影视搜索
  Future<List<Map<String, dynamic>>> movieSearch(String q, {int page = 1}) async {
    final d = await tbGet('movie_search', {'q': q, 'page': page});
    return (d as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 音乐搜索
  Future<List<Map<String, dynamic>>> musicSearch(String q) async {
    final d = await tbGet('music_search', {'q': q});
    return (d as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 每日一言
  Future<Map<String, dynamic>> hitokoto() async {
    final d = await tbGet('hitokoto');
    return d is Map ? Map<String, dynamic>.from(d) : {};
  }
}


class _CacheEntry {
  final dynamic data;
  final DateTime at;
  _CacheEntry(this.data) : at = DateTime.now();
  bool get expired => DateTime.now().difference(at) > SoftService._cacheTtl;

}

/// 自动重试拦截器
/// 对「连接超时 / 连接错误 / 5xx」自动重试一次（第二次仍失败才抛错），
/// 显著降低弱网下的加载失败率。
class _RetryInterceptor extends Interceptor {
  static const _maxRetry = 1;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final opt = err.requestOptions;
    final tried = (opt.extra['_retry'] as int?) ?? 0;
    final retriable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response != null && (err.response!.statusCode ?? 0) >= 500);

    if (retriable && tried < _maxRetry) {
      opt.extra['_retry'] = tried + 1;
      await Future.delayed(Duration(milliseconds: 400 * (tried + 1)));
      try {
        final resp = await Dio(BaseOptions(
          baseUrl: opt.baseUrl,
          connectTimeout: opt.connectTimeout,
          receiveTimeout: opt.receiveTimeout,
          headers: opt.headers,
          persistentConnection: true,
        )).request<dynamic>(
          opt.path,
          data: opt.data,
          queryParameters: opt.queryParameters,
          options: Options(method: opt.method),
        );
        return handler.resolve(resp);
      } catch (_) {
        // 重试仍失败 → 走原始错误
      }
    }
    handler.next(err);
  }


}

